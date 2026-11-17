-- The component type physics.hinge: Box2D's revolute joint. The two bodies turn around one pin, at the hinge's node,
-- as a door on its hinge, a wheel on its axle or a pendulum on its nail. It may limit the angle and turn by a motor.
local onlr = require("onlr")
local joint = require("physics.joint")

---@class physics.hinge : onlr.Component
---@field other physics.body? the body that it joins to its own
---@field collide boolean
---@field joint love.RevoluteJoint?
local Hinge = {}

Hinge.limit = onlr.property.bool(false, { description = "The angle between the bodies stays between lower and upper" })
Hinge.lower = onlr.property.number(-math.pi / 4, { description = "The least angle, in radians, from where they were when joined" })
Hinge.upper = onlr.property.number(math.pi / 4, { description = "The greatest angle, in radians" })
Hinge.motor = onlr.property.bool(false, { description = "A motor turns the bodies" })
Hinge.motorSpeed = onlr.property.number(0, { description = "Radians a second" })
Hinge.motorTorque = onlr.property.number(1000, { min = 0, description = "How hard the motor turns" })
joint.declare(Hinge, "physics.hinge")

function Hinge:_make(a, b, x, y)
  local j = love.physics.newRevoluteJoint(a, b, x, y, self.collide)
  j:setLimitsEnabled(self.limit)
  j:setLimits(self.lower, self.upper)
  j:setMotorEnabled(self.motor)
  j:setMotorSpeed(self.motorSpeed)
  j:setMaxMotorTorque(self.motorTorque)
  return j
end

return Hinge
