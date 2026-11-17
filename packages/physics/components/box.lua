-- The component type physics.box: a rectangle that collides, fixed to the nearest physics.body on its node or above it.
-- It turns and scales with its node, so a box on a node under the body may sit anywhere on it, at any angle.
local onlr = require("onlr")
local shape = require("physics.shape")

---@class physics.box : onlr.Component
---@field owner physics.body? the body that it is fixed to
---@field fixture love.Fixture?
local Box = {}

Box.width = onlr.property.number(32, { min = 0 })
Box.height = onlr.property.number(32, { min = 0 })
Box.center = onlr.property.vector(0, 0, { description = "The box's middle, from the node's place. A body turns around its node's place" })
shape.declare(Box, "physics.box")

-- Its four corners, in the body's space.
function Box:_outline(toBody)
  local cx, cy, w, h = self.center.x, self.center.y, self.width / 2, self.height / 2
  local points = {}
  for _, corner in ipairs({ { -w, -h }, { w, -h }, { w, h }, { -w, h } }) do
    local x, y = toBody(cx + corner[1], cy + corner[2])
    points[#points + 1] = x
    points[#points + 1] = y
  end
  return love.physics.newPolygonShape(points)
end

function Box:bounds()
  return self.center.x - self.width / 2, self.center.y - self.height / 2, self.width, self.height
end

function Box:drawEditor(chosen)
  love.graphics.setColor(1, 0.75, 0.3, chosen and 1 or 0.5)
  love.graphics.rectangle("line", self.center.x - self.width / 2, self.center.y - self.height / 2, self.width, self.height)
end

return Box
