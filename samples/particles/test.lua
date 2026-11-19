-- Checks the particles package (DESIGN 11.6): an emitter emits at its rate, follows its node in the world, emits at
-- once, tells its node when its particles end, takes changed properties with apply, stays at its node in local space,
-- and stands still while its node is turned off.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

local function near(actual, expected, what, within)
  check.ok(math.abs(actual - expected) <= (within or 0.01), ("%s: %s, not about %s"):format(what, tostring(actual), tostring(expected)))
end

check.run(function()
  local tree = onlr.tree
  local fountain = assert(tree.find("Fountain"))
  local emitter = fountain.components.particles.emitter
  local system = assert(emitter:get())

  -- It emits 60 a second, each living a second: 30 after half a second, and about 60 after that.
  check.equal(system:getBufferSize(), 256, "the buffer's size is the property's")
  check.frames(30)
  near(emitter:getCount(), 30, "30 particles after half a second", 2)
  check.frames(90)
  near(emitter:getCount(), 60, "as many die as are born after a second", 2)
  check.equal(fountain.components.probe.ends, 0, "an emitter that emits until stop never ends")

  -- In the world, the system is at its node, and turns its direction with the node.
  local x, y = system:getPosition()
  near(x, 40, "the system is at its node")
  near(y, 100, "the system is at its node")
  fountain.posX, fountain.rot = 60, 0.5
  check.frames(1)
  near((system:getPosition()), 60, "and follows it")
  near(system:getDirection(), -1.5708 + 0.5, "its direction turns with the node")

  -- apply takes the properties that a script changed.
  emitter.emissionRate = 0
  emitter:apply()
  check.frames(70)
  check.equal(emitter:getCount(), 0, "a rate of 0 emits nothing, after apply")
  emitter.sizes = { 1, 1, 1, 1, 1, 1, 1, 1, 1 }
  check.fails(function()
    emitter:apply()
  end, "up to 8 sizes", "9 sizes are an error")
  emitter.sizes = {}

  -- A burst: no emission at its start, then 20 at once; its node is told when the last dies.
  local burst = assert(tree.find("Burst"))
  local bang = burst.components.particles.emitter
  check.equal(bang:getCount(), 0, "without autoPlay nothing is emitted")
  check.equal(burst.components.probe.ends, 0, "and an emitter that never emitted does not end")
  bang:emit(20)
  check.frames(1)
  check.equal(bang:getCount(), 20, "emit gives its particles at once")
  check.frames(40)
  check.equal(bang:getCount(), 0, "they live half a second")
  check.equal(burst.components.probe.ends, 1, "its node is told that they ended")
  check.frames(10)
  check.equal(burst.components.probe.ends, 1, "once")
  bang:emit(5)
  check.frames(40)
  check.equal(burst.components.probe.ends, 2, "and again after the next emit")

  -- A puff emits for half a second; by now its last particle has died, and its node was told.
  local puff = assert(tree.find("Puff"))
  check.equal(puff.components.probe.ends, 1, "an emitter's lifetime ends, and its node is told")
  check.equal(puff.components.particles.emitter:get():isActive(), false, "it emits no more")
  puff.components.particles.emitter:play()
  check.frames(6)
  check.ok(puff.components.particles.emitter:getCount() > 0, "play emits again")

  -- In local space the system stays at the node's own place, and the node's transform moves it.
  local ring = assert(tree.find("Ring"))
  local rx, ry = ring.components.particles.emitter:get():getPosition()
  check.equal(rx + ry, 0, "a local system stays at its node's own place")

  -- A node turned off: its emitter stands still.
  local count = ring.components.particles.emitter:getCount()
  ring:setActive(false)
  check.frames(30)
  check.equal(ring.components.particles.emitter:getCount(), count, "a node turned off holds its particles")
  ring:setActive(true)

  -- The node view's picture: the system after a particle's lifetime, made once.
  love.graphics.push("all")
  bang:drawEditor(false)
  love.graphics.pop()
  check.ok(bang.shown:getCount() > 0, "the node view shows particles of an emitter that a script starts")
end)
