-- The component type physics.joint.distance: Box2D's distance joint. Its node's place and a point of the other body stay as far
-- apart as they were when joined, as a stick does; with a frequency, they spring towards that distance.
local onlr = require("onlr")
local joint = require("physics.joint")

---@class physics.joint.distance : onlr.Component
---@field other physics.body? the body that it joins to its own
---@field collide boolean
---@field joint love.DistanceJoint?
local Distance = {}

Distance.otherAnchor = onlr.property.vector(0, 0, { description = "The point of the other body that it holds, in its node's space" })
Distance.frequency = onlr.property.number(0, { min = 0, description = "How fast it springs, in times a second: 0 is a stick" })
Distance.damping = onlr.property.number(0, { min = 0, description = "How fast the spring calms down: 1 does not swing past" })
joint.declare(Distance, "physics.joint.distance")

function Distance:_make(a, b, x, y)
  local bx, by = self.other.node:toWorld(self.otherAnchor.x, self.otherAnchor.y)
  local j = love.physics.newDistanceJoint(a, b, x, y, bx, by, self.collide)
  j:setFrequency(self.frequency)
  j:setDampingRatio(self.damping)
  return j
end

return Distance
