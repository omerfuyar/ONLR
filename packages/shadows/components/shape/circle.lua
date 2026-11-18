-- The component type shadows.shape.circle: a circle that blocks light, around its node's place, as onlr.shape's circle
-- is. Its radius grows with its node's scale across.
local onlr = require("onlr")
local shape = require("shadows.shape")
local CircleShadow = require("shadows.ShadowShapes.CircleShadow")

---@class shadows.shape.circle : onlr.Component
---@field body table? Shädows' Body, which the circle is at
local Circle = {}

Circle.radius = onlr.property.number(16, { min = 0 })

-- Its middle, and a point on its edge across, so a scale of the node reaches the radius.
function Circle:_points()
  return { { 0, 0 }, { self.radius, 0 } }
end

function Circle:_make(body)
  return CircleShadow:new(body, 0, 0, 1)
end

function Circle:_place(circle, points)
  local x, y, ex, ey = points[1], points[2], points[3], points[4]
  self.body:SetPosition(x, y)
  circle:SetRadius(math.sqrt((ex - x) ^ 2 + (ey - y) ^ 2))
end

function Circle:drawEditor(chosen)
  love.graphics.setColor(0.2, 0.2, 0.3, chosen and 1 or 0.7)
  love.graphics.setLineWidth(2)
  love.graphics.circle("line", 0, 0, self.radius)
end

function Circle:bounds()
  return -self.radius, -self.radius, self.radius * 2, self.radius * 2
end

shape.declare(Circle, "shadows.shape.circle")

return Circle
