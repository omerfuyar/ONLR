-- Draws a square through its shader, and does not set the shader back: the engine does (DESIGN 6.3).
local onlr = require("onlr")

---@class forget : onlr.Component
local Forget = {}

Forget.shader = onlr.property.shader()

function Forget:draw()
  love.graphics.setShader(self.shader)
  self.shader:send("amount", 1)
  self.shader:send("tint", { 0, 0, 1, 1 })
  love.graphics.rectangle("fill", 0, 0, 8, 8)
end

return Forget
