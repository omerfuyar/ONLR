-- The component type onlr.paint: draws its node's onlr.shape, filled or as an outline, in a colour (DESIGN 10).
-- Its properties' names are LÖVE's: mode is "fill" or "line".
local onlr = require("onlr")

---@class onlr.paint : onlr.Component
local Paint = {}

Paint.needs = { "onlr.shape" }

Paint.mode = onlr.property.choice("fill", { choices = { "fill", "line" }, description = "A line shape is drawn as a line in either" })
Paint.lineWidth = onlr.property.number(1, { min = 0, description = "The width of a line and of an outline, as love.graphics.setLineWidth" })
Paint.color = onlr.property.color({ 1, 1, 1, 1 })

-- Draws the shape, and sets the colour and the line width back.
function Paint:draw()
  local r, g, b, a = love.graphics.getColor()
  local lineWidth = love.graphics.getLineWidth()
  love.graphics.setColor(self.color)
  love.graphics.setLineWidth(self.lineWidth)
  self.node.components.onlr.shape:drawShape(self.mode)
  love.graphics.setLineWidth(lineWidth)
  love.graphics.setColor(r, g, b, a)
end

Paint.drawEditor = Paint.draw

return Paint
