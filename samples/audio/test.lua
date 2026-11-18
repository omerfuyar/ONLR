-- Checks the audio package (DESIGN 11.12): music streams and loops from its start; a source plays when a script asks,
-- and its node is told when it ends; playNew plays copies over each other; a sound with a place follows its node, and
-- one without plays at the listener; a script's changes reach LÖVE; a node turned off pauses its sounds; the listener
-- hears from its node, or from its camera's point; and a stereo sound cannot have a place.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

local function near(actual, expected, what, within)
  check.ok(math.abs(actual - expected) <= (within or 0.01), ("%s: %s, not about %s"):format(what, tostring(actual), tostring(expected)))
end

check.run(function()
  local tree = onlr.tree
  check.frames(1)

  -- Music: streamed, looping, playing from the start.
  local song = assert(tree.find("Song")).components.audio.music
  local track = assert(song:get())
  check.equal(track:getType(), "stream", "music streams")
  check.equal(track:isLooping(), true, "and loops")
  check.equal(song:isPlaying(), true, "and plays from its start")
  near(track:getVolume(), 0.4, "at its volume")

  -- A source: decoded whole, silent until a script plays it, and its node told when it ends.
  local beepNode = assert(tree.find("Beep"))
  local beep = beepNode.components.audio.source
  check.equal(assert(beep:get()):getType(), "static", "a source is decoded whole")
  check.equal(beep:isPlaying(), false, "without autoPlay it waits")
  check.equal(beep:get():isRelative(), true, "a mono sound without a place plays at the listener")
  beep:play()
  check.frames(1)
  check.equal(beep:isPlaying(), true, "play plays it")
  love.timer.sleep(0.25)
  check.frames(1)
  check.equal(beep:isPlaying(), false, "it ends")
  check.equal(beepNode.components.probe.ends, 1, "and its node is told")
  check.frames(2)
  check.equal(beepNode.components.probe.ends, 1, "once")
  beep:play()
  beep:stop()
  check.frames(1)
  check.equal(beepNode.components.probe.ends, 1, "stop does not tell it")

  -- playNew: copies that play over each other, and stop stops them all.
  local a, b = beep:playNew(), beep:playNew()
  check.ok(a ~= b and a:isPlaying() and b:isPlaying(), "two copies play at once")
  beep:stop()
  check.ok(not a:isPlaying() and not b:isPlaying(), "stop stops the copies")

  -- A script's changes reach LÖVE in the next frame, as a tween's do.
  beep.volume, beep.pitch, beep.looping = 0.3, 1.5, true
  check.frames(1)
  near(beep:get():getVolume(), 0.3, "the volume")
  near(beep:get():getPitch(), 1.5, "the pitch")
  check.equal(beep:get():isLooping(), true, "looping")

  -- A sound with a place: at its node in the world, following it.
  local humNode = assert(tree.find("Hum"))
  local hum = assert(humNode.components.audio.source:get())
  check.equal(hum:isRelative(), false, "a sound with a place is in the world")
  local x, y = hum:getPosition()
  check.equal({ x, y }, { 280, 60 }, "at its node")
  local min, max = hum:getAttenuationDistances()
  check.equal({ min, max }, { 50, 400 }, "with its distances")
  humNode.posX = 100
  check.frames(1)
  check.equal((hum:getPosition()), 100, "and follows it")

  -- A node turned off pauses its sounds, and they play on.
  local songNode = assert(tree.find("Song"))
  songNode:setActive(false)
  check.equal(song:isPlaying(), false, "a node turned off pauses its sound")
  songNode:setActive(true)
  check.equal(song:isPlaying(), true, "and it plays on")

  -- The listener: LÖVE's, at its node, with its volume and distance model.
  local ears = assert(tree.find("Ears"))
  local lx, ly = love.audio.getPosition()
  check.equal({ lx, ly }, { 80, 60 }, "the listener is at its node")
  near(love.audio.getVolume(), 0.5, "with its volume")
  check.equal(love.audio.getDistanceModel(), "linearclamped", "and its distance model")
  ears.posX = 90
  check.frames(1)
  check.equal((love.audio.getPosition()), 90, "and follows it")
  local view = ears:addComponent("onlr.camera.view", { posX = 200, posY = 10 })
  check.frames(1)
  lx, ly = love.audio.getPosition()
  check.equal({ lx, ly }, { 290, 70 }, "on a camera's node, it hears from the camera's point")
  view.posX = 0
  check.fails(function()
    tree.newNode("More ears"):addComponent("audio.listener")
  end, "a game has one listener", "a second listener is an error")

  -- A stereo sound has no place in the world.
  check.fails(function()
    tree.newNode("Wide"):addComponent("audio.source", { sound = "sounds/wide.wav", positional = true })
  end, "has one channel", "a stereo sound with a place is an error")
  local wide = tree.newNode("Wide too"):addComponent("audio.source", { sound = "sounds/wide.wav" })
  wide:play()
  check.equal(wide:isPlaying(), true, "and plays without one")
  wide:stop()
end)
