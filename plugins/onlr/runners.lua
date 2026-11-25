-- The runners (DESIGN 12.1): LÖVE started on the project's folder, as programs of their own, and the link with each.
-- The preview runs while a project is open, and the game while the user plays it.

local ecs = require("ecs")
local net = require("net")
local process = require("process")
local project = require("project")
local console = require("console")
local link = require("link")
local stringBuffer = require("string.buffer")
local hints = require("hints")
local runtimes = require("runtimes")

local runners = {}

---A runner: LÖVE as the editor started it, and its link.
---@class onlr.editor.Runner
---@field mode "preview"|"game"
---@field process any
---@field server any the link's listening end
---@field connection any? the link, once the runner has connected
---@field buffer string.buffer what arrived and was not read yet
---@field ready boolean it sent hello
---@field output string[] the preview's last lines, which it shows when it ends; the game's go to the console at once
---@field partial string the start of a line that it has not ended yet
---@field sent table<string, string> the node files' texts that it was sent
---@field owed table<any, boolean> the answers that it owes: a type's name, or a view's number
---@field since number when it was last asked, or last heard, by the clock below
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

-- The lines of the preview that the editor keeps, which it shows when the preview ends: the error that ended it is among the
-- last, and a preview that prints at each frame does not grow the editor's memory.
local KEEP = 100

-- Seconds in steps of a tenth, for the preview's two seconds (DESIGN 12.1): os.time counts whole seconds, so two of them were
-- two to three, and os.clock counts the editor's own work, not the time that passes.
local clock = 0
ecs.timer.start(0.1, true, function()
  clock = clock + 0.1
end)

---The running game: whether it is paused, or halted at an error, and what the game sent of it.
runners.running = { playing = false, paused = false, tree = nil, values = nil }

---Called with each message of the preview for a view: its type, the message, and its block with its size in bytes. The block
---lies in the runner's buffer, and is read during the call only.
---@type fun(type: string, message: table, block: ffi.cdata*?, size: integer?)
runners.onView = function() end

ecs.event.declare("state", "A runner started, ended, paused or went on")
ecs.event.declare("running", "The game sent the running tree, or the watched nodes' values")

ecs.setting.declare({
  name = "playTint",
  type = "color",
  description = "The colour that the editor takes while a game plays, mixed into its panels, tabs and space around them, so the user sees that changes to the running game are not kept",
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
-- What takes the tint, and how much of it, over the theme's own colour (OpenECS DESIGN 12.4): the space around the panels, the
-- title bar, the rows of tabs, the tabs, the panels and their buttons, and the lines around them, each a part, so the whole editor
-- looks other while the game plays, as Unity's does. Fields and text keep their colours, so what is typed stays readable.
local TINTED = {
  ["ecs.colorBackground"] = 0.35,
  ["ecs.colorTabRow"] = 0.35,
  ["ecs.colorTab"] = 0.3,
  ["ecs.colorTabShown"] = 0.25,
  ["ecs.colorPanel"] = 0.25,
  ["ecs.colorButton"] = 0.2,
  ["ecs.colorButtonHover"] = 0.2,
  ["ecs.colorFrame"] = 0.4,
}

-- A colour "#RRGGBB" or "#RRGGBBAA" mixed with another by an amount from 0 to 1; a colour of another form is taken whole.
local function mix(base, tint, amount)
  local function parts(color)
    local r, g, b = tostring(color):match("^#(%x%x)(%x%x)(%x%x)")
    return r and { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) }
  end
  local a, b = parts(base), parts(tint)
  if not a or not b then
    return tint
  end
  local out = {}
  for i = 1, 3 do
    out[i] = math.floor(a[i] + (b[i] - a[i]) * amount + 0.5)
  end
  return ("#%02X%02X%02X"):format(out[1], out[2], out[3])
end

-- Whether a game plays, and whether it is paused: settings that the editor sets for the run only, so the title bar shows its Play
-- and Pause buttons on while they are true (DESIGN 13.2, OpenECS DESIGN 6.11). Their values in the user's files mean nothing.
ecs.setting.declare({ name = "playing", type = "bool", default = false, description = "Whether a game plays; the editor sets it, for the title bar's Play button" })
ecs.setting.declare({ name = "paused", type = "bool", default = false, description = "Whether the game is paused; the editor sets it, for the title bar's Pause button" })

ecs.event.subscribe("onlr.state", function()
  local playing = runners.running.playing == true
  ecs.setting.setForRun("onlr.playing", playing or nil)
  ecs.setting.setForRun("onlr.paused", (playing and runners.running.paused == true) or nil)
  if playing ~= tinted then
    tinted = playing
    local tint = ecs.setting.get("onlr.playTint")
    for name, amount in pairs(TINTED) do
      -- the theme's colour is read with the run's value taken away first, so a second game does not mix twice
      ecs.setting.setForRun(name, nil)
      ecs.setting.setForRun(name, playing and mix(ecs.setting.get(name), tint, amount) or nil)
    end
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
  -- The link listens on this computer's own address only, so no other computer reaches it, on a free port that net picks (DESIGN 12.2).
  local server, err = net.listen("127.0.0.1", 0)
  if not server then
    console.add(("The link could not listen on this computer: %s"):format(tostring(err)), "error", nil, mode)
    return nil
  end
  local port = server:port()
  local command, environment = {}, {}
  -- The preview opens no window: on Linux, SDL's offscreen driver draws with the graphics card all the same.
  if mode == "preview" and not isWindows then
    environment = { "SDL_VIDEODRIVER=offscreen" }
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
  local started
  started, err = process.start(command, folder, environment)
  if not started then
    console.add(("LÖVE did not start: %s. The setting onlr.love names its executable."):format(tostring(err)), "error", nil, mode)
    return nil
  end
  ---@type onlr.editor.Runner
  return {
    mode = mode, process = started, server = server, buffer = stringBuffer.new(), ready = false, output = {}, partial = "",
    sent = {}, owed = {}, since = clock,
  }
end

-- Adds an error of the game or the preview, its source in the console, with its stack and a hint when the error is one that the hints know (DESIGN 13.1).
-- An error that a component raised names it and its node; when a node file wrote the node, the name is a link, and a click
-- opens the file and chooses the node.
local function sayError(from, text, stack, source)
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
  console.add(stack and (text .. "\n" .. stack) or text, "error", links, from)
  local hint = hints.of(text)
  if hint then
    console.add("Hint: " .. hint, "info", nil, from)
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
      preview.since = clock
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
  preview.since = clock
end

-- Sends the node files that the editor holds otherwise than the preview does (DESIGN 12.2): those of paths, which changed in the
-- editor or on disk, or every node file with changes, when the preview starts. A file's text is the one that its last change wrote,
-- or the one on disk when it does not load, so the preview fails on it too and empties its views (DESIGN 4.2).
local function sendFiles(paths)
  if not (preview and preview.ready) then
    return
  end
  local sent = false
  for _, path in ipairs(paths or project.nodeFiles()) do
    local file = project.file(path)
    local text = file and file.kind == "node" and (file.text or file.disk)
    if text and preview.sent[path] ~= text and (paths or file.dirty) then
      preview.sent[path] = text
      -- the text goes as the message's block, which is sent as it is, not written as a Lua text with its lines escaped
      send(preview, { type = "file", path = path }, text)
      sent = true
    end
  end
  if sent then
    oweFrames()
  end
end

local function ask(name)
  if preview and preview.ready then
    send(preview, { type = "question", name = name })
    preview.owed[name] = true
    preview.since = clock
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

---Files of the project changed in the editor: the preview gets those that are node files.
---@param paths string[]
function runners.filesChanged(paths)
  runners.ensurePreview()
  sendFiles(paths)
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
  console.add(why, "error", nil, "preview")
  strikes = strikes + 1
  if strikes >= 2 then
    blocked = true
    console.add("The preview stopped twice in a row. It starts again when asked: Start the preview again.", "error", nil, "preview")
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

function fromPreview.frame(message, block, size)
  local runner = assert(preview)
  runner.owed[message.view] = nil
  strikes = 0
  -- The runner may draw the next frame while the editor shows this one (DESIGN 12.4).
  send(runner, { type = "shown", id = message.view })
  runners.onView("frame", message, block, size)
end

function fromPreview.bounds(message)
  runners.onView("bounds", message)
end

function fromPreview.answer(message)
  assert(preview).owed[message.name] = nil
  project.setTypeInfo(message.name, message)
  if message.error then
    sayError("preview", tostring(message.error))
  end
end

function fromPreview.error(message)
  local where = message.file and (message.file .. (message.line and (":" .. message.line) or "") .. ": ") or ""
  sayError("preview", where .. tostring(message.message), nil, message.source)
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
  sayError("game", where .. tostring(message.message), message.stack, message.source)
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

local function read(runner, handlers)
  local text = runner.process:read() .. runner.process:readErrors()
  if text ~= "" then
    text = runner.partial .. text
    local last = 1
    for line, after in text:gmatch("(.-)\r?\n()") do
      last = after
      -- OpenAL Soft says on every start that it found no sound device, which says nothing of the game.
      if not line:match("^%[ALSOFT%]") then
        if runner.mode == "game" then
          console.add(line, "info", nil, "game")
        else
          runner.output[#runner.output + 1] = line
          if #runner.output > KEEP then
            table.remove(runner.output, 1)
          end
        end
      end
    end
    runner.partial = text:sub(last)
  end
  if not runner.connection then
    runner.connection = runner.server:accept()
  end
  if runner.connection then
    -- What arrives is added to the runner's buffer, and the messages are read where they lie in it, so a frame is copied once.
    local buf = runner.buffer
    local function take()
      local got = false
      while true do
        local bytes = runner.connection:receive(4 * 1024 * 1024)
        if not bytes or bytes == "" then
          return got
        end
        buf:put(bytes)
        got = true
      end
    end
    if take() then
      -- A frame is bigger than what the system holds of a connection, so it arrives in parts while the runner sends on.
      -- The rest of a message that has started is read now, for a short while, not at the next tick.
      local need = link.need(buf)
      local limit = os.clock() + 0.03
      while need and #buf < need and os.clock() < limit do
        take()
      end
      link.unpack(buf, function(message, block, size)
        runner.since = clock
        local handler = handlers[message.type]
        if handler then
          handler(message, block, size)
        end
      end)
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
          console.add(line, "error", nil, "preview")
        end
        previewEnded("The preview ended. It starts again at the next change.")
      elseif next(runner.owed) and clock - runner.since > 2 then
        -- It gets two seconds for each answer (DESIGN 12.1).
        runner.process:kill(true)
        for _, line in ipairs(runner.output) do
          console.add(line, "error", nil, "preview")
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
        console.add(runner.partial, "info", nil, "game")
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
