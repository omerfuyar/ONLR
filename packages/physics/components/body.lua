-- The component type physics.body: a body of love.physics, as a component.
-- It does what a game with love.physics does by hand: it makes the body in the root's world at the node's place,
-- fixes to it the fixtures of its node and of the nodes under it, keeps it and the node in step, and ends it.
-- Its fixtures are components of their own, physics.fixture, which take their nodes' onlr.shape. So are its joints, physics.joint.
local onlr = require("onlr")
local find = require("physics.find")

---@class physics.body : onlr.Component
---@field world physics.world
---@field b love.Body? the body of love.physics while the component runs
---@field fixtures physics.fixture[] the fixtures fixed to it, which their own components add
---@field joints table[] the joints that hold it, which their own components add
---@field private x number where the node was when the body and it were last in step
---@field private y number
---@field private angle number
---@field private applied table<string, any> the properties as they were last set on the body
local Body = {}

Body.type = onlr.property.choice("dynamic", {
  choices = { "dynamic", "static", "kinematic" },
  description = "dynamic falls and is pushed; static never moves by itself; kinematic moves by its velocity alone",
})
Body.fixedRotation = onlr.property.bool(false, { description = "It does not turn" })
Body.bullet = onlr.property.bool(false, { description = "Checks its contacts between steps too, so a fast body does not pass through a thin one" })
Body.gravityScale = onlr.property.number(1, { description = "How much gravity pulls it: 0 floats" })
Body.linearDamping = onlr.property.number(0, { min = 0, description = "How fast it slows down by itself" })
Body.angularDamping = onlr.property.number(0, { min = 0, description = "How fast its turning slows down by itself" })

-- A node's place and angle in the world, as Box2D takes them: the angle of its x axis, clockwise, in radians.
local function place(node)
  local x, y = node:toWorld(0, 0)
  local ax, ay = node:toWorld(1, 0)
  return x, y, math.atan2(ay - y, ax - x)
end

-- Once: finds the root's one world, and adds one to the root when the tree has none.
-- While the top node loads there is no root, and that is an error.
function Body:load()
  local world = onlr.tree.findComponent("physics.world")
  if not world then
    -- while the top node loads, there is no root yet (DESIGN 5)
    if not onlr.tree.root then
      error(("physics.body on %s finds no physics.world, and there is no root to add one to while the top node loads: put a physics.world on the top node")
        :format(self.node.name), 0)
    end
    world = onlr.tree.root:addComponent("physics.world")
  end
  self.world = world
  self.fixtures = self.fixtures or {}
  self.joints = self.joints or {}
end

-- Each time the body starts to run: it is made at the node's place, with the fixtures that are fixed to it.
function Body:enable()
  local x, y, angle = place(self.node)
  local b = love.physics.newBody(self.world:get(), x, y, self.type)
  b:setAngle(angle)
  self.b, self.x, self.y, self.angle = b, x, y, angle
  self.applied = {}
  self:_apply()
  for _, fixture in ipairs(self.fixtures) do
    fixture:_fix()
  end
  self.world:_add(self)
  -- a joint is made when both of its bodies run, so the second of the two to start makes it
  for _, joint in ipairs(self.joints) do
    joint:_join()
  end
end

-- Each time the body stops running: it leaves the world, so a node that is turned off collides with nothing.
function Body:disable()
  self.world:_remove(self)
  for _, joint in ipairs(self.joints) do
    joint:_unjoin()
  end
  for _, fixture in ipairs(self.fixtures) do
    fixture:_unfix()
  end
  if self.b and not self.b:isDestroyed() then
    self.b:destroy()
  end
  self.b = nil
end

---The body of love.physics, for all that LÖVE's own functions do: applyForce, setLinearVelocity and the rest.
---nil while the component is not running.
---@return love.Body?
function Body:get()
  return self.b
end

---A fixture fixes itself to the body. Not called by scripts.
function Body:_attach(fixture)
  self.fixtures = self.fixtures or {}
  self.fixtures[#self.fixtures + 1] = fixture
  if self.b then
    fixture:_fix()
  end
end

---A fixture takes itself off the body. Not called by scripts.
function Body:_detach(fixture)
  for i, other in ipairs(self.fixtures or {}) do
    if other == fixture then
      table.remove(self.fixtures, i)
      break
    end
  end
  fixture:_unfix()
end

---A joint's component holds the body. Not called by scripts.
function Body:_hold(joint)
  self.joints = self.joints or {}
  self.joints[#self.joints + 1] = joint
end

---A joint's component lets the body go. Not called by scripts.
function Body:_release(joint)
  for i, other in ipairs(self.joints or {}) do
    if other == joint then
      table.remove(self.joints, i)
      return
    end
  end
end

-- What sets each property on the body of love.physics.
local SETTERS = {
  type = function(b, v) b:setType(v) end,
  fixedRotation = function(b, v) b:setFixedRotation(v) end,
  bullet = function(b, v) b:setBullet(v) end,
  gravityScale = function(b, v) b:setGravityScale(v) end,
  linearDamping = function(b, v) b:setLinearDamping(v) end,
  angularDamping = function(b, v) b:setAngularDamping(v) end,
}

-- Sets the properties that differ from those set last: at the start, and before each step, so a script changes them as fields.
function Body:_apply()
  find.apply(self.applied, self, SETTERS, assert(self.b))
end

-- Before each step: when a script moved or turned the node, the body goes there; what a script changed in the body's
-- properties, in its fixtures and in its joints is set (DESIGN 11.4).
function Body:_push()
  local x, y, angle = place(self.node)
  if x ~= self.x or y ~= self.y or angle ~= self.angle then
    self.b:setPosition(x, y)
    self.b:setAngle(angle)
    self.b:setAwake(true)
    self.x, self.y, self.angle = x, y, angle
  end
  self:_apply()
  for _, fixture in ipairs(self.fixtures) do
    fixture:_sync()
  end
  for _, joint in ipairs(self.joints) do
    if joint.owner == self then
      joint:_sync()
    end
  end
end

-- After each step: the node takes the place and the angle that Box2D gave the body.
function Body:_pull()
  if self.type == "static" then
    return
  end
  local x, y = self.b:getPosition()
  local angle = self.b:getAngle()
  local parent = self.node:getParent()
  local parentAngle = 0
  if parent then
    local _, _, a = place(parent)
    parentAngle = a
  end
  self.node.rot = angle - parentAngle
  self.node:setWorldPosition(x, y)
  -- as the node now is, so that only a script's change differs at the next step
  self.x, self.y, self.angle = place(self.node)
end

return Body
