-- Checks the moonshine package (DESIGN 11.11): a group drawn through its effects, at its node's place and not twice
-- moved, an effect turned off, a property changed, an effect removed, and a chain with no effect.
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
  local effects = scene.components.moonshine
  check.ok(effects.chain:get() == nil, "the chain is made when it first draws")

  -- Desaturated fully: the red square is grey, where its node is.
  local r, g, b = rgb(45, 35)
  check.ok(r == g and g == b and r > 40 and r < 120, ("the square is grey: %d %d %d"):format(r, g, b))
  check.equal(color(85, 65), "0 0 0", "and is not moved twice")
  check.ok(effects.chain:get() ~= nil, "the chain is made")

  -- An effect turned off is skipped.
  effects.desaturate:setEnabled(false)
  check.equal(color(45, 35), "255 0 0", "with desaturate off, the square is red")
  effects.desaturate:setEnabled(true)

  -- A property that a script changes reaches the effect.
  effects.desaturate.strength = 0
  check.equal(color(45, 35), "255 0 0", "with a strength of 0, the square is red")
  effects.colorgradesimple.factors.r = 0.5
  r = rgb(45, 35)
  check.ok(math.abs(r - 128) <= 1, "colorgradesimple halves the red: " .. r)

  -- An effect removed: the chain is made again without it.
  local built = effects.chain:get()
  scene:removeComponent("moonshine.colorgradesimple")
  check.frames(1) -- a component is taken off when the frame ends
  check.equal(color(45, 35), "255 0 0", "without colorgradesimple, the red is whole")
  check.ok(effects.chain:get() ~= built, "the chain was made again")

  -- A chain with no effect draws its nodes as they are.
  scene:removeComponent("moonshine.desaturate")
  check.frames(1)
  check.equal(color(45, 35), "255 0 0", "a chain with no effect draws as it is")
end)
