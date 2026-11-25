-- Reading and writing data files (DESIGN 4): the manifest and the node files.
-- A file is read by running it in a sandbox, and written in one way only, so the same table always gives the same text.

local format = {}

-- The version of the data files' format that this editor reads (DESIGN 17).
format.FORMAT = 1

-- The order of a node's fields, and of the fields of an instance's change (DESIGN 5).
local NODE = { "format", "id", "instance", "name", "posX", "posY", "rot", "sclX", "sclY", "z", "active", "componentOrder", "components", "children" }
-- The order of a manifest's fields (DESIGN 3.2). LÖVE's other settings come between window and defaultFilter.
local MANIFEST_FIRST = { "format", "name", "id", "gameVersion", "loveVersion", "startNode", "topNode", "window" }
local MANIFEST_LAST = { "defaultFilter", "fixedRate", "exclude" }
local INSTANCE = { "base", "changes" }

---A node's fields that a change of an instance may replace, with their defaults (DESIGN 5).
---@type table<string, any>
format.DEFAULTS = { posX = 0, posY = 0, rot = 0, sclX = 1, sclY = 1, z = 0, active = true }

local KEYWORDS = {}
for word in ([[and break do else elseif end false for function global goto if in local nil not or repeat return then true until while]]):gmatch("%a+") do
  KEYWORDS[word] = true
end

---Whether a text is a name in Lua, which a key is written as without brackets.
---@param text any
---@return boolean
function format.isName(text)
  return type(text) == "string" and text:match("^[%a_][%w_]*$") ~= nil and not KEYWORDS[text]
end

local buffer = require("string.buffer")

local function escape(c)
  if c == "\\" then
    return "\\\\"
  elseif c == '"' then
    return '\\"'
  elseif c == "\n" then
    return "\\n"
  end
  return ("\\%03d"):format(c:byte())
end

local function quote(text)
  if not text:find('[%c"\\]') then
    return '"' .. text .. '"'
  end
  return '"' .. text:gsub('[%c"\\]', escape) .. '"'
end

local function number(n)
  if n ~= n then
    return "0/0"
  elseif n == math.huge then
    return "math.huge"
  elseif n == -math.huge then
    return "-math.huge"
  elseif n == math.floor(n) and n >= -2 ^ 53 and n <= 2 ^ 53 then
    return ("%.0f"):format(n)
  end
  for digits = 15, 17 do
    local text = ("%%.%dg"):format(digits):format(n)
    if tonumber(text) == n then
      return text
    end
  end
  return ("%.17g"):format(n)
end

local function isList(t)
  local n = #t
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count == n and n > 0
end

local function byName(a, b)
  local ta, tb = type(a), type(b)
  if ta ~= tb then
    return ta == "number"
  end
  return a < b
end

local function set(list)
  local s = {}
  for _, key in ipairs(list) do
    s[key] = true
  end
  return s
end
local NODE_SET, INSTANCE_SET = set(NODE), set(INSTANCE)
local MANIFEST_SET = set(MANIFEST_FIRST)
for _, key in ipairs(MANIFEST_LAST) do
  MANIFEST_SET[key] = true
end
local NONE = {}

-- The keys of a table in the order they are written: those of first, then the others by name, then those of last. seen holds
-- the keys of first and last.
local function ordered(t, first, last, seen)
  local keys, n = {}, 0
  for i = 1, #first do
    local key = first[i]
    if t[key] ~= nil then
      n = n + 1
      keys[n] = key
    end
  end
  local from = n + 1
  for key in pairs(t) do
    if not seen[key] then
      n = n + 1
      keys[n] = key
    end
  end
  if n - from > 0 then
    -- only the keys after first's are sorted
    local rest = {}
    for i = from, n do
      rest[#rest + 1] = keys[i]
    end
    table.sort(rest, byName)
    for i = 1, #rest do
      keys[from + i - 1] = rest[i]
    end
  end
  for i = 1, #last do
    local key = last[i]
    if t[key] ~= nil then
      n = n + 1
      keys[n] = key
    end
  end
  return keys
end

-- The keys that are names, as format.isName tells, which a table's keys are written as without brackets.
local names, nameCount = {}, 0
local function isName(key)
  local known = names[key]
  if known == nil then
    known = format.isName(key)
    if nameCount > 10000 then
      names, nameCount = {}, 0
    end
    names[key], nameCount = known, nameCount + 1
  end
  return known
end

-- The indents, by depth.
local INDENTS = setmetatable({}, {
  __index = function(t, depth)
    local text = ("  "):rep(depth)
    t[depth] = text
    return text
  end,
})

-- Writes a value. kind tells the order of a table's fields: "node", "instance", "changes", "children", "manifest" or nil.
local function write(out, value, depth, kind)
  local t = type(value)
  if t == "number" then
    out:put(number(value))
  elseif t == "string" then
    out:put(quote(value))
  elseif t == "boolean" then
    out:put(value and "true" or "false")
  elseif t ~= "table" then
    error("a data file holds no " .. t, 0)
  elseif next(value) == nil then
    out:put("{}")
  else
    local inner = INDENTS[depth + 1]
    out:put("{\n")
    if kind == "children" or not kind and isList(value) then
      local sub = kind == "children" and "node" or nil
      for _, item in ipairs(value) do
        out:put(inner)
        write(out, item, depth + 1, sub)
        out:put(",\n")
      end
    else
      local keys
      if kind == "node" then
        keys = ordered(value, NODE, NONE, NODE_SET)
      elseif kind == "manifest" then
        keys = ordered(value, MANIFEST_FIRST, MANIFEST_LAST, MANIFEST_SET)
      elseif kind == "instance" then
        keys = ordered(value, INSTANCE, NONE, INSTANCE_SET)
      else
        keys = ordered(value, NONE, NONE, NONE)
      end
      for i = 1, #keys do
        local key = keys[i]
        out:put(inner)
        if kind ~= "changes" and isName(key) then
          out:put(key)
        else
          out:put("[")
          write(out, key, depth + 1)
          out:put("]")
        end
        out:put(" = ")
        local sub
        if kind == "node" then
          sub = key == "instance" and "instance" or key == "children" and "children" or nil
        elseif kind == "instance" then
          sub = key == "changes" and "changes" or nil
        elseif kind == "changes" then
          sub = "node"
        end
        local item = value[key]
        write(out, item, depth + 1, type(item) == "table" and sub or nil)
        out:put(",\n")
      end
    end
    out:put(INDENTS[depth], "}")
  end
end

local out = buffer.new()

---The text that the editor writes for a data file's table (DESIGN 4.2).
---@param t table the table that the file returns
---@param kind "node"|"manifest"|"data" a node file, the project's manifest, or another table, whose fields are in the order of their names
---@return string
function format.write(t, kind)
  out:reset()
  if kind == "node" then
    out:put("---@type onlr.NodeFile\n")
  elseif kind == "manifest" then
    out:put("---@type onlr.Project\n")
  end
  out:put("return ")
  local ok, err = pcall(write, out, t, 0, kind ~= "data" and kind or nil)
  if not ok then
    out:reset()
    error(err, 0)
  end
  out:put("\n")
  return out:get()
end

-- The basic functions that a data file may call (DESIGN 4.1).
local BASIC = {
  "assert", "error", "getmetatable", "ipairs", "next", "pairs", "pcall", "rawequal", "rawget", "rawset", "select",
  "setmetatable", "tonumber", "tostring", "type", "xpcall",
}

local function copy(t)
  local c = {}
  for k, v in pairs(t) do
    c[k] = v
  end
  return c
end

local function sandbox()
  local env = {}
  for _, name in ipairs(BASIC) do
    env[name] = _G[name]
  end
  env.unpack = table.unpack
  env.string = copy(string)
  env.table = copy(table)
  env.math = copy(math)
  -- A text's metatable is shared by every text, and its __index is the real string, so the file gets nothing for it.
  env.getmetatable = function(value)
    if type(value) == "string" then
      return nil
    end
    return getmetatable(value)
  end
  env._G = env
  return env
end

---Runs a data file's text in its sandbox and gives the table that it returns.
---@param text string the file's Lua
---@param path string its path, for the messages
---@return table? t the table, or nil when the file does not load
---@return string? message why it does not load
function format.read(text, path)
  local chunk, err = load(text, "@" .. path, "t", sandbox())
  if not chunk then
    return nil, err
  end
  local ok, result = pcall(chunk)
  if not ok then
    return nil, tostring(result)
  end
  if type(result) ~= "table" then
    return nil, path .. ": a data file returns a table"
  end
  if result.format ~= format.FORMAT then
    return nil, ("%s: format %s is not %d, the one that this editor reads"):format(path, tostring(result.format), format.FORMAT)
  end
  return result
end

---Whether a person wrote a file's text: it differs from what the editor writes for the same table.
---The ends of lines are not compared.
---@param text string the file's text
---@param t table the table that it returns
---@param kind "node"|"manifest"|"data"
---@return boolean
function format.handwritten(text, t, kind)
  return text:gsub("\r\n", "\n") ~= format.write(t, kind)
end

---A deep copy of a data file's table.
---@generic T
---@param value T
---@return T
function format.copy(value)
  if type(value) ~= "table" then
    return value
  end
  local c = {}
  for k, v in pairs(value) do
    c[k] = format.copy(v)
  end
  return c
end

---Whether two values of a data file are the same, table by table.
---@param a any
---@param b any
---@return boolean
function format.same(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then
    return a == b
  end
  for k, v in pairs(a) do
    if not format.same(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

local CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"

---A new id for a node: six random characters, lowercase letters and digits (DESIGN 4.2).
---@param taken table<string, any> the ids that the file has
---@return string
function format.newId(taken)
  while true do
    local id = {}
    for i = 1, 6 do
      local n = math.random(#CHARS)
      id[i] = CHARS:sub(n, n)
    end
    local text = table.concat(id)
    if not taken[text] then
      return text
    end
  end
end

---Reads a whole file.
---@param path string
---@return string? text
function format.readFile(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end
  local text = file:read("a")
  file:close()
  return text
end

---Writes a whole file: beside the old one, then renamed over it, so it is never left half-written (DESIGN 4.2).
---@param path string
---@param text string
---@return boolean ok
---@return string? message
function format.writeFile(path, text)
  local temp = path .. ".new"
  local file, err = io.open(temp, "wb")
  if not file then
    return false, err
  end
  file:write(text)
  file:close()
  local ok, message = os.rename(temp, path)
  if not ok then
    -- Windows does not rename over a file
    os.remove(path)
    ok, message = os.rename(temp, path)
  end
  return ok and true or false, message
end

return format
