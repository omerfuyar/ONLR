-- Shaders (DESIGN 6.7): loading a GLSL file, reading its values from its text, sending values, and time.
-- data.load("shader", path) loads a file once, and the components that name it share it.

---A value of a shader, as its text declares it, with what the note at the end of its line says (DESIGN 6.7).
---@class onlr.ShaderValue
---@field name string
---@field type string its type in GLSL, such as "vec4", or LÖVE's "number" and "Image"
---@field color boolean? the note says color: a vec3 or a vec4 that the inspector shows as a colour
---@field min number? the least value, from a note such as 0 to 1
---@field max number? the most value
---@field default any? the value that it starts with: a number, a boolean, or a list of numbers for a vector
---@field description string? the note's text that is not a word of its own, which the inspector shows with the value

local shader = {}

---The seconds that the game has run, the sum of its frames' dt. A shader's extern number time gets it before each frame draws.
shader.time = 0

-- The loaded shaders that have time, and the names that each has, which LÖVE leaves out of a shader when its code does not use
-- them, so a value of such a name is not sent.
---@type table<love.Shader, boolean>
local timed = setmetatable({}, { __mode = "k" })
---@type table<love.Shader, table<string, boolean>>
local names = setmetatable({}, { __mode = "k" })
-- The values that each loaded shader's file declares, with their notes.
---@type table<love.Shader, onlr.ShaderValue[]>
local declared = setmetatable({}, { __mode = "k" })

---The values that a loaded shader's file declares, with their notes; an empty list for a shader that the engine did not load.
---@param s love.Shader
---@return onlr.ShaderValue[]
function shader.declaredOf(s)
  return declared[s] or {}
end

-- The types whose values the inspector shows (DESIGN 6.7); another type, such as a matrix, a script sends itself.
local SHOWN = {
  float = true, number = true, int = true, bool = true, vec2 = true, vec3 = true, vec4 = true, Image = true, sampler2D = true,
}

-- The number of numbers in a value of each vector type.
local SIZES = { vec2 = 2, vec3 = 3, vec4 = 4 }

-- The numbers of a text, such as "1 0.5 0 1".
local function numbers(text)
  local list = {}
  for n in text:gmatch("%-?[%d%.]+") do
    list[#list + 1] = tonumber(n)
  end
  return list
end

---Reads a note, the comment at the end of a value's line, into the value: its words are color, "A to B" and "default V",
---parted by commas, and the text after a colon is its description. A note without such a word is a description whole.
---@param value onlr.ShaderValue
---@param note string
local function readNote(value, note)
  note = note:match("^%s*(.-)%s*$")
  local words, description = note:match("^([^:]*):%s*(.*)$")
  words = words or note
  local known = false
  for word in words:gmatch("[^,]+") do
    word = word:match("^%s*(.-)%s*$")
    local low, high = word:match("^(%-?[%d%.]+)%s+to%s+(%-?[%d%.]+)$")
    local default = word:match("^default%s+(.+)$")
    if word == "color" and (value.type == "vec3" or value.type == "vec4") then
      value.color, known = true, true
    elseif low and tonumber(low) and tonumber(high) then
      value.min, value.max, known = tonumber(low), tonumber(high), true
    elseif default then
      known = true
      if value.type == "bool" then
        value.default = default == "true"
      elseif SIZES[value.type] then
        local list = numbers(default)
        if #list == SIZES[value.type] then
          value.default = list
        end
      elseif tonumber(default) then
        value.default = tonumber(default)
      end
    end
  end
  if known then
    value.description = description ~= "" and description or nil
  elseif note ~= "" then
    value.description = note
  end
end

---What a value starts with when nothing sets it: its note's default, white for a colour, and otherwise 0 or false, as GLSL
---gives. nil for an image, which LÖVE draws as white.
---@param value onlr.ShaderValue
---@return any
function shader.start(value)
  if value.default ~= nil then
    return type(value.default) == "table" and { unpack(value.default) } or value.default
  end
  local size = SIZES[value.type]
  if size then
    local list = {}
    for i = 1, size do
      list[i] = value.color and 1 or 0
    end
    return list
  elseif value.type == "bool" then
    return false
  elseif value.type == "Image" or value.type == "sampler2D" then
    return nil
  end
  return 0
end

---The values that a shader's text declares, in their order: each extern or uniform outside its functions, of a type that the
---inspector shows, with its note. time is the engine's, and not among them.
---@param text string
---@return onlr.ShaderValue[]
function shader.values(text)
  -- each line's note, kept by the names that the line declares, before the comments are taken away
  local notes = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local code, note = line:match("^(.-)//(.*)$")
    if code and code:find("^%s*[%a_]") then
      for _, value in ipairs(shader.declared(code)) do
        notes[value.name] = note
      end
    end
  end
  local list = shader.declared(text)
  for _, value in ipairs(list) do
    if notes[value.name] then
      readNote(value, notes[value.name])
    end
  end
  return list
end

---The values that a text declares, without their notes.
---@param text string
---@return onlr.ShaderValue[]
function shader.declared(text)
  -- comments, then what lies inside braces, the functions' bodies, are taken away, so only the declarations outside them stay
  text = text:gsub("/%*.-%*/", " "):gsub("//[^\n]*", " "):gsub("#[^\n]*", " ")
  local outside, depth = {}, 0
  for i = 1, #text do
    local c = text:sub(i, i)
    if c == "{" then
      -- what comes before a function's start is its head, not a declaration
      if depth == 0 then
        outside[#outside + 1] = ";"
      end
      depth = depth + 1
    elseif c == "}" then
      depth = math.max(0, depth - 1)
      -- a function's end ends what came before it, as a ; does
      if depth == 0 then
        outside[#outside + 1] = ";"
      end
    elseif depth == 0 then
      outside[#outside + 1] = c
    end
  end
  local list, seen = {}, {}
  local PRECISION = { highp = true, mediump = true, lowp = true }
  for statement in table.concat(outside):gmatch("[^;]+") do
    local qualifier, rest = statement:match("^%s*([%a_]+)%s+(.*)$")
    if qualifier == "extern" or qualifier == "uniform" then
      local glslType, declared = rest:match("^([%w_]+)%s+(.*)$")
      while PRECISION[glslType] do
        glslType, declared = declared:match("^([%w_]+)%s+(.*)$")
      end
      -- each name, but an array, name[4], which the inspector does not show; an initial value, = 1.0, is passed over
      for item in (declared or ""):gmatch("[^,]+") do
        local name, after = item:match("^%s*([%a_][%w_]*)%s*(.*)$")
        if name and SHOWN[glslType] and after:sub(1, 1) ~= "[" and name ~= "time" and not seen[name] then
          seen[name] = true
          list[#list + 1] = { name = name, type = glslType }
        end
      end
    end
  end
  return list
end

---LÖVE's message, "Line 5: ERROR: '' : syntax error ...", as the file's own: "effects/flash.glsl:5: syntax error ...".
---@param path string
---@param err any
---@return string
function shader.message(path, err)
  err = tostring(err)
  local line, text = err:match("Line (%d+): ERROR: '[^']*' :%s*([^\n]*)")
  if not line then
    line, text = err:match("Line (%d+):%s*([^\n]*)")
  end
  if line then
    return ("%s:%s: %s"):format(path, line, text)
  end
  return ("%s: %s"):format(path, (err:gsub("\n+$", "")))
end

---Compiles a GLSL file of the project, in LÖVE's own form. An ira-shader is not built yet.
---@param path string
---@return love.Shader
function shader.load(path)
  if path:match("^ira%-shaders/") then
    error(path .. ": an ira-shader cannot be drawn yet; name a GLSL file", 0)
  end
  local text = love.filesystem.read(path)
  if not text then
    error(path .. ": no such file", 0)
  end
  local ok, made = pcall(love.graphics.newShader, text)
  if not ok then
    error(shader.message(path, made), 0)
  end
  names[made] = {}
  declared[made] = shader.values(text)
  if made:hasUniform("time") then
    timed[made] = true
    made:send("time", shader.time)
  end
  return made
end

---Moves time by a frame's dt. The loop calls it in each frame that updates, so a paused game's shaders stand still.
---@param dt number
function shader.advance(dt)
  shader.time = shader.time + dt
end

---Sends time to every loaded shader that has it. The loop calls it before each frame draws.
function shader.sendTime()
  for s in pairs(timed) do
    s:send("time", shader.time)
  end
end

---Whether a shader has a value of that name, which LÖVE leaves out when the code does not use it.
---@param s love.Shader
---@param name string
---@return boolean
function shader.has(s, name)
  local known = names[s]
  if not known then
    known = {}
    names[s] = known
  end
  local has = known[name]
  if has == nil then
    has = s:hasUniform(name)
    known[name] = has
  end
  return has
end

---Sends values to a shader: every value that its file declares, the component's own or what it starts with (shader.start),
---since components that name one file share its shader and one's values must not stay for the next; then the others of the
---component's, such as a matrix, of the names that the shader has.
---@param s love.Shader
---@param values table<string, any>?
function shader.send(s, values)
  values = values or {}
  for _, value in ipairs(declared[s] or {}) do
    local v = values[value.name]
    if v == nil then
      v = shader.start(value)
    end
    if v ~= nil and shader.has(s, value.name) then
      s:send(value.name, v)
    end
  end
  for name, value in pairs(values) do
    if name ~= "time" and shader.has(s, name) and not shader.isDeclared(s, name) then
      s:send(name, value)
    end
  end
end

---Whether a loaded shader's file declares a value of that name among those that the inspector shows.
---@param s love.Shader
---@param name string
---@return boolean
function shader.isDeclared(s, name)
  for _, value in ipairs(declared[s] or {}) do
    if value.name == name then
      return true
    end
  end
  return false
end

return shader
