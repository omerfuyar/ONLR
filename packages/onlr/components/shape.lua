-- The component type onlr.shape: a node's outline, a rectangle, a circle, a polygon or a line (DESIGN 10). It draws nothing in the
-- game: onlr.paint draws it, physics.fixture collides with it, shadows.caster casts a shadow of it, and bump.body takes it as its box.
-- So the node's look, its collision and its shadow are one outline, which the user sizes once.
local onlr = require("onlr")

---The shape in its node's space, as LÖVE's functions take it.
---@class onlr.Outline
---@field kind "rectangle"|"circle"|"polygon"|"line"
---@field x number a rectangle's left, or a circle's middle
---@field y number a rectangle's top, or a circle's middle
---@field width number a rectangle's
---@field height number a rectangle's
---@field radius number a circle's
---@field points number[] a polygon's corners or a line's points, x, y, x, y, as love.graphics.polygon takes them

---@class onlr.shape : onlr.Component
---@field private _flat number[]? the points as one list, x, y, x, y, which drawShape fills again at each draw
local Shape = {}

Shape.kind = onlr.property.choice("rectangle", { choices = { "rectangle", "circle", "polygon", "line" } })
Shape.width = onlr.property.number(32, { min = 0, when = { kind = "rectangle" } })
Shape.height = onlr.property.number(32, { min = 0, when = { kind = "rectangle" } })
Shape.radius = onlr.property.number(16, { min = 0, when = { kind = "circle" } })
Shape.points = onlr.property.list(onlr.property.vector(), {
  when = { kind = { "polygon", "line" } },
  handles = true,
  description = "A polygon's corners, or a line's points, in the node's space. The Shape tool drags them",
})
Shape.origin = onlr.property.vector(0, 0, {
  when = { kind = { "rectangle", "circle" } },
  description = "The point of the shape that is at the node's place: a rectangle's from its top left, a circle's from its middle",
})

---The shape in its node's space: the origin taken off a rectangle and a circle.
---@return onlr.Outline
function Shape:outline()
  local ox, oy = self.origin.x, self.origin.y
  local points = {}
  for _, point in ipairs(self.points) do
    points[#points + 1] = point.x
    points[#points + 1] = point.y
  end
  return {
    kind = self.kind, x = -ox, y = -oy, width = self.width, height = self.height, radius = self.radius, points = points,
  }
end

---Draws the shape with LÖVE in the colour and the line width that are set: filled, or as an outline. A line is drawn as a line,
---and a polygon of fewer than 3 corners, or a line of fewer than 2 points, draws nothing.
---It makes no garbage: a rectangle and a circle draw from the values themselves, and the points go into one list that the
---shape keeps and fills again at each draw, as `outline` would give them.
---@param mode "fill"|"line"
function Shape:drawShape(mode)
  local kind = self.kind
  if kind == "rectangle" then
    love.graphics.rectangle(mode, -self.origin.x, -self.origin.y, self.width, self.height)
    return
  elseif kind == "circle" then
    love.graphics.circle(mode, -self.origin.x, -self.origin.y, self.radius)
    return
  end
  local points = self.points
  local count = #points * 2
  if kind == "line" and count >= 4 or kind == "polygon" and count >= 6 then
    local flat = self._flat or {}
    self._flat = flat
    for i, point in ipairs(points) do
      flat[i * 2 - 1], flat[i * 2] = point.x, point.y
    end
    for i = #flat, count + 1, -1 do
      flat[i] = nil
    end
    if kind == "line" then
      love.graphics.line(flat)
    else
      love.graphics.polygon(mode, flat)
    end
  end
end

-- In the node view, the outline shows as a thin green line of one pixel at any zoom, as a collider's does: always on a node that
-- does not paint it, and when chosen on one that does.
function Shape:drawEditor(chosen)
  if self.node.components.onlr.paint and not chosen then
    return
  end
  local x0, y0 = love.graphics.transformPoint(0, 0)
  local x1, y1 = love.graphics.transformPoint(1, 0)
  local scale = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
  if scale <= 0 then
    return
  end
  local r, g, b, a = love.graphics.getColor()
  local lineWidth = love.graphics.getLineWidth()
  love.graphics.setColor(0.45, 0.85, 0.5, chosen and 1 or 0.7)
  love.graphics.setLineWidth(1 / scale)
  self:drawShape("line")
  love.graphics.setLineWidth(lineWidth)
  love.graphics.setColor(r, g, b, a)
end

-- The rectangle around the shape.
function Shape:bounds()
  local o = self:outline()
  if o.kind == "rectangle" then
    return o.x, o.y, o.width, o.height
  elseif o.kind == "circle" then
    return o.x - o.radius, o.y - o.radius, o.radius * 2, o.radius * 2
  end
  local p = o.points
  if #p == 0 then
    return
  end
  local x1, y1, x2, y2 = p[1], p[2], p[1], p[2]
  for i = 1, #p, 2 do
    x1, y1 = math.min(x1, p[i]), math.min(y1, p[i + 1])
    x2, y2 = math.max(x2, p[i]), math.max(y2, p[i + 1])
  end
  return x1, y1, x2 - x1, y2 - y1
end

return Shape
