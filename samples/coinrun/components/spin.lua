-- A script that one coin of the level has and the others lack: the instance adds it (nodes/level.lua).
local onlr = require("onlr")

---@class spin : onlr.Component
local Spin = {}

Spin.speed = onlr.property.number(1, { description = "Turns a second" })

function Spin:update(dt)
  self.node.rot = self.node.rot + self.speed * 2 * math.pi * dt
end

return Spin
