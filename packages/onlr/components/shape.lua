-- The component type onlr.shape: a rectangle, a circle, a line or a polygon.
-- Its properties' names are LÖVE's: mode is "fill" or "line".
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

-- The points as LÖVE takes them: x, y, x, y.
local function flat(points)
  local list = {}
  for _, point in ipairs(points) do
    list[#list + 1] = point.x
    list[#list + 1] = point.y
  end
  return list
end

-- Draws the shape, and sets the colour and the line width back.
function Shape:draw()
  local r, g, b, a = love.graphics.getColor()
  local lineWidth = love.graphics.getLineWidth()
  love.graphics.setColor(self.color)
  love.graphics.setLineWidth(self.lineWidth)
  local kind = self.kind
  if kind == "rectangle" then
    love.graphics.rectangle(self.mode, 0, 0, self.width, self.height)
  elseif kind == "circle" then
    love.graphics.circle(self.mode, 0, 0, self.radius)
  elseif kind == "line" and #self.points >= 2 then
    love.graphics.line(flat(self.points))
  elseif kind == "polygon" and #self.points >= 3 then
    love.graphics.polygon(self.mode, flat(self.points))
  end
  love.graphics.setLineWidth(lineWidth)
  love.graphics.setColor(r, g, b, a)
end

Shape.drawEditor = Shape.draw

-- The rectangle around the shape.
function Shape:bounds()
  local kind = self.kind
  if kind == "rectangle" then
    return 0, 0, self.width, self.height
  elseif kind == "circle" then
    return -self.radius, -self.radius, self.radius * 2, self.radius * 2
  end
  local points = self.points
  if #points == 0 then
    return
  end
  local x1, y1, x2, y2 = points[1].x, points[1].y, points[1].x, points[1].y
  for _, point in ipairs(points) do
    x1, y1 = math.min(x1, point.x), math.min(y1, point.y)
    x2, y2 = math.max(x2, point.x), math.max(y2, point.y)
  end
  return x1, y1, x2 - x1, y2 - y1
end

return Shape
