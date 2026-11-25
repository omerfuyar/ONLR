-- Turns its node: its children turn and move with it, as a node's place holds for all under it.
local onlr = require("onlr")

---@class spin : onlr.Component
local Spin = {}

Spin.speed = onlr.property.number(1, { angle = true, description = "Degrees a second" })

function Spin:update(dt)
  self.node.rot = self.node.rot + self.speed * dt
end

return Spin
