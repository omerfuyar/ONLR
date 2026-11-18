-- The component type physics.shape.polygon: a convex polygon that collides, fixed to the nearest physics.body on its node or
-- above it. Box2D takes 3 to 8 corners that make a convex polygon; a polygon of fewer corners, as a new one is, collides
-- with nothing until the user adds them, and any other is an error that names the node.
local onlr = require("onlr")
local shape = require("physics.shape")

---@class physics.shape.polygon : onlr.Component
---@field owner physics.body? the body that it is fixed to
---@field fixture love.Fixture?
local Polygon = {}

Polygon.points = onlr.property.list(onlr.property.vector(), { description = "Its corners in the node's space: 3 to 8, making a convex polygon" })
shape.declare(Polygon, "physics.shape.polygon")

-- Its corners in the body's space; nil, so no fixture, while it has fewer than 3.
function Polygon:_outline(toBody)
  if #self.points < 3 then
    return nil
  end
  if #self.points > 8 then
    error(("physics.shape.polygon on %s has %d corners, and Box2D takes at most 8"):format(self.node.name, #self.points), 0)
  end
  local flat = {}
  for _, point in ipairs(self.points) do
    local x, y = toBody(point.x, point.y)
    flat[#flat + 1] = x
    flat[#flat + 1] = y
  end
  local ok, made = pcall(love.physics.newPolygonShape, flat)
  if not ok then
    error(("physics.shape.polygon on %s is not a convex polygon that Box2D takes: %s"):format(self.node.name, tostring(made)), 0)
  end
  return made
end

function Polygon:bounds()
  if #self.points == 0 then
    return 0, 0, 0, 0
  end
  local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
  for _, point in ipairs(self.points) do
    x0, y0 = math.min(x0, point.x), math.min(y0, point.y)
    x1, y1 = math.max(x1, point.x), math.max(y1, point.y)
  end
  return x0, y0, x1 - x0, y1 - y0
end

function Polygon:drawEditor(chosen)
  if #self.points < 2 then
    return
  end
  local flat = {}
  for _, point in ipairs(self.points) do
    flat[#flat + 1] = point.x
    flat[#flat + 1] = point.y
  end
  love.graphics.setColor(1, 0.75, 0.3, chosen and 1 or 0.5)
  if #self.points >= 3 then
    love.graphics.polygon("line", flat)
  else
    love.graphics.line(flat)
  end
end

return Polygon
