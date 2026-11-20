-- The component type physics.joint: one of Box2D's joints, by its kind (DESIGN 11.4). It is on its body's node or on a node
-- under it, and holds that body to the body that other names; the joint's node is where it holds them, such as a hinge's pin.
-- It is made when both bodies run, and ends when either stops, as Box2D ends it.
-- - hinge, the revolute joint: the bodies turn around one pin, as a door, a wheel or a pendulum; it may limit the angle and
--   turn by a motor.
-- - weld: the bodies hold together as one, such as a part that breaks off later when a script ends the weld.
-- - distance: its node's place and a point of the other body stay as far apart as they were, as a stick; with a frequency,
--   they spring towards that distance.
-- - rope: its node's place and a point of the other body come no further apart than its length, and may come closer.
-- - prismatic: the bodies slide along an axis and do not turn, as a lift or a piston; it may limit the slide and move by a motor.
-- - wheel: the other body turns freely on its node's place, which slides along an axis on a spring, as a car's wheel.
-- - friction: the bodies slow each other's sliding and turning, as a top-down game's floor slows what is on it.
-- - motor: the other body is pushed towards where it was when joined, by a force and a torque, as a platform that a script
--   moves with setLinearOffset.
-- - pulley: its node's place and a point of the other body hang from two points of the world, by one rope, as a lift and its
--   weight.
-- Before each step, a joint whose node moved under its body, or whose kind, bodies or anchors changed, is made again; a value
-- that tunes it, such as a motor's speed, is set (DESIGN 11.4).
local onlr = require("onlr")
local find = require("physics.find")

---@class physics.joint : onlr.Component
---@field owner physics.body? the body of its node or above it
---@field joint love.Joint?
---@field private key string? what it was made from
---@field private applied table<string, any> the values that tune it, as they were last set
local Joint = {}

Joint.kind = onlr.property.choice("hinge", { choices = { "hinge", "weld", "distance", "rope", "prismatic", "wheel", "friction", "motor", "pulley" } })
Joint.other = onlr.property.component("physics.body", { description = "The body that it joins to its own" })
Joint.collide = onlr.property.bool(false, { description = "Its two bodies still collide with each other" })
Joint.otherAnchor = onlr.property.vector(0, 0, {
  when = { kind = { "distance", "rope", "pulley" } },
  description = "The point of the other body that it holds, in the other body's node's space",
})
Joint.axis = onlr.property.vector(1, 0, { when = { kind = { "prismatic", "wheel" } }, description = "The way that it slides, in its node's space" })
Joint.limit = onlr.property.bool(false, { when = { kind = { "hinge", "prismatic" } }, description = "The angle between the bodies, or the slide, stays between lower and upper" })
Joint.lower = onlr.property.number(-math.pi / 4, { when = { kind = { "hinge", "prismatic" } }, description = "The least angle, in radians, or slide, in pixels, from where they were when joined" })
Joint.upper = onlr.property.number(math.pi / 4, { when = { kind = { "hinge", "prismatic" } }, description = "The greatest angle, in radians, or slide, in pixels" })
Joint.motor = onlr.property.bool(false, { when = { kind = { "hinge", "prismatic", "wheel" } }, description = "A motor turns or slides the bodies" })
Joint.motorSpeed = onlr.property.number(0, { when = { kind = { "hinge", "prismatic", "wheel" } }, description = "Radians a second, or pixels a second for a prismatic joint" })
Joint.motorTorque = onlr.property.number(1000, { min = 0, when = { kind = { "hinge", "wheel" } }, description = "How hard the motor turns" })
Joint.motorForce = onlr.property.number(1000, { min = 0, when = { kind = "prismatic" }, description = "How hard the motor slides" })
Joint.frequency = onlr.property.number(0, { min = 0, when = { kind = { "distance", "wheel" } }, description = "How fast it springs, in times a second: 0 is a stick, and a wheel's spring is stiff" })
Joint.damping = onlr.property.number(0, { min = 0, when = { kind = { "distance", "wheel" } }, description = "How fast the spring calms down: 1 does not swing past" })
Joint.length = onlr.property.number(0, { min = 0, when = { kind = "rope" }, description = "The longest it gets, in pixels: 0 is as far as they were when joined" })
Joint.maxForce = onlr.property.number(100, { min = 0, when = { kind = { "friction", "motor" } }, description = "The most force with which it slows or pushes" })
Joint.maxTorque = onlr.property.number(100, { min = 0, when = { kind = { "friction", "motor" } }, description = "The most torque with which it slows or turns" })
Joint.correction = onlr.property.number(0.3, { min = 0, max = 1, when = { kind = "motor" }, description = "How much of the way back it pushes in each step" })
Joint.groundAnchor = onlr.property.vector(0, -100, { when = { kind = "pulley" }, description = "Where its own side of the rope hangs from, in its node's space" })
Joint.otherGroundAnchor = onlr.property.vector(0, -100, { when = { kind = "pulley" }, description = "Where the other side hangs from, in the other body's node's space" })
Joint.ratio = onlr.property.number(1, { min = 0.01, when = { kind = "pulley" }, description = "How much more its own side moves than the other: 2 is a block and tackle" })

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

-- A direction of its node's space, in the world.
local function direction(node, v)
  local x0, y0 = node:toWorld(0, 0)
  local x1, y1 = node:toWorld(v.x, v.y)
  return x1 - x0, y1 - y0
end

-- Box2D's joint of the kind, between the two bodies, held at x, y in the world.
function Joint:_make(a, b, x, y)
  local kind, other = self.kind, self.other.node
  if kind == "weld" then
    return love.physics.newWeldJoint(a, b, x, y, self.collide)
  elseif kind == "hinge" then
    return love.physics.newRevoluteJoint(a, b, x, y, self.collide)
  elseif kind == "prismatic" then
    local ax, ay = direction(self.node, self.axis)
    return love.physics.newPrismaticJoint(a, b, x, y, ax, ay, self.collide)
  elseif kind == "wheel" then
    local ax, ay = direction(self.node, self.axis)
    return love.physics.newWheelJoint(a, b, x, y, ax, ay, self.collide)
  elseif kind == "friction" then
    return love.physics.newFrictionJoint(a, b, x, y, self.collide)
  elseif kind == "motor" then
    return love.physics.newMotorJoint(a, b, self.correction, self.collide)
  end
  local bx, by = other:toWorld(self.otherAnchor.x, self.otherAnchor.y)
  if kind == "distance" then
    return love.physics.newDistanceJoint(a, b, x, y, bx, by, self.collide)
  elseif kind == "pulley" then
    local gx, gy = self.node:toWorld(self.groundAnchor.x, self.groundAnchor.y)
    local hx, hy = other:toWorld(self.otherGroundAnchor.x, self.otherGroundAnchor.y)
    return love.physics.newPulleyJoint(a, b, gx, gy, hx, hy, x, y, bx, by, self.ratio, self.collide)
  end
  local length = self.length > 0 and self.length or math.sqrt((bx - x) ^ 2 + (by - y) ^ 2)
  return love.physics.newRopeJoint(a, b, x, y, bx, by, length, self.collide)
end

-- The values that tune a joint of each kind, each with its setter: a script changes them as fields, and they are set before the
-- next step, without making the joint again.
local TUNING = {
  hinge = {
    limit = function(j, v) j:setLimitsEnabled(v) end,
    lower = function(j, _, c) j:setLimits(c.lower, c.upper) end,
    upper = function(j, _, c) j:setLimits(c.lower, c.upper) end,
    motor = function(j, v) j:setMotorEnabled(v) end,
    motorSpeed = function(j, v) j:setMotorSpeed(v) end,
    motorTorque = function(j, v) j:setMaxMotorTorque(v) end,
  },
  prismatic = {
    limit = function(j, v) j:setLimitsEnabled(v) end,
    lower = function(j, _, c) j:setLimits(c.lower, c.upper) end,
    upper = function(j, _, c) j:setLimits(c.lower, c.upper) end,
    motor = function(j, v) j:setMotorEnabled(v) end,
    motorSpeed = function(j, v) j:setMotorSpeed(v) end,
    motorForce = function(j, v) j:setMaxMotorForce(v) end,
  },
  wheel = {
    frequency = function(j, v) j:setSpringFrequency(v) end,
    damping = function(j, v) j:setSpringDampingRatio(v) end,
    motor = function(j, v) j:setMotorEnabled(v) end,
    motorSpeed = function(j, v) j:setMotorSpeed(v) end,
    motorTorque = function(j, v) j:setMaxMotorTorque(v) end,
  },
  distance = {
    frequency = function(j, v) j:setFrequency(v) end,
    damping = function(j, v) j:setDampingRatio(v) end,
  },
  rope = {
    length = function(j, v)
      if v > 0 then
        j:setMaxLength(v)
      end
    end,
  },
  friction = {
    maxForce = function(j, v) j:setMaxForce(v) end,
    maxTorque = function(j, v) j:setMaxTorque(v) end,
  },
  motor = {
    maxForce = function(j, v) j:setMaxForce(v) end,
    maxTorque = function(j, v) j:setMaxTorque(v) end,
    correction = function(j, v) j:setCorrectionFactor(v) end,
  },
  weld = {},
  pulley = {},
}

-- Sets the values that tune the joint and differ from those set last.
function Joint:_apply()
  local j = assert(self.joint)
  local setters = {}
  for name, set in pairs(TUNING[self.kind]) do
    setters[name] = function(v)
      set(j, v, self)
    end
  end
  find.apply(self.applied, self, setters)
end

-- A text of what the joint is made from: its kind, its bodies, its place in its body, and the anchors that Box2D takes only
-- when it makes a joint.
function Joint:_key()
  local a, g, h, x = self.otherAnchor, self.groundAnchor, self.otherGroundAnchor, self.axis
  return table.concat({
    self.kind, tostring(self.other), tostring(self.collide), a.x, a.y, x.x, x.y, g.x, g.y, h.x, h.y, self.ratio,
    self.kind == "rope" and (self.length > 0 and "set" or "as joined") or "",
  }, " ") .. "|" .. find.placeKey(self.node, self.owner.node)
end

-- Not called by scripts: the body calls it before each step. A joint whose key changed is made again, which Box2D needs for
-- its anchors; else what a script changed in the values that tune it is set.
function Joint:_sync()
  if self:_key() ~= self.key then
    self:_unjoin()
    self:_join()
  elseif self.joint then
    self:_apply()
  end
end

-- Not called by scripts: the bodies call them when they start and stop.
function Joint:_join()
  if self.joint or not (self.owner and self.owner.b and self.other.b) then
    return
  end
  local ax, ay = self.node:toWorld(0, 0)
  self.key = self:_key()
  self.joint = self:_make(self.owner.b, self.other.b, ax, ay)
  self.applied = {}
  self:_apply()
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
    local anchor = (self.kind == "distance" or self.kind == "rope" or self.kind == "pulley") and self.otherAnchor or { x = 0, y = 0 }
    local x, y = self.node:toLocal(other:toWorld(anchor.x, anchor.y))
    love.graphics.line(0, 0, x, y)
  end
end

function Joint:bounds()
  return -4, -4, 8, 8
end

return Joint
