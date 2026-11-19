-- The component type physics.joint: one of Box2D's joints, by its kind (DESIGN 11.4). It is on its body's node or on a node
-- under it, and holds that body to the body that other names; the joint's node is where it holds them, such as a hinge's pin.
-- It is made when both bodies run, and ends when either stops, as Box2D ends it.
-- - hinge, the revolute joint: the bodies turn around one pin, as a door, a wheel or a pendulum; it may limit the angle and
--   turn by a motor.
-- - weld: the bodies hold together as one, such as a part that breaks off later when a script ends the weld.
-- - distance: its node's place and a point of the other body stay as far apart as they were, as a stick; with a frequency,
--   they spring towards that distance.
-- - rope: its node's place and a point of the other body come no further apart than its length, and may come closer.
local onlr = require("onlr")
local find = require("physics.find")

---@class physics.joint : onlr.Component
---@field owner physics.body? the body of its node or above it
---@field joint love.Joint?
local Joint = {}

Joint.kind = onlr.property.choice("hinge", { choices = { "hinge", "weld", "distance", "rope" } })
Joint.other = onlr.property.component("physics.body", { description = "The body that it joins to its own" })
Joint.collide = onlr.property.bool(false, { description = "Its two bodies still collide with each other" })
Joint.otherAnchor = onlr.property.vector(0, 0, {
  when = { kind = { "distance", "rope" } },
  description = "The point of the other body that it holds, in its node's space",
})
Joint.limit = onlr.property.bool(false, { when = { kind = "hinge" }, description = "The angle between the bodies stays between lower and upper" })
Joint.lower = onlr.property.number(-math.pi / 4, { when = { kind = "hinge" }, description = "The least angle, in radians, from where they were when joined" })
Joint.upper = onlr.property.number(math.pi / 4, { when = { kind = "hinge" }, description = "The greatest angle, in radians" })
Joint.motor = onlr.property.bool(false, { when = { kind = "hinge" }, description = "A motor turns the bodies" })
Joint.motorSpeed = onlr.property.number(0, { when = { kind = "hinge" }, description = "Radians a second" })
Joint.motorTorque = onlr.property.number(1000, { min = 0, when = { kind = "hinge" }, description = "How hard the motor turns" })
Joint.frequency = onlr.property.number(0, { min = 0, when = { kind = "distance" }, description = "How fast it springs, in times a second: 0 is a stick" })
Joint.damping = onlr.property.number(0, { min = 0, when = { kind = "distance" }, description = "How fast the spring calms down: 1 does not swing past" })
Joint.length = onlr.property.number(0, { min = 0, when = { kind = "rope" }, description = "The longest it gets, in pixels: 0 is as far as they were when joined" })

function Joint:enable()
  self.owner = find.bodyOf(self.node)
  if not self.owner then
    error(("physics.joint on %s has no physics.body on its node or above it"):format(self.node.name), 0)
  end
  if not self.other or self.other == self.owner then
    error(("physics.joint on %s names no other body to join"):format(self.node.name), 0)
  end
  self.owner:_hold(self)
  self.other:_hold(self)
  self:_join()
end

function Joint:disable()
  self:_unjoin()
  if self.owner then
    self.owner:_release(self)
    self.other:_release(self)
    self.owner = nil
  end
end

---The joint of love.physics, for all that LÖVE's own functions do; nil while either body does not run.
---@return love.Joint?
function Joint:get()
  return self.joint
end

-- Box2D's joint of the kind, between the two bodies, held at x, y in the world.
function Joint:_make(a, b, x, y)
  local kind = self.kind
  if kind == "weld" then
    return love.physics.newWeldJoint(a, b, x, y, self.collide)
  elseif kind == "hinge" then
    local j = love.physics.newRevoluteJoint(a, b, x, y, self.collide)
    j:setLimitsEnabled(self.limit)
    j:setLimits(self.lower, self.upper)
    j:setMotorEnabled(self.motor)
    j:setMotorSpeed(self.motorSpeed)
    j:setMaxMotorTorque(self.motorTorque)
    return j
  end
  local bx, by = self.other.node:toWorld(self.otherAnchor.x, self.otherAnchor.y)
  if kind == "distance" then
    local j = love.physics.newDistanceJoint(a, b, x, y, bx, by, self.collide)
    j:setFrequency(self.frequency)
    j:setDampingRatio(self.damping)
    return j
  end
  local length = self.length > 0 and self.length or math.sqrt((bx - x) ^ 2 + (by - y) ^ 2)
  return love.physics.newRopeJoint(a, b, x, y, bx, by, length, self.collide)
end

-- Not called by scripts: the bodies call them when they start and stop.
function Joint:_join()
  if self.joint or not (self.owner and self.owner.b and self.other.b) then
    return
  end
  local ax, ay = self.node:toWorld(0, 0)
  self.joint = self:_make(self.owner.b, self.other.b, ax, ay)
end

function Joint:_unjoin()
  if self.joint and not self.joint:isDestroyed() then
    self.joint:destroy()
  end
  self.joint = nil
end

-- In the node view: a ring at the joint's place, and a line to the other body's node, or to its anchor.
function Joint:drawEditor(chosen)
  love.graphics.setColor(0.6, 0.8, 1, chosen and 1 or 0.5)
  love.graphics.circle("line", 0, 0, 4)
  local other = self.other and self.other.node
  if other then
    local anchor = (self.kind == "distance" or self.kind == "rope") and self.otherAnchor or { x = 0, y = 0 }
    local x, y = self.node:toLocal(other:toWorld(anchor.x, anchor.y))
    love.graphics.line(0, 0, x, y)
  end
end

function Joint:bounds()
  return -4, -4, 8, 8
end

return Joint
