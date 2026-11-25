-- Checks the shadows package (DESIGN 11.14): the library sets no global; a lamp lights the ground near it and not far
-- from it; a wall casts a shadow behind it; a lamp follows its node and takes its colour; a wall turned off casts
-- none; and a camera above the world moves and zooms the light with the world.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

-- A pixel of the window, as LÖVE shows it at the end of the frame, from 0 to 255.
local function rgb(x, y)
  local shot
  love.graphics.captureScreenshot(function(data)
    shot = data
  end)
  check.frames(2)
  local r, g, b = assert(shot, "no screenshot"):getPixel(x, y)
  return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

local function bright(x, y, what)
  local r, g, b = rgb(x, y)
  check.ok(r > 128 and g > 128 and b > 128, ("%s: %d %d %d is not bright"):format(what, r, g, b))
end

local function dark(x, y, what)
  local r, g, b = rgb(x, y)
  check.ok(r < 30 and g < 30 and b < 30, ("%s: %d %d %d is not dark"):format(what, r, g, b))
end

check.run(function()
  local tree = onlr.tree
  check.equal(rawget(_G, "shadows"), nil, "the library sets no global")
  check.frames(2)

  -- The lamp at 30, 30 reaches 120 pixels, and fades on the way; the wall at 45 to 50 across, 25 to 35 down, is in
  -- its way to the right.
  bright(34, 30, "the ground next to the lamp is lit")
  dark(150, 115, "beyond its reach it is dark")
  dark(58, 30, "behind the wall it is in shadow")
  bright(30, 58, "beside the wall, as far, it is lit")

  -- A wall turned off casts no shadow.
  local wall = assert(tree.find("Wall"))
  wall:setActive(false)
  check.frames(1)
  bright(58, 30, "without the wall, behind it is lit")
  wall:setActive(true)
  check.frames(1)
  dark(58, 30, "and in shadow again")

  -- The wall's shadow is its onlr.shape: a shape made longer casts a longer shadow, and one of another kind casts its own.
  local shape = wall.components.onlr.shape
  local caster = wall.components.shadows.caster
  local box = caster:get()
  shape.height = 40
  check.frames(1)
  dark(58, 60, "a longer wall casts a longer shadow")
  shape.kind, shape.radius = "circle", 4
  check.frames(1)
  check.ok(caster:get() ~= nil and caster:get() ~= box, "a circle casts its own shadow")
  shape.kind, shape.height = "rectangle", 10
  check.frames(1)
  dark(58, 30, "and the wall casts its shadow again")

  -- A light with no world above it adds one to the root, as a body of physics or bump does.
  local loose = tree.newNode("Loose")
  check.equal(tree.root.components.shadows.world, nil, "the root has no world of its own")
  loose:addComponent("shadows.light")
  check.ok(tree.root.components.shadows.world ~= nil, "the light added a world to the root")
  -- the root's world would darken all under it, the room's own world too, so it goes with the light
  loose:destroy()
  tree.root:removeComponent("shadows.world")
  check.frames(1)

  -- The lamp follows its node, and takes its colour.
  local lamp = assert(tree.find("Lamp"))
  local light = lamp.components.shadows.light
  lamp.posX, lamp.posY = 130, 90
  check.frames(1)
  bright(130, 92, "the light follows its node")
  dark(30, 30, "and is gone from where it was")
  light.color = { 1, 0, 0, 1 }
  check.frames(1)
  local r, g, b = rgb(130, 92)
  check.ok(r > 128 and g < 30 and b < 30, ("a red lamp lights red: %d %d %d"):format(r, g, b))
  light.color = { 1, 1, 1, 1 }
  lamp.posX, lamp.posY = 30, 30

  -- Its arc is in radians, as every angle is: a quarter turn lights ahead of its node's way, 37 degrees to the side of it,
  -- and not beside the lamp.
  light.arc = math.pi / 2
  check.frames(1)
  bright(50, 45, "a beam of a quarter turn lights ahead")
  dark(30, 58, "and not beside the lamp")
  light.arc = 2 * math.pi
  check.frames(1)
  bright(30, 58, "a whole turn lights beside it again")

  -- A camera that shows the world 40 pixels to the right: the lamp at 30, 30 of the world is at -10, 30 of the window.
  local view = assert(tree.find("View")).components.onlr.camera.view
  view.posX = 120
  check.frames(1)
  bright(2, 30, "the light moves with the camera")
  dark(30, 30, "and leaves where it was")

  -- Twice as large, around the lamp, which is at the window's middle: what is 27 pixels below it is 55 below it in
  -- the window, and lit; and the wall's shadow is twice as far to the right.
  view.posX, view.posY, view.zoom = 30, 30, 2
  check.frames(1)
  bright(80, 115, "the light grows with the camera's zoom")
  dark(136, 60, "and so does the wall's shadow")
end)
