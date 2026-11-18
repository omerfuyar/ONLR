-- A script with a property of most kinds, to see in the inspector: it draws a row of circles from them.
local onlr = require("onlr")

---@class showcase : onlr.Component
local Showcase = {}

Showcase.count = onlr.property.integer(5, { min = 1, max = 12, heading = "Circles", description = "How many: a slider, since it has a least and a most" })
Showcase.radius = onlr.property.number(10, { min = 2, max = 30 })
Showcase.gap = onlr.property.vector(30, 0, { description = "From one circle to the next" })
Showcase.color = onlr.property.color({ 0.95, 0.6, 0.2, 1 })
Showcase.mode = onlr.property.choice("fill", { choices = { "fill", "line" } })
Showcase.label = onlr.property.string("Change me in the inspector", { heading = "Text" })
Showcase.colors = onlr.property.list(onlr.property.color(), { description = "Each circle takes the next colour, when the list has any" })
Showcase.outline = onlr.property.group({
  show = onlr.property.bool(true),
  width = onlr.property.number(2, { min = 1, max = 8 }),
}, { label = "Outline", description = "A group: properties under one heading" })
Showcase.follow = onlr.property.node({ description = "A node of the same file, which the row points at" })

function Showcase:draw()
  for i = 1, self.count do
    local x, y = (i - 1) * self.gap.x, (i - 1) * self.gap.y
    love.graphics.setColor(#self.colors > 0 and self.colors[(i - 1) % #self.colors + 1] or self.color)
    love.graphics.circle(self.mode, x, y, self.radius)
    if self.outline.show then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setLineWidth(self.outline.width)
      love.graphics.circle("line", x, y, self.radius)
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(self.label, 0, self.radius + 8)
  if self.follow and not self.follow:isDestroyed() then
    local fx, fy = self.node:toLocal(self.follow:toWorld(0, 0))
    love.graphics.line(0, 0, fx, fy)
  end
end

Showcase.drawEditor = Showcase.draw

function Showcase:bounds()
  return -self.radius, -self.radius, (self.count - 1) * self.gap.x + 2 * self.radius, (self.count - 1) * self.gap.y + 2 * self.radius + 24
end

return Showcase
