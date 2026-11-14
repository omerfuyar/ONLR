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

local function makeFolders(path)
  local at = path:sub(1, 1) == "/" and "/" or ""
  for part in path:gmatch("[^/]+/?") do
    at = at .. part
    if part:sub(-1) == "/" and #at > 3 then
      fs.makeFolder(at)
    end
  end
end

local function isRuntime(folder, platform)
  local program = platform == "windows-x86_64" and "love.exe" or "bin/love"
  return fs.info(folder .. program) ~= nil
end

-- On Linux, the LÖVE that runs the players is a runtime when it is an AppImage's contents, as ONLR's archive holds it.
local function playersRuntime()
  if isWindows then
    return nil
  end
  local love = ecs.setting.get("onlr_player.love")
  if type(love) ~= "string" or love == "" then
    love = os.getenv("LOVE") or "love"
  end
  local out = process.run({ "sh", "-c", 'readlink -f "$(command -v "$0")"', love }, "", "")
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
  local set = ecs.setting.get("onlr_export." .. name .. "Runtime")
  if type(set) == "string" and set ~= "" then
    set = set:gsub("\\", "/")
    if set:sub(-1) ~= "/" then
      set = set .. "/"
    end
    if isRuntime(set, platform) then
      return done(set)
    end
    return done(nil, ("The setting onlr_export.%sRuntime names %s, which holds no LÖVE."):format(name, set))
  end
  local known = runtimes.KNOWN[platform]
  local folder = dataFolder() .. platform .. "/"
  local kept = folder .. (known.inside or "")
  if isRuntime(kept, platform) then
    return done(kept)
  end
  if platform == "linux-x86_64" then
    local own = playersRuntime()
    if own then
      return done(own)
    end
  end
  if not known.url then
    return done(nil, ("ONLR has no address to download LÖVE's runtime for %s from yet. The setting onlr_export.%sRuntime names a folder to use."):format(
      platform, name))
  end
  local request, err = web.get(known.url, function(request)
    if request:status() ~= 200 then
      return done(nil, ("LÖVE's runtime was not downloaded from %s: %s"):format(known.url,
        request:status() == -1 and request:error() or ("status " .. request:status())))
    end
    local body = request:body()
    -- The download is checked against the hash that ONLR ships, before anything of it is used.
    local sum = hash.of("sha256", body)
    if sum ~= known.sha256 then
      return done(nil, ("LÖVE's runtime from %s is not the file that ONLR knows: its SHA-256 hash is %s, not %s. It is not used."):format(
        known.url, sum, known.sha256))
    end
    makeFolders(folder)
    local archive = folder .. known.file
    local file = io.open(archive, "wb")
    if not file then
      return done(nil, "The runtime could not be written to " .. archive)
    end
    file:write(body)
    file:close()
    local ok, message = compress.zip.extract(archive, folder)
    if not ok or not isRuntime(kept, platform) then
      return done(nil, "The runtime could not be unpacked: " .. tostring(message))
    end
    done(kept)
  end)
  if not request then
    done(nil, "The download could not start: " .. tostring(err))
  end
end

return runtimes
