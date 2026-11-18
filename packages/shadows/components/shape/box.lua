-- The component type shadows.shape.box: a rectangle that blocks light, from its node's place, as onlr.shape's
-- rectangle is. It turns and scales with its node.
local onlr = require("onlr")
local shape = require("shadows.shape")
local PolygonShadow = require("shadows.ShadowShapes.PolygonShadow")

---@class shadows.shape.box : onlr.Component
local Box = {}

Box.width = onlr.property.number(32, { min = 0 })
Box.height = onlr.property.number(32, { min = 0 })

function Box:_points()
  local w, h = self.width, self.height
  return { { 0, 0 }, { w, 0 }, { w, h }, { 0, h } }
end

function Box:_make(body)
  return PolygonShadow:new(body, 0, 0, 1, 0, 1, 1, 0, 1)
end

function Box:_place(polygon, points)
  polygon:SetVertices(unpack(points))
end

function Box:drawEditor(chosen)
  love.graphics.setColor(0.2, 0.2, 0.3, chosen and 1 or 0.7)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", 0, 0, self.width, self.height)
end

function Box:bounds()
  return 0, 0, self.width, self.height
end

shape.declare(Box, "shadows.shape.box")

return Box
