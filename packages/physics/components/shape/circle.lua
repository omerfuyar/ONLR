-- The component type physics.shape.circle: a circle that collides, fixed to the nearest physics.body on its node or above it.
local onlr = require("onlr")
local shape = require("physics.shape")

---@class physics.shape.circle : onlr.Component
---@field owner physics.body? the body that it is fixed to
---@field fixture love.Fixture?
local Circle = {}

Circle.radius = onlr.property.number(16, { min = 0 })
Circle.center = onlr.property.vector(0, 0, { description = "The circle's middle, from the node's place" })
shape.declare(Circle, "physics.shape.circle")

-- Its middle in the body's space, and its radius as large as its node is in the world.
function Circle:_outline(toBody)
  local x, y = toBody(self.center.x, self.center.y)
  return love.physics.newCircleShape(x, y, self.radius * shape.scale(self.node))
end

function Circle:bounds()
  return self.center.x - self.radius, self.center.y - self.radius, self.radius * 2, self.radius * 2
end

function Circle:drawEditor(chosen)
  love.graphics.setColor(1, 0.75, 0.3, chosen and 1 or 0.5)
  love.graphics.circle("line", self.center.x, self.center.y, self.radius)
  love.graphics.line(self.center.x, self.center.y, self.center.x + self.radius, self.center.y)
end

return Circle
