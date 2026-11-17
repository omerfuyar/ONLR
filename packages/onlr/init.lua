-- What require("onlr") gives. This file joins the engine's other files, sets where require looks,
-- and does nothing else.
-- main.lua and conf.lua load it as packages.onlr, which LÖVE finds in the project's folder as it is.
-- When it loads, it adds packages/ to the places where require looks, and answers to the name onlr too.
-- conf.lua loads it before LÖVE's modules for drawing and input are there,
-- so no file of the engine uses them while it loads.

local path = love.filesystem.getRequirePath()
if not path:find("packages/?.lua", 1, true) then
  love.filesystem.setRequirePath(path .. ";packages/?.lua;packages/?/init.lua")
end

---@class onlr
local onlr = {}
package.loaded["onlr"] = onlr

local data = require("onlr.library.data")

onlr.loop = require("onlr.library.loop")
onlr.tree = require("onlr.library.tree")
onlr.property = require("onlr.library.property")

-- The fields of the manifest that are ONLR's own. Every other field is one of LÖVE's settings, under LÖVE's name.
local OWN = {
  format = true, name = true, id = true, gameVersion = true, loveVersion = true, startNode = true, topNode = true,
  window = true, defaultFilter = true, fixedRate = true, exclude = true,
}

-- The folder of the runner's files, when the editor started the game (DESIGN 12.1).
local function runnerFolder()
  for _, a in ipairs(arg or {}) do
    local folder = type(a) == "string" and a:match("^%-%-onlr%-runner=(.+)$")
    if folder then
      return folder
    end
  end
end

-- Loads the runner's files, once, with Lua's own loadfile, which reads any path.
local runner
local function loadRunner()
  local folder = runnerFolder()
  if folder and not runner then
    local chunk = assert(loadfile(folder .. "/init.lua"))
    runner = chunk(folder)
  end
  return runner
end

---Sets LÖVE's settings from the project's manifest. Called from conf.lua (DESIGN 3.1).
---@param t table what love.conf gets
function onlr.conf(t)
  local manifest = data.manifest()
  t.identity = manifest.id
  t.version = manifest.loveVersion
  t.window.title = manifest.name
  for key, value in pairs(manifest.window or {}) do
    t.window[key] = value
  end
  for key, value in pairs(manifest) do
    if not OWN[key] then
      if type(value) == "table" and type(t[key]) == "table" then
        for k, v in pairs(value) do
          t[key][k] = v
        end
      else
        t[key] = value
      end
    end
  end
  local p = loadRunner()
  if p and p.conf then
    p.conf(t)
  end
end

---Starts the engine. Called from main.lua. It sets love.run to the engine's loop, which calls
---the steps of onlr.loop; a game that sets its own love.run calls them itself.
function onlr.start()
  local manifest = data.manifest()
  if manifest.defaultFilter and love.graphics then
    love.graphics.setDefaultFilter(manifest.defaultFilter, manifest.defaultFilter)
  end
  love.run = onlr.loop.run
  local p = loadRunner()
  if p and p.start then
    p.start(onlr)
  end
end

return onlr
