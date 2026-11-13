-- Reading data files (DESIGN 4): the manifest and the node files, each a Lua file that returns a table.
-- And the files that properties name, such as images, which the engine loads once and shares (DESIGN 6.2).
-- No function here uses LÖVE while this file loads: conf.lua loads the engine before LÖVE's other modules.

local data = {}

-- The version of the data files' format that this engine reads (DESIGN 17).
data.FORMAT = 1

-- The basic functions that a data file may call: those that compute. Those that load code or reach outside are left out.
local BASIC = {
  "assert", "error", "getmetatable", "ipairs", "next", "pairs", "pcall", "rawequal", "rawget", "rawset", "select",
  "setmetatable", "tonumber", "tostring", "type", "unpack", "xpcall",
}

local function copy(t)
  local c = {}
  for k, v in pairs(t) do
    c[k] = v
  end
  return c
end

-- A new table of globals for one data file: the basic functions, and copies of string, table and math,
-- so a file cannot change what another file or the game sees.
local function sandbox()
  local env = {}
  for _, name in ipairs(BASIC) do
    env[name] = _G[name]
  end
  env.string = copy(string)
  env.table = copy(table)
  env.math = copy(math)
  env._G = env
  return env
end

-- Texts that the player gives in place of a file on disk, such as a node file that the editor holds unsaved (DESIGN 12.2).
---@type table<string, string>
data.texts = {}

---Runs a data file's text in its sandbox and gives the table it returns.
---@param text string the file's Lua
---@param path string its path, for the messages
---@return table
function data.run(text, path)
  local chunk, err = loadstring(text, "@" .. path)
  if not chunk then
    error(err, 0)
  end
  setfenv(chunk, sandbox())
  local ok, result = pcall(chunk)
  if not ok then
    error(result, 0)
  end
  if type(result) ~= "table" then
    error(path .. ": a data file returns a table", 0)
  end
  if result.format ~= data.FORMAT then
    error(("%s: format %s is not %d, the one that this engine reads"):format(path, tostring(result.format), data.FORMAT), 0)
  end
  return result
end

---Reads a data file of the game, in its sandbox, and checks its format.
---@param path string such as "nodes/level.lua"
---@return table
function data.read(path)
  local text = data.texts[path]
  if not text then
    if not love.filesystem.getInfo(path, "file") then
      error(path .. ": no such file", 0)
    end
    text = assert(love.filesystem.read(path))
  end
  return data.run(text, path)
end

local manifest

---The project's manifest, read once.
---@return onlr.Project
function data.manifest()
  manifest = manifest or data.read("manifest.lua")
  return manifest
end

-- Loaded files, by a key of their kind and path: an entry holds the value and how many components hold it.
-- An entry that nothing holds stays until the root changes, when the engine lets it go (data.collect).
---@type table<string, {value: any, holds: integer}>
local loaded = {}

local function get(key, make)
  local entry = loaded[key]
  if not entry then
    entry = { value = make(), holds = 0 }
    loaded[key] = entry
  end
  return entry
end

---Whether a path names a file of the game.
---@param path string
---@return boolean
function data.exists(path)
  return type(path) == "string" and love.filesystem.getInfo(path, "file") ~= nil
end

local function need(path)
  if not data.exists(path) then
    error(tostring(path) .. ": no such file", 0)
  end
end

---A loaded file, by its kind, and the key under which it is held.
---kind is "image", "font", "sound" or "node". A sound is the source that each component clones,
---a font is a path and a size, and a node file is its table.
---@param kind "image"|"font"|"sound"|"node"
---@param path string?
---@param option any the font's size, or whether a sound streams
---@return any value
---@return string key
function data.load(kind, path, option)
  local key
  local entry
  if kind == "image" then
    key = "image:" .. tostring(path)
    entry = loaded[key] or (need(path) or get(key, function()
      return love.graphics.newImage(path)
    end))
  elseif kind == "font" then
    key = "font:" .. (path or "") .. ":" .. tostring(option)
    if path then
      need(path)
    end
    entry = get(key, function()
      if path then
        return love.graphics.newFont(path, option)
      end
      return love.graphics.newFont(option)
    end)
  elseif kind == "sound" then
    key = "sound:" .. tostring(path) .. (option and ":stream" or "")
    entry = loaded[key] or (need(path) or get(key, function()
      return love.audio.newSource(path, option and "stream" or "static")
    end))
  else
    key = "node:" .. tostring(path)
    entry = loaded[key] or get(key, function()
      return data.read(path)
    end)
  end
  return entry.value, key
end

---Holds a loaded file, so it stays when the root changes.
---@param key string
function data.hold(key)
  local entry = loaded[key]
  if entry then
    entry.holds = entry.holds + 1
  end
end

---Lets go of a file that data.hold held.
---@param key string
function data.release(key)
  local entry = loaded[key]
  if entry then
    entry.holds = entry.holds - 1
  end
end

---Lets go of every loaded file that nothing holds. The engine calls it when the root changes.
function data.collect()
  for key, entry in pairs(loaded) do
    if entry.holds <= 0 then
      loaded[key] = nil
    end
  end
end

---Forgets every loaded file, held or not, such as when the player reads a changed image again (DESIGN 12.2).
---@param path string? only the files of this path
function data.forget(path)
  for key in pairs(loaded) do
    if not path or key:find(":" .. path, 1, true) then
      loaded[key] = nil
    end
  end
end

---Whether a file is loaded, for the tests.
---@param key string such as "image:images/coin.png"
---@return boolean
function data.isLoaded(key)
  return loaded[key] ~= nil
end

return data
