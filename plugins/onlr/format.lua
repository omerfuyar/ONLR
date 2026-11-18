-- Reading and writing data files (DESIGN 4): the manifest and the node files.
-- A file is read by running it in a sandbox, and written in one way only, so the same table always gives the same text.

local format = {}

-- The version of the data files' format that this editor reads (DESIGN 17).
format.FORMAT = 1

-- The order of a node's fields, and of the fields of an instance's change (DESIGN 5).
local NODE = { "format", "id", "instance", "name", "posX", "posY", "rot", "sclX", "sclY", "z", "active", "components", "children" }
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

local function quote(text)
  return '"' .. text:gsub('[%c"\\]', function(c)
    if c == "\\" then
      return "\\\\"
    elseif c == '"' then
      return '\\"'
    elseif c == "\n" then
      return "\\n"
    end
    return ("\\%03d"):format(c:byte())
  end) .. '"'
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

-- The keys of a table in the order they are written: those of first, then the others by name, then those of last.
local function ordered(t, first, last)
  local keys, seen = {}, {}
  for _, key in ipairs(first or {}) do
    if t[key] ~= nil then
      keys[#keys + 1] = key
    end
    seen[key] = true
  end
  for _, key in ipairs(last or {}) do
    seen[key] = true
  end
  local rest = {}
  for key in pairs(t) do
    if not seen[key] then
      rest[#rest + 1] = key
    end
  end
  table.sort(rest, byName)
  for _, key in ipairs(rest) do
    keys[#keys + 1] = key
  end
  for _, key in ipairs(last or {}) do
    if t[key] ~= nil then
      keys[#keys + 1] = key
    end
  end
  return keys
end

local writeNode

-- Writes a value. kind tells the order of a table's fields: "node", "instance", "changes", "children", "manifest" or nil.
local function write(out, value, indent, kind)
  local t = type(value)
  if t == "number" then
    out[#out + 1] = number(value)
  elseif t == "string" then
    out[#out + 1] = quote(value)
  elseif t == "boolean" then
    out[#out + 1] = tostring(value)
  elseif t ~= "table" then
    error("a data file holds no " .. t, 0)
  elseif next(value) == nil then
    out[#out + 1] = "{}"
  else
    local inner = indent .. "  "
    out[#out + 1] = "{\n"
    if not kind and isList(value) or kind == "children" then
      for _, item in ipairs(value) do
        out[#out + 1] = inner
        write(out, item, inner, kind == "children" and "node" or nil)
        out[#out + 1] = ",\n"
      end
    else
      local keys
      if kind == "node" then
        keys = ordered(value, NODE)
      elseif kind == "manifest" then
        keys = ordered(value, MANIFEST_FIRST, MANIFEST_LAST)
      elseif kind == "instance" then
        keys = ordered(value, INSTANCE)
      else
        keys = ordered(value)
      end
      for _, key in ipairs(keys) do
        out[#out + 1] = inner
        if kind ~= "changes" and format.isName(key) then
          out[#out + 1] = key
        else
          out[#out + 1] = "["
          write(out, key, inner)
          out[#out + 1] = "]"
        end
        out[#out + 1] = " = "
        local sub
        if kind == "node" then
          sub = key == "instance" and "instance" or key == "children" and "children" or nil
        elseif kind == "instance" then
          sub = key == "changes" and "changes" or nil
        elseif kind == "changes" then
          sub = "node"
        end
        write(out, value[key], inner, type(value[key]) == "table" and sub or nil)
        out[#out + 1] = ",\n"
      end
    end
    out[#out + 1] = indent .. "}"
  end
end

---The text that the editor writes for a data file's table (DESIGN 4.2).
---@param t table the table that the file returns
---@param kind "node"|"manifest"|"data" a node file, the project's manifest, or another table, whose fields are in the order of their names
---@return string
function format.write(t, kind)
  local out = {}
  if kind == "node" then
    out[1] = "---@type onlr.NodeFile\n"
  elseif kind == "manifest" then
    out[1] = "---@type onlr.Project\n"
  end
  out[#out + 1] = "return "
  write(out, t, "", kind ~= "data" and kind or nil)
  out[#out + 1] = "\n"
  return table.concat(out)
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
