-- A script: a component type that the user writes. Scripts are in components/.
-- The user attaches it to objects in the editor.
local onlr = require("onlr")

---@class components.player : onlr.Component
local Player = {}

-- Properties. The inspector shows them in this order, and the scene keeps their values.
-- The component reads each under the same name: self.speed.
Player.speed = onlr.property.number(200, { min = 0, description = "Pixels a second" })
Player.jumpSound = onlr.property.sound()
Player.startFacing = onlr.property.choice("right", { choices = { "left", "right" } })

-- A group: the inspector shows its fields under one heading. Read as self.jump.height.
Player.jump = onlr.property.group({
  height = onlr.property.number(96),
  time = onlr.property.number(0.4),
})

-- A list: the user adds and removes rows. Read as self.footsteps[1].
Player.footsteps = onlr.property.list(onlr.property.sound())

-- Once, when the object enters the running scene. The properties are set by now.
function Player:load()
  -- Another component of the same object. The body is the pack's; move is its function.
  self.body = self.object:get("bump.body")
  -- A field of the script's own. It is not a property, so the inspector does not show it.
  self.velocityY = 0
end

-- Each frame. Any function of LÖVE may be called.
function Player:update(dt)
  local x, y = self.object:toWorld(0, 0)
  if love.keyboard.isDown("right") then
    x = x + self.speed * dt
  elseif love.keyboard.isDown("left") then
    x = x - self.speed * dt
  end
  self.velocityY = self.velocityY + 900 * dt
  self.body:move(x, y + self.velocityY * dt)
end

-- Any callback of LÖVE, under its name and with what LÖVE gives.
function Player:keypressed(key)
  if key == "space" then
    self.velocityY = -2 * self.jump.height / self.jump.time
    if self.jumpSound then
      self.jumpSound:play()
    end
  end
end

-- Not LÖVE's and not the engine's: the body calls it with object:send("contact", ...).
function Player:contact(other, normalX, normalY)
  if normalY < 0 then
    self.velocityY = 0
  end
end

return Player
