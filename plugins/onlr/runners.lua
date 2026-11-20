-- The runners (DESIGN 12.1): LÖVE started on the project's folder, as programs of their own, and the link with each.
-- The preview runs while a project is open, and the game while the user plays it.

local ecs = require("ecs")
local net = require("net")
local process = require("process")
local project = require("project")
local console = require("console")
local link = require("link")
local hints = require("hints")
local runtimes = require("runtimes")

local runners = {}

---A runner: LÖVE as the editor started it, and its link.
---@class onlr.editor.Runner
---@field mode "preview"|"game"
---@field process any
---@field server any the link's listening end
---@field connection any? the link, once the runner has connected
---@field buffer string what arrived and was not read yet
---@field ready boolean it sent hello
---@field output string[] what it printed
---@field partial string the start of a line that it has not ended yet
---@field sent table<string, string> the node files' texts that it was sent
---@field owed table<any, boolean> the answers that it owes: a type's name, or a view's number
---@field since integer when it was last asked, or last heard
---@field stopping boolean? the editor asked it to end

---@type onlr.editor.Runner?
local preview
---@type onlr.editor.Runner?
local game

---The views that the node views show, by number: what the preview draws (DESIGN 12.3).
---@type table<integer, table>
runners.views = {}

---Why the preview is down, when it is.
---@type string?
runners.down = nil
-- A view that stopped the preview twice in a row is not drawn again until the user asks.
local strikes, blocked = 0, false

---The running game: whether it is paused, or halted at an error, and what the game sent of it.
runners.running = { playing = false, paused = false, tree = nil, values = nil }

---Called with each message of the preview for a view: its type, the message and its block.
---@type fun(type: string, message: table, block: string?)
runners.onView = function() end

ecs.event.declare("state", "A runner started, ended, paused or went on")
ecs.event.declare("running", "The game sent the running tree, or the watched nodes' values")

ecs.setting.declare({
  name = "playTint",
  type = "color",
  description = "The colour of the frames around the panels while a game plays, so the user sees that changes to the running game are not kept; the frames' own colour shows none",
  default = "#9C6B3C",
})

-- The sizes of the game's window that Play offers (DESIGN 12.1): the manifest's own, then others, as a phone's. The project's
-- setting playSize keeps the chosen size as "WIDTHxHEIGHT".
runners.SIZES = {
  { label = "As the manifest" },
  { label = "1920 × 1080", size = "1920x1080" },
  { label = "1280 × 720", size = "1280x720" },
  { label = "Phone 360 × 800", size = "360x800" },
  { label = "Phone 390 × 844", size = "390x844" },
  { label = "Phone 800 × 360", size = "800x360" },
  { label = "Tablet 768 × 1024", size = "768x1024" },
}

-- While a game plays, the frames around the panels take the tint, for this run only, through OpenECS's run layer of settings: the
-- user's colour comes back at its end.
local tinted = false
ecs.event.subscribe("onlr.state", function()
  local playing = runners.running.playing == true
  if playing ~= tinted then
    tinted = playing
    ecs.setting.setForRun("ecs.colorFrame", playing and ecs.setting.get("onlr.playTint") or nil)
  end
end)

ecs.setting.declare({
  name = "love",
  type = "string",
  description = "LÖVE's executable, which runs the preview and the game; when empty, the variable LOVE names it, or else the one of ONLR's archive, or else love",
  default = "",
})


local isWindows = package.config:sub(1, 1) == "\\"

---@param mode "preview"|"game"
---@param startPath string?
---@return onlr.editor.Runner?
local function start(mode, startPath)
  local folder = project.folder()
  if folder == "" then
    return nil
  end
  -- net tells no port that it chose, so the editor chooses one, and tries another when it is taken.
  local server, port
  for _ = 1, 20 do
    port = math.random(20000, 59999)
    server = net.listen(port)
    if server then
      break
    end
  end
  if not server then
    console.add("The link could not listen on a port of this computer.", "error")
    return nil
  end
  local command = {}
  -- The preview opens no window: on Linux, SDL's offscreen driver draws with the graphics card all the same.
  if mode == "preview" and not isWindows then
    command = { "env", "SDL_VIDEODRIVER=offscreen" }
  end
  command[#command + 1] = runtimes.love()
  command[#command + 1] = folder:gsub("/$", "")
  command[#command + 1] = "--onlr-runner=" .. project.home() .. "plugins/onlr/runner"
  command[#command + 1] = "--onlr-mode=" .. mode
  command[#command + 1] = "--onlr-port=" .. port
  if startPath then
    command[#command + 1] = "--onlr-start=" .. startPath
  end
  -- the size of the window that Play chose, for this run only: the manifest keeps its own
  local size = project.setting("playSize")
  if mode == "game" and type(size) == "string" then
    command[#command + 1] = "--onlr-size=" .. size
  end
  local started, err = process.start(command, folder)
  if not started then
    console.add(("LÖVE did not start: %s. The setting onlr.love names its executable."):format(tostring(err)), "error")
    return nil
  end
  ---@type onlr.editor.Runner
  return {
    mode = mode, process = started, server = server, buffer = "", ready = false, output = {}, partial = "",
    sent = {}, owed = {}, since = os.time(),
  }
end

-- Adds an error to the console, with its stack and a hint when the error is one that the hints know (DESIGN 13.1).
-- An error that a component raised names it and its node; when a node file wrote the node, the name is a link, and a click
-- opens the file and chooses the node.
local function sayError(text, stack, source)
  local links
  if type(source) == "table" then
    local name = ("%s on %s"):format(tostring(source.type), source.name ~= "" and tostring(source.name) or "a node")
    if source.file and source.id then
      links = { { text = name, tooltip = "Choose the node whose component raised the error", onClick = function()
        require("nodeview").openFile(source.file)
        project.choose(source.file, { source.id })
      end } }
    else
      text = text .. "\nIn " .. name .. ", which code made."
    end
  end
  console.add(stack and (text .. "\n" .. stack) or text, "error", links)
  local hint = hints.of(text)
  if hint then
    console.add("Hint: " .. hint, "info")
  end
end

local function send(runner, message, block)
  if runner and runner.connection then
    runner.connection:send(link.pack(message, block))
  end
end

local function stop(runner)
  if not runner then
    return
  end
  runner.stopping = true
  send(runner, { type = "stop" })
  local started = runner.process
  -- A runner that does not end when asked is ended.
  ecs.timer.start(1, false, function()
    if not started:exited() then
      started:kill(true)
    end
  end)
end

-- The preview

local function sendView(id)
  local view = runners.views[id]
  if preview and preview.ready and view then
    send(preview, {
      type = "view", id = id, path = view.path, x = view.x, y = view.y, zoom = view.zoom,
      width = view.width, height = view.height, chosen = view.chosen, hidden = view.hidden,
    })
    if view.width >= 1 and view.height >= 1 then
      preview.owed[id] = true
      preview.since = os.time()
    end
  end
end

local function oweFrames(path)
  if not preview then
    return
  end
  for id, view in pairs(runners.views) do
    if (not path or view.path == path) and view.width >= 1 and view.height >= 1 then
      preview.owed[id] = true
    end
  end
  preview.since = os.time()
end

-- Sends the node files that the editor holds otherwise than the preview does (DESIGN 12.2).
local function sendFiles()
  if not (preview and preview.ready) then
    return
  end
  for _, path in ipairs(project.nodeFiles()) do
    local file = project.file(path)
    local text = project.text(path)
    if file and file.data and (preview.sent[path] and preview.sent[path] ~= text or not preview.sent[path] and file.dirty) then
      preview.sent[path] = text
      send(preview, { type = "file", path = path, text = text })
      oweFrames()
    end
  end
end

local function ask(name)
  if preview and preview.ready then
    send(preview, { type = "question", name = name })
    preview.owed[name] = true
    preview.since = os.time()
  end
end

---Starts the preview, when a project is open and none runs.
function runners.ensurePreview()
  if preview or blocked or project.folder() == "" then
    return
  end
  preview = start("preview")
  if preview then
    runners.down = nil
    ecs.event.emit("onlr.state")
  end
end

---Starts the preview again, also after a view stopped it twice.
function runners.restartPreview()
  blocked, strikes = false, 0
  if preview then
    stop(preview)
    preview = nil
  end
  runners.ensurePreview()
end

---Ends the preview, such as when the project closes.
function runners.stopPreview()
  stop(preview)
  preview = nil
end

---Sets what a node view shows, and asks the preview to draw it.
---@param id integer the view's number
---@param view table? its node file, its place, zoom and size, and the chosen nodes; nil closes it
function runners.setView(id, view)
  if view then
    runners.views[id] = view
    sendView(id)
  elseif runners.views[id] then
    runners.views[id] = nil
    send(preview, { type = "view", id = id, closed = true })
  end
end

---Sends one edit of a node's own fields, such as while a drag moves it, or of its components' values (values[type][name]).
---@param path string the node file
---@param node string the node's path of ids
---@param fields table<string, any>?
---@param values table<string, table<string, any>>?
function runners.change(path, node, fields, values)
  if preview and preview.ready then
    send(preview, { type = "change", path = path, node = node, fields = fields, values = values })
    oweFrames(path)
  end
end

---The project's files changed in the editor: the preview gets them.
function runners.filesChanged()
  runners.ensurePreview()
  sendFiles()
end

---A file that is not Lua changed on disk, such as an image.
---@param path string
function runners.reload(path)
  if preview and preview.ready then
    send(preview, { type = "reload", path = path })
    oweFrames()
  end
end

local function previewEnded(why)
  local runner = preview
  if not runner then
    return
  end
  preview = nil
  runners.down = why
  console.add(why, "error")
  strikes = strikes + 1
  if strikes >= 2 then
    blocked = true
    console.add("The preview stopped twice in a row. It starts again when asked: Start the preview again.", "error")
  end
  runners.onView("down", { message = why })
  ecs.event.emit("onlr.state")
end

local fromPreview = {}

function fromPreview.hello(message)
  local runner = assert(preview)
  runner.ready = true
  if message.engine then
    ecs.log.info("the preview runs the engine " .. tostring(message.engine))
  end
  sendFiles()
  for id in pairs(runners.views) do
    sendView(id)
  end
  for _, name in ipairs(project.typeNames()) do
    ask(name)
  end
  ecs.event.emit("onlr.state")
end

function fromPreview.frame(message, block)
  local runner = assert(preview)
  runner.owed[message.view] = nil
  strikes = 0
  -- The runner may draw the next frame while the editor shows this one (DESIGN 12.4).
  send(runner, { type = "shown", id = message.view })
  runners.onView("frame", message, block)
end

function fromPreview.bounds(message)
  runners.onView("bounds", message)
end

function fromPreview.answer(message)
  assert(preview).owed[message.name] = nil
  project.setTypeInfo(message.name, message)
  if message.error then
    sayError(tostring(message.error))
  end
end

function fromPreview.error(message)
  local where = message.file and (message.file .. (message.line and (":" .. message.line) or "") .. ": ") or ""
  sayError(where .. tostring(message.message), nil, message.source)
  if message.view then
    assert(preview).owed[message.view] = nil
    runners.onView("error", message)
  end
end

-- The game

local fromGame = {}

function fromGame.hello()
  local runner = assert(game)
  runner.ready = true
  if runners.watching then
    send(runner, runners.watching)
  end
end

function fromGame.tree(message)
  runners.running.tree = message.nodes
  ecs.event.emit("onlr.running", "tree")
end

-- The frames a second and the time of update and draw, twice a second.
function fromGame.stats(message)
  runners.running.stats = { fps = message.fps, update = message.update, draw = message.draw }
  ecs.event.emit("onlr.running", "stats")
end

function fromGame.values(message)
  runners.running.values = message.nodes
  ecs.event.emit("onlr.running", "values")
end

-- The game stopped at an error, and LÖVE shows it; its running tree and values still answer, until Stop (DESIGN 12.6).
function fromGame.halted()
  runners.running.halted = true
  ecs.event.emit("onlr.state")
end

function fromGame.error(message)
  local where = message.file and (message.file .. (message.line and (":" .. message.line) or "") .. ": ") or ""
  sayError(where .. tostring(message.message), message.stack, message.source)
end

---Plays the game: saves the project, then starts the game (DESIGN 13.6).
---@param startPath string? for Play This File, the node file to run as the first root
---@return boolean started
function runners.play(startPath)
  if project.folder() == "" or not project.saveAll() then
    return false
  end
  if game then
    stop(game)
    game = nil
  end
  -- The console clears for the new game, unless its Clear on run toggle is off (DESIGN 12.1).
  console.run()
  local top = project.manifest() and project.manifest().topNode
  if startPath == top then
    -- The top node's own file plays as Play does (DESIGN 12.1).
    startPath = nil
  end
  game = start("game", startPath)
  runners.running = { playing = game ~= nil, paused = false }
  ecs.event.emit("onlr.state")
  return game ~= nil
end

function runners.stop()
  stop(game)
end

---@param paused boolean
function runners.pause(paused)
  if game then
    runners.running.paused = paused
    send(game, { type = paused and "pause" or "resume" })
    ecs.event.emit("onlr.state")
  end
end

function runners.step()
  if game then
    runners.running.paused = true
    send(game, { type = "step" })
    ecs.event.emit("onlr.state")
  end
end

---Asks the game for the running tree, and for the values of running nodes (DESIGN 12.6).
---@param tree boolean
---@param nodes integer[] the nodes' numbers
function runners.watch(tree, nodes)
  runners.watching = { type = "watch", tree = tree, nodes = nodes }
  send(game, runners.watching)
end

---Sets a value of a running node.
---@param message table the node's number, and a field, or a component and a property, with the value
function runners.set(message)
  message.type = "set"
  send(game, message)
end

-- Reading both runners

-- The size of the message that some bytes start, when they hold its first line.
local function wanted(bytes)
  local textSize, blockSize, headerEnd = bytes:match("^(%d+) (%d+)\n()")
  return textSize and headerEnd - 1 + tonumber(textSize) + tonumber(blockSize)
end

local function read(runner, handlers)
  local text = runner.process:read() .. runner.process:readErrors()
  if text ~= "" then
    text = runner.partial .. text
    local last = 1
    for line, after in text:gmatch("(.-)\r?\n()") do
      last = after
      -- OpenAL Soft says on every start that it found no sound device, which says nothing of the game.
      if not line:match("^%[ALSOFT%]") then
        runner.output[#runner.output + 1] = line
        if runner.mode == "game" then
          console.add(line, "info")
        end
      end
    end
    runner.partial = text:sub(last)
  end
  if not runner.connection then
    runner.connection = runner.server:accept()
  end
  if runner.connection then
    local chunks = { runner.buffer }
    local size = #runner.buffer
    local function take()
      local got = false
      while true do
        local bytes = runner.connection:receive(4 * 1024 * 1024)
        if not bytes or bytes == "" then
          return got
        end
        chunks[#chunks + 1] = bytes
        size = size + #bytes
        got = true
      end
    end
    if take() then
      -- A frame is bigger than what the system holds of a connection, so it arrives in parts while the runner sends on.
      -- The rest of a message that has started is read now, for a short while, not at the next tick.
      local need = wanted(chunks[1] ~= "" and chunks[1] or chunks[2])
      local limit = os.clock() + 0.03
      while need and size < need and os.clock() < limit do
        take()
      end
      runner.buffer = table.concat(chunks)
      local messages
      messages, runner.buffer = link.unpack(runner.buffer)
      for _, item in ipairs(messages) do
        runner.since = os.time()
        local handler = handlers[item[1].type]
        if handler then
          handler(item[1], item[2])
        end
      end
    end
  end
end

local function poll()
  if preview then
    local runner = preview
    read(runner, fromPreview)
    if preview == runner then
      local exited = runner.process:exited()
      if exited and not runner.stopping then
        -- What it printed tells why, such as an error in main.lua before the engine loaded.
        for _, line in ipairs(runner.output) do
          console.add(line, "error")
        end
        previewEnded("The preview ended. It starts again at the next change.")
      elseif next(runner.owed) and os.time() - runner.since > 2 then
        -- It gets two seconds for each answer (DESIGN 12.1).
        runner.process:kill(true)
        for _, line in ipairs(runner.output) do
          console.add(line, "error")
        end
        previewEnded("The preview did not answer in two seconds, so it was ended. It starts again at the next change.")
      end
    end
  end
  if game then
    local runner = game
    read(runner, fromGame)
    if runner.process:exited() then
      if runner.partial ~= "" then
        console.add(runner.partial, "info")
      end
      game = nil
      runners.running = { playing = false, paused = false }
      ecs.event.emit("onlr.state")
      ecs.event.emit("onlr.running", "tree")
    end
  end
end

-- Often, so a frame waits little for the editor to take it.
ecs.timer.start(0.004, true, poll)

---Whether the preview runs and has connected.
---@return boolean
function runners.previewReady()
  return preview ~= nil and preview.ready
end

-- A runner ends by itself when the editor is gone: its link closes.

return runners
