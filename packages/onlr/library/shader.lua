-- Shaders (DESIGN 6.7): loading a GLSL file, reading its values from its text, sending values, and time.
-- data.load("shader", path) loads a file once, and the components that name it share it.

---A value of a shader, as its text declares it.
---@class onlr.ShaderValue
---@field name string
---@field type string its type in GLSL, such as "vec4", or LÖVE's "number" and "Image"

local shader = {}

---The seconds that the game has run, the sum of its frames' dt. A shader's extern number time gets it before each frame draws.
shader.time = 0

-- The loaded shaders that have time, and the names that each has, which LÖVE leaves out of a shader when its code does not use
-- them, so a value of such a name is not sent.
---@type table<love.Shader, boolean>
local timed = setmetatable({}, { __mode = "k" })
---@type table<love.Shader, table<string, boolean>>
local names = setmetatable({}, { __mode = "k" })

-- The types whose values the inspector shows (DESIGN 6.7); another type, such as a matrix, a script sends itself.
local SHOWN = {
  float = true, number = true, int = true, bool = true, vec2 = true, vec3 = true, vec4 = true, Image = true, sampler2D = true,
}

---The values that a shader's text declares, in their order: each extern or uniform outside its functions, of a type that the
---inspector shows. time is the engine's, and not among them.
---@param text string
---@return onlr.ShaderValue[]
function shader.values(text)
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

-- LÖVE's message, "Line 5: ERROR: '' : syntax error ...", as the file's own: "effects/flash.glsl:5: syntax error ...".
local function message(path, err)
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
    error(message(path, made), 0)
  end
  names[made] = {}
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

---Sends values to a shader: those of the names that it has. A number, a bool, a list of numbers or an image is sent as it is.
---@param s love.Shader
---@param values table<string, any>?
function shader.send(s, values)
  for name, value in pairs(values or {}) do
    if name ~= "time" and shader.has(s, name) then
      s:send(name, value)
    end
  end
end

return shader
