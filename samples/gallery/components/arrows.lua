-- Moves its node with the arrow keys, through its bump body when it has one, so walls stop it.
local onlr = require("onlr")

---@class arrows : onlr.Component
local Arrows = {}

Arrows.speed = onlr.property.number(160, { min = 0, description = "Pixels a second" })

function Arrows:update(dt)
  local x, y = 0, 0
  if love.keyboard.isDown("left") then x = x - 1 end
  if love.keyboard.isDown("right") then x = x + 1 end
  if love.keyboard.isDown("up") then y = y - 1 end
  if love.keyboard.isDown("down") then y = y + 1 end
  local nx, ny = self.node.posX + x * self.speed * dt, self.node.posY + y * self.speed * dt
  local body = self.node.components.bump and self.node.components.bump.body
  if body then
    body:move(self.node:getParent():toWorld(nx, ny))
  else
    self.node.posX, self.node.posY = nx, ny
  end
end

return Arrows
