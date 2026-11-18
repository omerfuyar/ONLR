-- Moves its node from side to side: a small script on each of thousands of nodes.
local onlr = require("onlr")

---@class mover : onlr.Component
local Mover = {}

Mover.speed = onlr.property.number(20)

function Mover:load()
  self.time = 0
  self.startX = self.node.posX
end

function Mover:update(dt)
  self.time = self.time + dt
  self.node.posX = self.startX + math.sin(self.time * self.speed * 0.1) * 4
end

return Mover
