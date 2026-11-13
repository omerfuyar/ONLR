-- A type whose drawEditor fails: the node view marks its node, and the rest draws on (DESIGN 6.5).
local onlr = require("onlr")

---@class broken : onlr.Component
local Broken = {}

Broken.late = onlr.property.bool(false)

function Broken:drawEditor()
  love.graphics.setColor(1, 0, 0, 1)
  love.graphics.push()
  if self.late then
    -- In the node view, the functions that change the tree change nothing, and report an error.
    onlr.tree.newNode("Never")
  end
  error("it fails")
end

return Broken
