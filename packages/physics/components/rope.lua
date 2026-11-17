-- The component type physics.rope: Box2D's rope joint. Its node's place and a point of the other body come no further
-- apart than its length, and may come closer, as a rope does.
local onlr = require("onlr")
local joint = require("physics.joint")

---@class physics.rope : onlr.Component
---@field other physics.body? the body that it joins to its own
---@field collide boolean
---@field joint love.RopeJoint?
local Rope = {}

Rope.otherAnchor = onlr.property.vector(0, 0, { description = "The point of the other body that it holds, in its node's space" })
Rope.length = onlr.property.number(0, { min = 0, description = "The longest it gets, in pixels: 0 is as far as they were when joined" })
joint.declare(Rope, "physics.rope")

function Rope:_make(a, b, x, y)
  local bx, by = self.other.node:toWorld(self.otherAnchor.x, self.otherAnchor.y)
  local length = self.length > 0 and self.length or math.sqrt((bx - x) ^ 2 + (by - y) ^ 2)
  return love.physics.newRopeJoint(a, b, x, y, bx, by, length, self.collide)
end

return Rope
