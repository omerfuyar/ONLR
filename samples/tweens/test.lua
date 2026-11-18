-- Checks the flux and tick packages (DESIGN 11.8): a node's tweens move it and its timers call their functions, both
-- wait while the node is turned off and end with it, and stop is safe in their own functions.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

-- Within 2 pixels: a frame of a tween of 100 pixels in a second is 1.7.
local function near(actual, expected, what)
  check.ok(math.abs(actual - expected) < 2, ("%s: %s, not about %s"):format(what, tostring(actual), tostring(expected)))
end

check.run(function()
  local one, two = assert(onlr.tree.find("One")), assert(onlr.tree.find("Two"))
  local mover, tweens, timers = one.components.mover, one.components.flux.tweens, one.components.tick.timers
  check.ok(tweens ~= nil and timers ~= nil, "a script that needs them gets them")

  -- Half a second and a frame, since 30 steps of 1/60 fall a hair short of 0.5: the tween is half way, the timer has
  -- ticked twice, and the delay has come.
  check.frames(31)
  near(one.posX, 50, "a linear tween is half way after half its time")
  check.equal(mover.ticks, 2, "a timer every quarter of a second has ticked twice")
  check.equal(mover.later, true, "a delay of half a second has come")
  check.equal(tweens:count(), 1, "one tween moves")

  -- Turned off for half a second: nothing moves, and nothing ticks.
  two:setActive(false)
  local x, ticks = two.posX, two.components.mover.ticks
  check.frames(30)
  check.equal(two.posX, x, "a node turned off: its tweens wait")
  check.equal(two.components.mover.ticks, ticks, "and its timers wait")
  two:setActive(true)

  -- A quarter of a second on: the second node goes on from where it waited, and the first's tween has ended.
  check.frames(15)
  near(two.posX, 75, "the second node goes on from where it waited")
  check.equal(one.posX, 100, "the tween ends at its value")
  check.equal(mover.slid, true, "and calls oncomplete")
  check.equal(tweens:count(), 0, "and is gone")

  -- stop: a tween of a table stops where it is, and calls no oncomplete; the others go on.
  local a, b, done = { v = 0 }, { v = 0 }, false
  tweens:to(a, 1, { v = 10 }):ease("linear"):oncomplete(function()
    done = true
  end)
  tweens:to(b, 1, { v = 10 }):ease("linear")
  check.frames(30)
  tweens:stop(a)
  check.frames(60)
  near(a.v, 5, "a stopped tween stays where it was")
  check.equal(done, false, "and calls no oncomplete")
  check.equal(b.v, 10, "the other went on")

  -- stop in a timer's own function, while the timers update: every timer ends, and nothing breaks.
  local calls = 0
  for _ = 1, 3 do
    timers:delay(function()
      calls = calls + 1
      timers:stop()
    end, 0.1)
  end
  check.frames(10)
  check.equal(calls, 1, "the first timer stopped the others")
  local count = mover.ticks
  check.frames(30)
  check.equal(mover.ticks, count, "a stopped recurring timer ticks no more")
  check.equal(timers:count(), 0, "no timer waits")

  -- A stopped tween in a tween's own function.
  local c = { v = 0 }
  tweens:to(c, 0.1, { v = 1 }):oncomplete(function()
    tweens:stop()
  end)
  tweens:to({ v = 0 }, 1, { v = 1 })
  tweens:to({ v = 0 }, 1, { v = 1 })
  check.frames(10)
  check.equal(tweens:count(), 0, "stop in oncomplete ends every tween")

  -- Destroyed: a node's timers end with it, and call nothing.
  local second = two.components.mover
  two:destroy()
  local after = second.ticks
  check.frames(30)
  check.equal(second.ticks, after, "a destroyed node's timers call nothing")
end)
