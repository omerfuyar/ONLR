-- A group (DESIGN 5): drawTree draws its node and all under it, moved down, as many times as copies says.
local onlr = require("onlr")

---@class shift : onlr.Component
local Shift = {}

Shift.by = onlr.property.number(100)
Shift.copies = onlr.property.integer(1)

-- The engine calls it in place of drawing the group, and draw draws the group's nodes.
function Shift:drawTree(draw)
  love.graphics.push()
  for _ = 1, self.copies do
    love.graphics.translate(0, self.by)
    draw()
  end
  love.graphics.pop()
end

return Shift
