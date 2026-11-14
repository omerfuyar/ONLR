-- The players (DESIGN 12.1): LÖVE started on the project's folder, as programs of their own, and the link with each.
-- The edit player runs while a project is open, and the play player while the game plays.

local ecs = require("ecs")
local net = require("net")
local process = require("process")
local project = require("onlr_project")
local console = require("console")
local link = require("link")

local players = {}

---A player: LÖVE as the editor started it, and its link.
---@class onlr_player.Player
---@field mode "edit"|"play"
---@field process any
---@field server any the link's listening end
---@field connection any? the link, once the player has connected
---@field buffer string what arrived and was not read yet
---@field ready boolean it sent hello
---@field output string[] what it printed
---@field partial string the start of a line that it has not ended yet
---@field sent table<string, string> the node files' texts that it was sent
---@field owed table<any, boolean> the answers that it owes: a type's name, or a view's number
---@field since integer when it was last asked, or last heard
---@field stopping boolean? the editor asked it to end

---@type onlr_player.Player?
local edit
---@type onlr_player.Player?
local play

---The views that the node views show, by number: what the edit player draws (DESIGN 12.3).
---@type table<integer, table>
players.views = {}

---Why the edit player is down, when it is.
---@type string?
players.down = nil
-- A view that stopped the edit player twice in a row is not drawn again until the user asks.
local strikes, blocked = 0, false

---The running game: whether it is paused, and what the play player sent of it.
players.running = { playing = false, paused = false, tree = nil, values = nil }

---Called with each message of the edit player for a view: its type, the message and its block.
---@type fun(type: string, message: table, block: string?)
players.onView = function() end

ecs.event.declare("state", "A player started, ended, paused or went on")
ecs.event.declare("running", "The play player sent the running tree, or the watched nodes' values")

ecs.setting.declare({
  name = "love",
  type = "string",
  description = "LÖVE's executable, which runs the players; when empty, the variable LOVE names it, or else it is love",
  default = "",
})

local function lovePath()
  local path = ecs.setting.get("onlr_player.love")
  if type(path) == "string" and path ~= "" then
    return path
  end
  return os.getenv("LOVE") or "love"
end

local isWindows = package.config:sub(1, 1) == "\\"

---@param mode "edit"|"play"
---@param startPath string?
---@return onlr_player.Player?
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
  -- The edit player opens no window: on Linux, SDL's offscreen driver draws with the graphics card all the same.
  if mode == "edit" and not isWindows then
    command = { "env", "SDL_VIDEODRIVER=offscreen" }
  end
  command[#command + 1] = lovePath()
  command[#command + 1] = folder:gsub("/$", "")
  command[#command + 1] = "--onlr-player=" .. project.home() .. "player"
  command[#command + 1] = "--onlr-mode=" .. mode
  command[#command + 1] = "--onlr-port=" .. port
  if startPath then
    command[#command + 1] = "--onlr-start=" .. startPath
  end
  local started, err = process.start(command, folder)
  if not started then
    console.add(("LÖVE did not start: %s. The setting onlr_player.love names its executable."):format(tostring(err)), "error")
    return nil
  end
  ---@type onlr_player.Player
  return {
    mode = mode, process = started, server = server, buffer = "", ready = false, output = {}, partial = "",
    sent = {}, owed = {}, since = os.time(),
  }
end

local function send(player, message, block)
  if player and player.connection then
    player.connection:send(link.pack(message, block))
  end
end

local function stop(player)
  if not player then
    return
  end
  player.stopping = true
  send(player, { type = "stop" })
  local started = player.process
  -- A player that does not end when asked is ended.
  ecs.timer.start(1, false, function()
    if not started:exited() then
      started:kill(true)
    end
  end)
end

-- The edit player

local function sendView(id)
  local view = players.views[id]
  if edit and edit.ready and view then
    send(edit, {
      type = "view", id = id, path = view.path, x = view.x, y = view.y, zoom = view.zoom,
      width = view.width, height = view.height, chosen = view.chosen,
    })
    if view.width >= 1 and view.height >= 1 then
      edit.owed[id] = true
      edit.since = os.time()
    end
  end
end

local function oweFrames(path)
  if not edit then
    return
  end
  for id, view in pairs(players.views) do
    if (not path or view.path == path) and view.width >= 1 and view.height >= 1 then
      edit.owed[id] = true
    end
  end
  edit.since = os.time()
end

-- Sends the node files that the editor holds otherwise than the edit player does (DESIGN 12.2).
local function sendFiles()
  if not (edit and edit.ready) then
    return
  end
  for _, path in ipairs(project.nodeFiles()) do
    local file = project.file(path)
    local text = project.text(path)
    if file and file.data and (edit.sent[path] and edit.sent[path] ~= text or not edit.sent[path] and file.dirty) then
      edit.sent[path] = text
      send(edit, { type = "file", path = path, text = text })
      oweFrames()
    end
  end
end

local function ask(name)
  if edit and edit.ready then
    send(edit, { type = "question", name = name })
    edit.owed[name] = true
    edit.since = os.time()
  end
end

---Starts the edit player, when a project is open and none runs.
function players.ensureEdit()
  if edit or blocked or project.folder() == "" then
    return
  end
  edit = start("edit")
  if edit then
    players.down = nil
    ecs.event.emit("onlr_player.state")
  end
end

---Starts the edit player again, also after a view stopped it twice.
function players.restartEdit()
  blocked, strikes = false, 0
  if edit then
    stop(edit)
    edit = nil
  end
  players.ensureEdit()
end

---Ends the edit player, such as when the project closes.
function players.stopEdit()
  stop(edit)
  edit = nil
end

---Sets what a node view shows, and asks the edit player to draw it.
---@param id integer the view's number
---@param view table? its node file, its place, zoom and size, and the chosen nodes; nil closes it
function players.setView(id, view)
  if view then
    players.views[id] = view
    sendView(id)
  elseif players.views[id] then
    players.views[id] = nil
    send(edit, { type = "view", id = id, closed = true })
  end
end

---Tells the edit player that a node view has shown a view's last frame (DESIGN 12.4).
---@param id integer
function players.shown(id)
  send(edit, { type = "shown", id = id })
end

---Sends one edit of a node's own fields, such as while a drag moves it.
---@param path string the node file
---@param node string the node's path of ids
---@param fields table<string, any>
function players.change(path, node, fields)
  if edit and edit.ready then
    send(edit, { type = "change", path = path, node = node, fields = fields })
    oweFrames(path)
  end
end

---The project's files changed in the editor: the edit player gets them.
function players.filesChanged()
  players.ensureEdit()
  sendFiles()
end

---A file that is not Lua changed on disk, such as an image.
---@param path string
function players.reload(path)
  if edit and edit.ready then
    send(edit, { type = "reload", path = path })
    oweFrames()
  end
end

local function editEnded(why)
  local player = edit
  if not player then
    return
  end
  edit = nil
  players.down = why
  console.add(why, "error")
  strikes = strikes + 1
  if strikes >= 2 then
    blocked = true
    console.add("The edit player stopped twice in a row. It starts again when asked: Start the edit player again.", "error")
  end
  players.onView("down", { message = why })
  ecs.event.emit("onlr_player.state")
end

local edits = {}

function edits.hello(message)
  local player = assert(edit)
  player.ready = true
  if message.engine then
    ecs.log.info("the edit player runs the engine " .. tostring(message.engine))
  end
  sendFiles()
  for id in pairs(players.views) do
    sendView(id)
  end
  for _, name in ipairs(project.typeNames()) do
    ask(name)
  end
  ecs.event.emit("onlr_player.state")
end

function edits.frame(message, block)
  local player = assert(edit)
  player.owed[message.view] = nil
  strikes = 0
  players.onView("frame", message, block)
end

function edits.bounds(message)
  players.onView("bounds", message)
end

function edits.answer(message)
  assert(edit).owed[message.name] = nil
  project.setTypeInfo(message.name, message)
  if message.error then
    console.add(tostring(message.error), "error")
  end
end

function edits.error(message)
  local where = message.file and (message.file .. (message.line and (":" .. message.line) or "") .. ": ") or ""
  console.add(where .. tostring(message.message), "error")
  if message.view then
    assert(edit).owed[message.view] = nil
    players.onView("error", message)
  end
end

-- The play player

local plays = {}

function plays.hello()
  local player = assert(play)
  player.ready = true
  if players.watching then
    send(player, players.watching)
  end
end

function plays.tree(message)
  players.running.tree = message.nodes
  ecs.event.emit("onlr_player.running", "tree")
end

function plays.values(message)
  players.running.values = message.nodes
  ecs.event.emit("onlr_player.running", "values")
end

function plays.error(message)
  local where = message.file and (message.file .. (message.line and (":" .. message.line) or "") .. ": ") or ""
  console.add(where .. tostring(message.message), "error")
  if message.stack then
    console.add(message.stack, "error")
  end
end

---Plays the game: saves the project, then starts the play player (DESIGN 13.6).
---@param startPath string? for Play This File, the node file to run as the first root
---@return boolean started
function players.play(startPath)
  if project.folder() == "" or not project.saveAll() then
    return false
  end
  if play then
    stop(play)
    play = nil
  end
  local top = project.manifest() and project.manifest().topNode
  if startPath == top then
    -- The top node's own file plays as Play does (DESIGN 12.1).
    startPath = nil
  end
  play = start("play", startPath)
  players.running = { playing = play ~= nil, paused = false }
  ecs.event.emit("onlr_player.state")
  return play ~= nil
end

function players.stop()
  stop(play)
end

---@param paused boolean
function players.pause(paused)
  if play then
    players.running.paused = paused
    send(play, { type = paused and "pause" or "resume" })
    ecs.event.emit("onlr_player.state")
  end
end

function players.step()
  if play then
    players.running.paused = true
    send(play, { type = "step" })
    ecs.event.emit("onlr_player.state")
  end
end

---Asks the play player for the running tree, and for the values of running nodes (DESIGN 12.6).
---@param tree boolean
---@param nodes integer[] the nodes' numbers
function players.watch(tree, nodes)
  players.watching = { type = "watch", tree = tree, nodes = nodes }
  send(play, players.watching)
end

---Sets a value of a running node.
---@param message table the node's number, and a field, or a component and a property, with the value
function players.set(message)
  message.type = "set"
  send(play, message)
end

-- Reading both players

local function read(player, handlers)
  local text = player.process:read() .. player.process:readErrors()
  if text ~= "" then
    text = player.partial .. text
    local last = 1
    for line, after in text:gmatch("(.-)\r?\n()") do
      last = after
      -- OpenAL Soft says on every start that it found no sound device, which says nothing of the game.
      if not line:match("^%[ALSOFT%]") then
        player.output[#player.output + 1] = line
        if player.mode == "play" then
          console.add(line, "info")
        end
      end
    end
    player.partial = text:sub(last)
  end
  if not player.connection then
    player.connection = player.server:accept()
  end
  if player.connection then
    local chunks = {}
    while true do
      local bytes = player.connection:receive(4 * 1024 * 1024)
      if not bytes or bytes == "" then
        break
      end
      chunks[#chunks + 1] = bytes
    end
    if #chunks > 0 then
      player.buffer = player.buffer .. table.concat(chunks)
      local messages
      messages, player.buffer = link.unpack(player.buffer)
      for _, item in ipairs(messages) do
        player.since = os.time()
        local handler = handlers[item[1].type]
        if handler then
          handler(item[1], item[2])
        end
      end
    end
  end
end

local function poll()
  if edit then
    local player = edit
    read(player, edits)
    if edit == player then
      local exited = player.process:exited()
      if exited and not player.stopping then
        -- What it printed tells why, such as an error in main.lua before the engine loaded.
        for _, line in ipairs(player.output) do
          console.add(line, "error")
        end
        editEnded("The edit player ended. It starts again at the next change.")
      elseif next(player.owed) and os.time() - player.since > 2 then
        -- It gets two seconds for each answer (DESIGN 12.1).
        player.process:kill(true)
        for _, line in ipairs(player.output) do
          console.add(line, "error")
        end
        editEnded("The edit player did not answer in two seconds, so it was ended. It starts again at the next change.")
      end
    end
  end
  if play then
    local player = play
    read(player, plays)
    if player.process:exited() then
      if player.partial ~= "" then
        console.add(player.partial, "info")
      end
      play = nil
      players.running = { playing = false, paused = false }
      ecs.event.emit("onlr_player.state")
      ecs.event.emit("onlr_player.running", "tree")
    end
  end
end

ecs.timer.start(0.016, true, poll)

---Whether the edit player runs and has connected.
---@return boolean
function players.editReady()
  return edit ~= nil and edit.ready
end

-- A player ends by itself when the editor is gone: its link closes.

return players
