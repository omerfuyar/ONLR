-- The component type onlr.shape: a rectangle, a circle, a line or a polygon.
-- In this prototype, only its properties. Their names are LÖVE's: mode is "fill" or "line".
local onlr = require("onlr")

---@class onlr.shape : onlr.Component
local Shape = {}

Shape.kind = onlr.property.choice("rectangle", { choices = { "rectangle", "circle", "line", "polygon" } })
Shape.mode = onlr.property.choice("fill", { choices = { "fill", "line" }, description = "A line has no mode" })
-- A rectangle's size, from the node's place.
Shape.width = onlr.property.number(32, { min = 0 })
Shape.height = onlr.property.number(32, { min = 0 })
-- A circle's, around the node's place.
Shape.radius = onlr.property.number(16, { min = 0 })
-- A line's points, or a polygon's corners, in the node's space.
Shape.points = onlr.property.list(onlr.property.vector())
Shape.lineWidth = onlr.property.number(1, { min = 0, description = "As love.graphics.setLineWidth" })
Shape.color = onlr.property.color({ 1, 1, 1, 1 })

-- Draws the shape, and sets the colour and the line width back.
function Shape:draw() end
Shape.drawEditor = Shape.draw
function Shape:bounds() end

return Shape
