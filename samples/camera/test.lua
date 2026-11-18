-- Checks the camera helpers (DESIGN 10): a camera that follows its target, smoothly and with a deadzone, that keeps
-- inside its limits at any zoom, and that shakes without moving its own point.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

local function near(actual, expected, what)
  check.ok(math.abs(actual - expected) < 0.5, ("%s: %s, not about %s"):format(what, tostring(actual), tostring(expected)))
end

check.run(function()
  local world, player = assert(onlr.tree.find("World")), assert(onlr.tree.find("Player"))
  local camera = assert(world.components.onlr.camera.view)
  local follow, shake = assert(world.components.onlr.camera.follow), assert(world.components.onlr.camera.shake)
  check.ok(world.components.onlr.camera.limits ~= nil, "the world has its limits")
  check.equal(follow.target, player, "the target is the player, by its id")
  check.equal(select(1, camera:getSize()), 160, "the camera's screen is the window")

  -- At the start the camera is on the player, kept inside the world: the window is 160 by 120, so the camera's point
  -- is at least 80 from the left and 60 from the top.
  near(camera.posX, 80, "the player is near the left edge: the camera stops at it")
  near(camera.posY, 60, "and at the top")

  -- The player in the middle: the camera catches up, smoothly.
  player.posX, player.posY = 200, 100
  check.frames(1)
  check.ok(camera.posX > 80 and camera.posX < 200, "after a frame it is on its way: " .. camera.posX)
  check.frames(60)
  near(camera.posX, 200, "after a second it is on the player")
  near(camera.posY, 100, "on both axes")

  -- A deadzone of 40: the player moves 10 and the camera stays; 30, and it moves 10.
  follow.smoothing = 0
  follow.deadzone.x, follow.deadzone.y = 40, 40
  player.posX = 210
  check.frames(1)
  near(camera.posX, 200, "inside the deadzone the camera stays")
  player.posX = 230
  check.frames(1)
  near(camera.posX, 210, "past it, the camera keeps the player at its edge")

  -- The limits: at the world's far corner, the camera stops short of it.
  player.posX, player.posY = 390, 190
  check.frames(1)
  near(camera.posX, 320, "the camera stops at the right edge")
  near(camera.posY, 140, "and at the bottom")

  -- Zoomed out until it shows more than the world: it is centred on the world.
  camera.zoom = 0.25
  check.frames(1)
  near(camera.posX, 200, "a view larger than the limits is centred")
  near(camera.posY, 100, "on both axes")
  camera.zoom = 1

  -- A shake moves the drawing, and fades; the camera's own point stays where the follow put it.
  check.frames(1)
  local x = camera.posX
  shake:shake(1)
  check.frames(3)
  check.ok(camera.shakeX ~= 0 or camera.shakeY ~= 0, "a shake moves the drawing")
  near(camera.posX, x, "and not the camera's point")
  check.ok(shake:getTrauma() < 1, "it fades")
  check.frames(60)
  check.equal(shake:getTrauma(), 0, "and ends")
  check.equal(camera.shakeX, 0, "and the drawing is still")

  -- A target that is destroyed: the camera stays, and nothing breaks.
  player:destroy()
  check.frames(2)
  near(camera.posX, x, "a camera whose target is gone stays")
end)
