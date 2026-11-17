-- The component type physics.weld: Box2D's weld joint. The two bodies hold together as one, at the weld's node,
-- such as a part that breaks off later when a script ends the weld.
local joint = require("physics.joint")

---@class physics.weld : onlr.Component
---@field other physics.body? the body that it joins to its own
---@field collide boolean
---@field joint love.WeldJoint?
local Weld = {}

joint.declare(Weld, "physics.weld")

function Weld:_make(a, b, x, y)
  return love.physics.newWeldJoint(a, b, x, y, self.collide)
end

return Weld
