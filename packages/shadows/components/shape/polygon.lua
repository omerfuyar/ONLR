-- The component type shadows.shape.polygon: a convex polygon that blocks light, of corners in its node's space, as
-- onlr.shape's polygon is.
local onlr = require("onlr")
local shape = require("shadows.shape")
local PolygonShadow = require("shadows.ShadowShapes.PolygonShadow")

---@class shadows.shape.polygon : onlr.Component
local Polygon = {}

Polygon.points = onlr.property.list(onlr.property.vector(0, 0), {
  description = "Its corners, at least 3, around a convex shape, in the node's space",
})

function Polygon:_points()
  if #self.points < 3 then
    error(("shadows.shape.polygon on %s: a polygon has at least 3 corners"):format(self.node.name), 0)
  end
  local points = {}
  for i, p in ipairs(self.points) do
    points[i] = { p.x, p.y }
  end
  return points
end

function Polygon:_make(body)
  return PolygonShadow:new(body, 0, 0, 1, 0, 1, 1)
end

function Polygon:_place(polygon, points)
  polygon:SetVertices(unpack(points))
end

function Polygon:drawEditor(chosen)
  if #self.points < 3 then
    return
  end
  local flat = {}
  for _, p in ipairs(self.points) do
    flat[#flat + 1] = p.x
    flat[#flat + 1] = p.y
  end
  love.graphics.setColor(0.2, 0.2, 0.3, chosen and 1 or 0.7)
  love.graphics.setLineWidth(2)
  love.graphics.polygon("line", flat)
end

function Polygon:bounds()
  local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
  for _, p in ipairs(self.points) do
    x1, y1, x2, y2 = math.min(x1, p.x), math.min(y1, p.y), math.max(x2, p.x), math.max(y2, p.y)
  end
  if x1 > x2 then
    return
  end
  return x1, y1, x2 - x1, y2 - y1
end

shape.declare(Polygon, "shadows.shape.polygon")

return Polygon
