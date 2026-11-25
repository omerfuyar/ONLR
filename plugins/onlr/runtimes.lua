-- LÖVE's runtimes (DESIGN 15.2): LÖVE for one version and one platform, as files in a folder.
-- The runtime of another platform is downloaded at the first export for it, checked against the SHA-256 hash that ONLR ships,
-- and kept in the user's data folder, by version and platform.

local ecs = require("ecs")
local fs = require("fs")
local web = require("web")
local hash = require("hash")
local compress = require("compress")
local process = require("process")

local runtimes = {}

---The version of LÖVE that this version of ONLR serves (DESIGN 15.1).
runtimes.VERSION = "11.5"

---What ONLR knows of each platform's runtime: where it is downloaded from, the SHA-256 hash of that file, taken from
---LÖVE's release, and the folder inside it that holds LÖVE's files.
---@type table<string, {url: string?, file: string, sha256: string?, inside: string?}>
runtimes.KNOWN = {
  ["windows-x86_64"] = {
    url = "https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip",
    file = "love-11.5-win64.zip",
    sha256 = "ba6e56be2685e53c817749c4a5007f51137136fe5a3ab64920508babc2e74369",
    inside = "love-11.5-win64/",
  },
  -- The contents of LÖVE's AppImage, whose hash is 65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00.
  -- ONLR hosts them as a .tar.gz, which has no address yet.
  ["linux-x86_64"] = { file = "love-11.5-x86_64.tar.gz" },
}

---What is known of the runtimes: runtimes.KNOWN, or the table that the Lua file which the variable ONLR_RUNTIMES names
---returns, in its place, read at each export, so a test downloads from a server of its own (DESIGN 15.2, 16).
---@return table<string, {url: string?, file: string, sha256: string?, inside: string?}>? known
---@return string? message why the file named cannot be used
local function known()
  local path = os.getenv("ONLR_RUNTIMES")
  if not path or path == "" then
    return runtimes.KNOWN
  end
  local file = io.open(path, "rb")
  if not file then
    return nil, "The variable ONLR_RUNTIMES names " .. path .. ", which cannot be read."
  end
  local text = file:read("a")
  file:close()
  local chunk, err = load(text, "@" .. path, "t", {})
  local ok, result = false, err
  if chunk then
    ok, result = pcall(chunk)
  end
  if not ok or type(result) ~= "table" then
    return nil, ("The variable ONLR_RUNTIMES names %s, which returns no table: %s"):format(path, tostring(result))
  end
  return result
end

for _, platform in ipairs({ "linux", "windows" }) do
  ecs.setting.declare({
    name = platform .. "Runtime",
    type = "string",
    description = ("A folder to use as LÖVE's runtime for %s builds, such as a LÖVE that you built; when empty, ONLR's own"):format(
      platform == "linux" and "Linux" or "Windows"),
    default = "",
  })
end

local isWindows = package.config:sub(1, 1) == "\\"

-- The LÖVE that ONLR's archive holds, in love/ beside plugins/ (DESIGN 15.3): its AppRun on Linux, which finds the
-- AppImage's libraries, and love.exe on Windows.
local ownLove = ecs.plugin.folder .. "../../love/" .. (isWindows and "love.exe" or "AppRun")

---The LÖVE that runs the preview and the game (DESIGN 15.2): the one that the setting onlr.love names, or else the
---variable LOVE, or else the one of ONLR's archive, or else love, as the system finds it.
---@return string
function runtimes.love()
  local path = ecs.setting.get("onlr.love")
  if type(path) == "string" and path ~= "" then
    return path
  end
  path = os.getenv("LOVE")
  if path and path ~= "" then
    return path
  end
  if fs.info(ownLove) then
    return ownLove
  end
  return "love"
end

-- The folder where the runtimes are kept: the user's data folder.
local function dataFolder()
  local base
  if isWindows then
    base = (os.getenv("APPDATA") or "."):gsub("\\", "/")
  else
    base = os.getenv("XDG_DATA_HOME") or ((os.getenv("HOME") or ".") .. "/.local/share")
  end
  return base .. "/onlr/runtimes/" .. runtimes.VERSION .. "/"
end

-- Removes a folder and everything in it.
local function removeAll(path)
  for _, entry in ipairs(fs.list(path, "") or {}) do
    if entry.type == "folder" then
      removeAll(path .. entry.name .. "/")
    else
      fs.remove(path .. entry.name)
    end
  end
  fs.remove(path)
end

-- Unpacks an archive into a folder, by its format: a .zip, or a .tar.gz.
---@return boolean ok
---@return string? message
local function unpack(archive, body, folder)
  if archive:match("%.zip$") then
    return compress.zip.extract(archive, folder)
  end
  if not archive:match("%.tar%.gz$") then
    return false, "ONLR unpacks a .zip or a .tar.gz, not " .. archive
  end
  local tar, err = compress.gzip.unpack(body)
  local files = tar and compress.tar.unpack(tar)
  if not files then
    return false, err or "it is no tar archive"
  end
  for _, entry in ipairs(files) do
    if entry.name:find("%.%.") then
      return false, "it names a file outside its folder: " .. entry.name
    end
    if entry.name:sub(-1) == "/" then
      fs.makeFolder(folder .. entry.name)
    else
      local dir = entry.name:match("^(.*/)")
      if dir then
        fs.makeFolder(folder .. dir)
      end
      local file = io.open(folder .. entry.name, "wb")
      if not file then
        return false, "it could not write " .. entry.name
      end
      file:write(entry.data or "")
      file:close()
    end
  end
  return true
end

-- The downloads under way, by platform, with the functions that wait for each.
---@type table<string, fun(folder: string?, message: string?)[]>
local waiting = {}

local function isRuntime(folder, platform)
  local program = platform == "windows-x86_64" and "love.exe" or "bin/love"
  return fs.info(folder .. program) ~= nil
end

-- The LÖVE that runs the preview and the game is the runtime of the editor's own platform when its folder holds one, as
-- ONLR's archive does: an AppImage's contents on Linux, LÖVE's own folder on Windows.
local function runnersRuntime()
  local love = runtimes.love()
  if isWindows then
    local folder = love:gsub("\\", "/"):match("^(.*/)[^/]*$")
    return folder and isRuntime(folder, "windows-x86_64") and folder or nil
  end
  local out = process.run({ "sh", "-c", 'readlink -f "$(command -v "$0")"', love }, "", {}, "")
  local folder = out and out:match("^(.*/)[^/\n]*\n?$")
  if folder and isRuntime(folder, "linux-x86_64") then
    return folder
  end
end

---Finds a platform's runtime, and downloads it when it is missing.
---@param platform "linux-x86_64"|"windows-x86_64"
---@param done fun(folder: string?, message: string?) gets the runtime's folder, ending with a slash, or nil and why there is none
function runtimes.get(platform, done)
  local name = platform:match("^%a+")
  local set = ecs.setting.get("onlr." .. name .. "Runtime")
  if type(set) == "string" and set ~= "" then
    set = set:gsub("\\", "/")
    if set:sub(-1) ~= "/" then
      set = set .. "/"
    end
    if isRuntime(set, platform) then
      return done(set)
    end
    return done(nil, ("The setting onlr.%sRuntime names %s, which holds no LÖVE."):format(name, set))
  end
  local all, message = known()
  if not all then
    return done(nil, message)
  end
  local entry = all[platform] or {}
  -- A runtime is unpacked into a folder of its own, and renamed into place whole, so a folder there is a runtime that was
  -- unpacked to its end.
  local folder = dataFolder() .. platform .. "/"
  local kept = folder .. "love/"
  if isRuntime(kept, platform) then
    return done(kept)
  end
  if platform == (isWindows and "windows-x86_64" or "linux-x86_64") then
    local own = runnersRuntime()
    if own then
      return done(own)
    end
  end
  if not entry.url or not entry.file then
    return done(nil, ("ONLR has no address to download LÖVE's runtime for %s from yet. The setting onlr.%sRuntime names a folder to use."):format(
      platform, name))
  end
  -- A second export while the runtime downloads waits for the same download.
  if waiting[platform] then
    table.insert(waiting[platform], done)
    return
  end
  waiting[platform] = { done }
  local function finish(path, why)
    local callbacks = waiting[platform]
    waiting[platform] = nil
    for _, each in ipairs(callbacks) do
      each(path, why)
    end
  end
  local request, err = web.get(entry.url, function(request)
    if request:status() ~= 200 then
      return finish(nil, ("LÖVE's runtime was not downloaded from %s: %s"):format(entry.url,
        request:status() == -1 and request:error() or ("status " .. request:status())))
    end
    local body = request:body()
    -- The download is checked against the hash that ONLR ships, before anything of it is used.
    local sum = hash.of("sha256", body)
    if sum ~= entry.sha256 then
      return finish(nil, ("LÖVE's runtime from %s is not the file that ONLR knows: its SHA-256 hash is %s, not %s. It is not used."):format(
        entry.url, sum, tostring(entry.sha256)))
    end
    -- What an unpack that was cut short left is taken away first.
    local unpacking = folder .. "unpacking/"
    removeAll(unpacking)
    removeAll(kept)
    fs.makeFolder(unpacking)
    local archive = folder .. entry.file
    local file = io.open(archive, "wb")
    if not file then
      return finish(nil, "The runtime could not be written to " .. archive)
    end
    file:write(body)
    file:close()
    local ok, why = unpack(archive, body, unpacking)
    os.remove(archive)
    local inside = unpacking .. (entry.inside or "")
    if ok and not isRuntime(inside, platform) then
      ok, why = false, "it holds no LÖVE"
    end
    if ok then
      local renamed, err = os.rename(inside, kept)
      ok, why = renamed == true, err
    end
    removeAll(unpacking)
    if not ok then
      removeAll(kept)
      return finish(nil, "The runtime could not be unpacked: " .. tostring(why))
    end
    finish(kept)
  end)
  if not request then
    finish(nil, "The download could not start: " .. tostring(err))
  end
end

return runtimes
