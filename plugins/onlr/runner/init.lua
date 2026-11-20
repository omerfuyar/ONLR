-- The runner's files (DESIGN 12): the Lua code that serves the editor. They are in ONLR's own folder, and no project holds them.
-- The engine loads this file with Lua's loadfile when the editor started LÖVE, and gets what it returns:
-- conf, which the engine calls from onlr.conf, and start, which it calls from onlr.start.
-- The editor's arguments, after the project's folder:
--   --onlr-runner=FOLDER   this folder
--   --onlr-mode=preview|game  the mode
--   --onlr-port=PORT       where the editor listens, on 127.0.0.1
--   --onlr-start=PATH      in the game, the node file to run as the first root in place of the manifest's start node
--   --onlr-size=WxH       in the game, the window's size in place of the manifest's, such as a phone's

local folder = ...

-- Loads another of the runner's files, once.
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

-- The component whose function the engine called when the error came, and its node, which the editor names and chooses.
local function source()
  local life = package.loaded["onlr.library.life"]
  local r = life and life.current
  if not r then
    return nil
  end
  local node = r.node
  return { type = r.type.name, name = node.name, file = node._file, id = node._id }
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
    source = source(),
  })
end

-- An error goes to the editor, with its file, line and stack (DESIGN 12.2). In the game LÖVE's own handler then shows it;
-- the preview ends, and the editor starts it again at the next change.
-- The game stops at its error, and keeps answering the link while LÖVE's handler shows it, so the editor reads the running tree and
-- its values as the error left them, until Stop (DESIGN 12.6).
-- LÖVE 11.5's own handler is love.errhand, which it calls when the game sets no love.errorhandler.
---@diagnostic disable-next-line: undefined-field
local shown = love.errorhandler or love.errhand
function love.errorhandler(message)
  local traceback = debug.traceback("", 2):gsub("^\n", "")
  print("Error: " .. tostring(message) .. "\n" .. traceback)
  report(message, traceback)
  if options.mode == "game" and shown then
    link.send({ type = "halted" })
    local engine = package.loaded["onlr"]
    local runnerState = engine and engine.loop and engine.loop._runner
    local ok, result = pcall(shown, message)
    local screen = ok and type(result) == "function" and result or nil ---@type function?
    if not ok then
      print("Error: LÖVE's error handler failed: " .. tostring(result))
    end
    if not runnerState or not runnerState.frame then
      return screen
    end
    -- without LÖVE's screen, such as with no window, the link still answers until Stop
    return function()
      pcall(runnerState.frame)
      if screen then
        return screen()
      end
      love.event.pump()
      for name, a in love.event.poll() do
        if name == "quit" then
          return a or 1
        end
      end
      love.timer.sleep(0.05)
    end
  end
  return function()
    return 1
  end
end

local runner = { options = options, report = report }

---Called from onlr.conf, after the manifest's settings.
---@param t table what love.conf gets
function runner.conf(t)
  if options.mode == "preview" then
    -- The preview draws into canvases and shows nothing, so it waits for no screen.
    t.window.vsync = 0
    t.window.fullscreen = false
    t.console = false
  end
  local width, height = (options.size or ""):match("^(%d+)x(%d+)$")
  if options.mode == "game" and width then
    t.window.width, t.window.height = tonumber(width), tonumber(height)
    t.window.fullscreen = false
  end
end

---Called from onlr.start.
---@param onlr onlr
function runner.start(onlr)
  link.send({ type = "hello", mode = options.mode, engine = require("onlr.library.data").read("packages/onlr/manifest.lua").version })
  if options.mode == "preview" then
    part("preview").start(onlr)
  else
    part("game").start(onlr, options)
  end
end

return runner
