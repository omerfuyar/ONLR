-- The player's files (DESIGN 12): the Lua code that serves the editor. They are in ONLR's own folder, and no project holds them.
-- The engine loads this file with Lua's loadfile when the editor started LÖVE, and gets what it returns:
-- conf, which the engine calls from onlr.conf, and start, which it calls from onlr.start.
-- The editor's arguments, after the project's folder:
--   --onlr-player=FOLDER   this folder
--   --onlr-mode=edit|play  the mode
--   --onlr-port=PORT       where the editor listens, on 127.0.0.1
--   --onlr-start=PATH      in play mode, the node file to run as the first root in place of the manifest's start node

local folder = ...

-- Loads another of the player's files, once.
local loaded = {}
local function part(name)
  if loaded[name] == nil then
    loaded[name] = assert(loadfile(folder .. "/" .. name .. ".lua"))(part)
  end
  return loaded[name]
end

local options = {}
for _, a in ipairs(arg or {}) do
  local key, value = tostring(a):match("^%-%-onlr%-(%a+)=(.+)$")
  if key then
    options[key] = value
  end
end

-- Each line that the game prints shows in the editor's console when it is printed.
io.stdout:setvbuf("no")
io.stderr:setvbuf("no")

local link = part("link")
if options.port then
  link.connect(tonumber(options.port))
end

-- Splits an error's message into its file, its line and the rest.
local function report(message, traceback)
  message = tostring(message)
  local file, line, rest = message:match("^([^:\n]+):(%d+): (.*)$")
  link.send({
    type = "error",
    message = rest or message,
    file = file,
    line = tonumber(line),
    stack = traceback,
  })
end

-- An error goes to the editor, with its file, line and stack (DESIGN 12.2). In play mode LÖVE's own handler then shows it;
-- the edit player ends, and the editor starts it again at the next change.
local shown = love.errorhandler
function love.errorhandler(message)
  local traceback = debug.traceback("", 2):gsub("^\n", "")
  print("Error: " .. tostring(message) .. "\n" .. traceback)
  report(message, traceback)
  if options.mode == "play" and shown then
    return shown(message)
  end
  return function()
    return 1
  end
end

local player = { options = options, report = report }

---Called from onlr.conf, after the manifest's settings.
---@param t table what love.conf gets
function player.conf(t)
  if options.mode == "edit" then
    -- The edit player draws into canvases and shows nothing, so it waits for no screen.
    t.window.vsync = 0
    t.window.fullscreen = false
    t.console = false
  end
end

---Called from onlr.start.
---@param onlr onlr
function player.start(onlr)
  link.send({ type = "hello", mode = options.mode, engine = require("onlr.data").read("packages/onlr/manifest.lua").version })
  if options.mode == "edit" then
    part("edit").start(onlr)
  else
    part("play").start(onlr, options)
  end
end

return player
