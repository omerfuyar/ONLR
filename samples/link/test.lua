-- Checks both players through the link: every message of DESIGN 12.2's tables.
local check = require("check")
local editor = require("editor")

-- A frame's pixel, as OpenECS's images hold it: blue, green, red and alpha.
local function pixel(block, width, x, y)
  local i = (y * width + x) * 4
  return ("%d %d %d %d"):format(block:byte(i + 1, i + 4))
end

local function nodeOf(bounds, path)
  for _, node in ipairs(bounds.nodes) do
    if node.path == path then
      return node
    end
  end
end

local function editPlayer()
  local player = editor.start("coinrun", "edit")
  local hello = player.expect("hello")
  check.equal(hello and hello.mode, "edit", "the edit player says hello")

  -- A view: which node file to draw, from where, and at what size. The player answers with bounds and a frame.
  player.send({ type = "view", id = 1, path = "nodes/level.lua", x = 0, y = 500, zoom = 1, width = 320, height = 180 })
  local bounds = assert(player.expect("bounds"), "no bounds")
  local frame, block = player.expect("frame")
  check.equal({ frame.view, frame.width, frame.height, #block }, { 1, 320, 180, 320 * 180 * 4 }, "a frame of the view's size")
  check.equal(pixel(block, 320, 10, 150), "76 153 51 255", "the ground, with red and blue swapped")
  check.equal(pixel(block, 320, 110, 10), "230 128 77 255", "the player's sprite")
  check.equal(pixel(block, 320, 10, 10), "0 0 0 0", "the view is clear where nothing draws")

  -- Bounds: each node's rectangle in its own space, with its place in the world, by its path of ids.
  local playerNode = assert(nodeOf(bounds, "k3f9pl"), "the player's bounds")
  check.equal({ playerNode.name, playerNode.parent, playerNode.rect, playerNode.place[5], playerNode.place[6] },
    { "Player", "w0r1dn", { 0, 0, 32, 48 }, 100, 500 }, "a node's bounds and place")
  local bigCoin = assert(nodeOf(bounds, "t1r6bz"), "an instance's first node is named by the instance's id")
  check.equal({ bigCoin.name, bigCoin.place[1], bigCoin.file }, { "Big coin", 2, "nodes/coin.lua" }, "an instance's node, from its base")
  check.equal(assert(nodeOf(bounds, "t1r6bz/g1nt4k")).active, false, "a node inside an instance, turned off")
  check.equal(assert(nodeOf(bounds, "f7ag2e")).file, "nodes/level.lua", "a node that the instance adds is the level's")
  check.equal(assert(nodeOf(bounds, "s9c0re")).rect ~= nil, true, "a text has bounds")
  check.equal(assert(nodeOf(bounds, "l3v1q0")).rect, nil, "a node that shows nothing has none")

  -- The player sends a frame only when the editor has shown the last one.
  player.send({ type = "view", id = 1, x = 10 })
  check.equal(player.expect("frame", 0.3), nil, "no frame before the last one was shown")
  player.send({ type = "shown", id = 1 })
  frame, block = player.expect("frame")
  check.equal(pixel(block, 320, 100, 10), "230 128 77 255", "the view moved")

  -- A change: one edit of a node, such as a move. Bounds follow, since a node changed.
  player.send({ type = "change", path = "nodes/level.lua", node = "k3f9pl", fields = { posX = 200, name = "Hero" } })
  player.send({ type = "shown", id = 1 })
  bounds = assert(player.expect("bounds"), "no bounds after a change")
  frame, block = player.expect("frame")
  playerNode = assert(nodeOf(bounds, "k3f9pl"))
  check.equal({ playerNode.name, playerNode.place[5] }, { "Hero", 200 }, "the changed node")
  check.equal({ pixel(block, 320, 200, 10), pixel(block, 320, 100, 10) }, { "230 128 77 255", "0 0 0 0" }, "the node moved in the frame")
  -- The shadow is the player's child, so it moved with it.
  check.equal(assert(nodeOf(bounds, "p7c2sh")).place[5], 200, "a child moves with its parent")

  -- A file: a node file as the editor holds it, saved or not, read in place of the project's file.
  player.send({ type = "file", path = "nodes/unsaved.lua", text = [[
    return {
      format = 1,
      id = "uns4v3",
      name = "Unsaved",
      components = { onlr = { shape = { color = { 1, 0, 0, 1 }, height = 20, width = 20 } } },
    }
  ]] })
  player.send({ type = "view", id = 2, path = "nodes/unsaved.lua", x = 0, y = 0, zoom = 2, width = 64, height = 64 })
  local second
  repeat
    second, block = player.expect("frame")
  until not second or second.view == 2
  check.equal({ pixel(block, 64, 30, 30), pixel(block, 64, 50, 50) }, { "0 0 255 255", "0 0 0 0" }, "an unsaved file, zoomed")

  -- A file that does not load: the view's error names it, and the player goes on.
  player.send({ type = "file", path = "nodes/unsaved.lua", text = "return {" })
  local err = assert(player.expect("error"), "no error")
  check.equal({ err.view, err.file }, { 2, "nodes/unsaved.lua" }, "the error of a file that does not load")
  player.send({ type = "view", id = 2, closed = true })

  -- A question: what a component type declares, in its order, and the types that it needs.
  player.send({ type = "question", name = "player" })
  local answer = assert(player.expect("answer"), "no answer")
  local names, kinds = {}, {}
  for i, p in ipairs(answer.properties) do
    names[i], kinds[i] = p.name, p.kind
  end
  check.equal(names, { "speed", "jumpSound", "startFacing", "jump", "footsteps" }, "the properties, in their order")
  check.equal(kinds, { "number", "sound", "choice", "group", "list" }, "their kinds")
  check.equal({ answer.properties[1].default, answer.properties[1].options.min, answer.properties[3].options.choices },
    { 200, 0, { "left", "right" } }, "defaults and options")
  check.equal({ answer.properties[4].fields[1].name, answer.properties[5].item.kind }, { "height", "sound" }, "a group's fields and a list's kind")
  check.equal({ answer.needs, answer.file }, { { "bump.body" }, "components/player.lua" }, "the types that it needs")
  player.send({ type = "question", name = "nothing" })
  answer = assert(player.expect("answer"))
  check.ok(answer.error and answer.error:find("no component type nothing", 1, true), "why a type does not load")

  -- Reload: a file that is not Lua changed, so the views are made and drawn again.
  player.send({ type = "shown", id = 1 })
  player.send({ type = "reload", path = "images/player.png" })
  frame, block = player.expect("frame")
  check.equal(pixel(block, 320, 100, 10), "230 128 77 255", "after a reload, the view shows the file again")

  -- Stop ends the player.
  player.send({ type = "stop" })
  check.equal(player.stopped(), true, "the edit player ends")
end

-- A drawEditor that fails marks its node, and the rest draws on (DESIGN 6.5).
local function brokenView()
  local player = editor.start("drawing", "edit")
  player.send({ type = "view", id = 1, path = "nodes/broken.lua", x = 0, y = 0, zoom = 1, width = 32, height = 32 })
  local frame, block = player.expect("frame")
  check.equal(frame and pixel(block, 32, 20, 20), "0 255 0 255", "the rest draws on")
  check.equal(pixel(block, 32, 2, 2), "0 0 0 0", "a colour that a drawEditor sets does not reach the next")
  local bounds = assert(player.expect("bounds", 1) or (function()
    player.send({ type = "change", path = "nodes/broken.lua", node = "br0k3n", fields = {} })
    return player.expect("bounds")
  end)(), "no bounds")
  local node = assert(nodeOf(bounds, "br0k3n"))
  check.ok(node.errors and node.errors[1]:find("it fails", 1, true), "the node is marked with the error")
  local second = assert(nodeOf(bounds, "br0k32")).errors
  check.ok(second and second[1]:find("changes nothing in the node view", 1, true),
    "the engine's functions that change the tree change nothing there")
  player.send({ type = "stop" })
  player.stopped()
end

local function playPlayer()
  -- Play This File: the node file runs as the root, under the top node.
  local player = editor.start("coinrun", "play", "--onlr-start=nodes/win.lua")
  local hello = player.expect("hello")
  check.equal(hello and hello.mode, "play", "the play player says hello")

  -- Watch: the running tree, each node with a number.
  player.send({ type = "watch", tree = true })
  local tree = assert(player.expect("tree"), "no tree")
  local byName = {}
  for _, node in ipairs(tree.nodes) do
    byName[node.name] = node
  end
  check.equal({ tree.nodes[1].name, byName.Win.root, byName.Win.parent, byName.Music.components },
    { "Game", true, tree.nodes[1].n, { "music" } }, "the running tree")

  -- Values: the watched nodes' places and their components' values, a reference as what it names.
  player.send({ type = "watch", tree = true, nodes = { byName.Win.n, byName.Music.n } })
  local values = assert(player.expect("values"), "no values")
  local win, music = values.nodes[1], values.nodes[2]
  check.equal({ win.posX, win.components.counter.prefix, win.components["onlr.text"].text },
    { 560, "You win! Coins: ", "You win! Coins: 0" }, "a running node's values")
  check.equal({ win.components["onlr.text"].font, music.components.music.track }, { { size = 24 }, "sounds/theme.wav" },
    "a font and a sound, as what they name")

  -- A running change: a new value for a running node.
  player.send({ type = "set", node = byName.Win.n, field = "posX", value = 5 })
  player.send({ type = "set", node = byName.Win.n, component = "counter", property = "prefix", value = "X" })
  local changed
  for _ = 1, 10 do
    values = assert(player.expect("values"))
    changed = values.nodes[1]
    if changed.components["onlr.text"].text == "X0" then
      break
    end
  end
  check.equal({ changed.posX, changed.components["onlr.text"].text }, { 5, "X0" }, "the game runs on with the new values")
  player.send({ type = "set", node = byName.Win.n, component = "onlr.text", property = "enabled", value = false })

  -- Pause stops the game: the counter no longer writes the text. Step runs one frame.
  player.send({ type = "pause" })
  player.send({ type = "set", node = byName.Win.n, component = "counter", property = "prefix", value = "Y" })
  local text
  for _ = 1, 5 do
    values = assert(player.expect("values"))
    text = values.nodes[1].components["onlr.text"].text
  end
  check.equal({ text, values.nodes[1].components["onlr.text"].enabled }, { "X0", false }, "paused: nothing updates")
  player.send({ type = "step" })
  for _ = 1, 10 do
    values = assert(player.expect("values"))
    text = values.nodes[1].components["onlr.text"].text
    if text == "Y0" then
      break
    end
  end
  check.equal(text, "Y0", "a step runs one frame")
  player.send({ type = "resume" })

  -- The tree is sent again when it changes: turning a node off changes it.
  player.expect("tree", 0.5)
  player.send({ type = "set", node = byName.Win.n, field = "active", value = false })
  tree = assert(player.expect("tree", 2), "the tree after a change")
  player.send({ type = "watch" })

  -- Stop ends the game.
  player.send({ type = "stop" })
  check.equal(player.stopped(), true, "the play player ends")
  check.ok(not player.printed():find("Error", 1, true), "it printed no error")
end

-- An error goes to the editor with its file, line and stack.
local function errors()
  local player = editor.start("life", "play", "--onlr-start=nodes/failing.lua")
  local err = assert(player.expect("error", 10), "no error")
  check.equal({ err.file, err.line, err.message }, { "components/failing.lua", 6, "this component fails in load" }, "an error's file, line and message")
  check.ok(err.stack and err.stack:find("components/failing.lua:6", 1, true), "its stack")
  check.ok(player.printed():find("this component fails in load", 1, true), "what the game prints reaches the editor's console")
end

check.run(function()
  editPlayer()
  brokenView()
  playPlayer()
  errors()
end)
