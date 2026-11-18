-- Checks the moonshine package (DESIGN 11.11): a group drawn through its effects, at its node's place and not twice
-- moved, an effect turned off, a property changed, the order of the effects, an effect removed, and a chain with no
-- effect.
local check = require("check")
local onlr = require("onlr")

-- The window's pixels, as LÖVE shows them at the end of the frame.
local function capture()
  local shot
  love.graphics.captureScreenshot(function(data)
    shot = data
  end)
  check.frames(2)
  return assert(shot, "no screenshot")
end

local function rgb(x, y)
  local r, g, b = capture():getPixel(x, y)
  return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

local function color(x, y)
  return ("%d %d %d"):format(rgb(x, y))
end

check.run(function()
  local scene = assert(onlr.tree.find("Scene"))
  local moon = scene.components.moonshine
  check.ok(moon.chain:get() == nil, "the chain is made when it first draws")

  -- Desaturated fully: the red square is grey, where its node is.
  local r, g, b = rgb(45, 35)
  check.ok(r == g and g == b and r > 40 and r < 120, ("the square is grey: %d %d %d"):format(r, g, b))
  check.equal(color(85, 65), "0 0 0", "and is not moved twice")
  check.ok(moon.chain:get() ~= nil, "the chain is made")

  -- An effect turned off is skipped.
  moon.effect.desaturate:setEnabled(false)
  check.equal(color(45, 35), "255 0 0", "with desaturate off, the square is red")
  moon.effect.desaturate:setEnabled(true)

  -- A property that a script changes reaches the effect.
  moon.effect.desaturate.strength = 0
  check.equal(color(45, 35), "255 0 0", "with a strength of 0, the square is red")
  moon.effect.colorgradesimple.factors.r = 0.5
  r = rgb(45, 35)
  check.ok(math.abs(r - 128) <= 1, "colorgradesimple halves the red: " .. r)

  -- order: the effects apply in the order that it names. Desaturated after the red is halved, the square is a dark
  -- grey; halved after it is desaturated, its green and blue stay whole and its red is halved.
  moon.effect.desaturate.strength = 1
  moon.chain.order = { "colorgradesimple", "desaturate" }
  local r1, g1, b1 = rgb(45, 35)
  check.ok(r1 == g1 and g1 == b1, ("graded, then desaturated: grey, %d %d %d"):format(r1, g1, b1))
  moon.chain.order = { "desaturate" }
  local r2, g2 = rgb(45, 35)
  check.ok(r2 < g2, ("desaturated, then graded by name after it: the red is less, %d %d"):format(r2, g2))
  moon.effect.desaturate.strength = 0
  moon.chain.order = {}

  -- An effect removed: the chain is made again without it.
  local built = moon.chain:get()
  scene:removeComponent("moonshine.effect.colorgradesimple")
  check.frames(1) -- a component is taken off when the frame ends
  check.equal(color(45, 35), "255 0 0", "without colorgradesimple, the red is whole")
  check.ok(moon.chain:get() ~= built, "the chain was made again")

  -- A chain with no effect draws its nodes as they are.
  scene:removeComponent("moonshine.effect.desaturate")
  check.frames(1)
  check.equal(color(45, 35), "255 0 0", "a chain with no effect draws as it is")
end)
