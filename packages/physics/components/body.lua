-- The component type physics.body: a body of love.physics, as a component.
-- It does what a game with love.physics does by hand: it makes the body in the root's world at the node's place,
-- fixes to it the shapes of its node and of the nodes under it, keeps it and the node in step, and ends it.
-- Its shapes are components of their own: physics.box and physics.circle.
local onlr = require("onlr")

---@class physics.body : onlr.Component
---@field world physics.world
---@field b love.Body? the body of love.physics while the component runs
---@field shapes table[] the shapes fixed to it, which their own components add
---@field private x number where the node was when the body and it were last in step
---@field private y number
---@field private angle number
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
function Body:load()
  self.world = onlr.tree.findComponent("physics.world") or onlr.tree.root:addComponent("physics.world")
  self.shapes = self.shapes or {}
end

-- Each time the body starts to run: it is made at the node's place, with the shapes that are fixed to it.
function Body:enable()
  local x, y, angle = place(self.node)
  local b = love.physics.newBody(self.world:get(), x, y, self.type)
  b:setAngle(angle)
  b:setFixedRotation(self.fixedRotation)
  b:setBullet(self.bullet)
  b:setGravityScale(self.gravityScale)
  b:setLinearDamping(self.linearDamping)
  b:setAngularDamping(self.angularDamping)
  self.b, self.x, self.y, self.angle = b, x, y, angle
  for _, shape in ipairs(self.shapes) do
    shape:_fix()
  end
  self.world:_add(self)
end

-- Each time the body stops running: it leaves the world, so a node that is turned off collides with nothing.
function Body:disable()
  self.world:_remove(self)
  for _, shape in ipairs(self.shapes) do
    shape:_unfix()
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

---A shape's component fixes itself to the body. Not called by scripts.
function Body:_attach(shape)
  self.shapes = self.shapes or {}
  self.shapes[#self.shapes + 1] = shape
  if self.b then
    shape:_fix()
  end
end

---A shape's component takes itself off the body. Not called by scripts.
function Body:_detach(shape)
  for i, other in ipairs(self.shapes or {}) do
    if other == shape then
      table.remove(self.shapes, i)
      break
    end
  end
  shape:_unfix()
end

-- Before each step: when a script moved or turned the node, the body goes there.
function Body:_push()
  local x, y, angle = place(self.node)
  if x ~= self.x or y ~= self.y or angle ~= self.angle then
    self.b:setPosition(x, y)
    self.b:setAngle(angle)
    self.b:setAwake(true)
    self.x, self.y, self.angle = x, y, angle
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
  local parentAngle = parent and select(3, place(parent)) or 0
  self.node.rot = angle - parentAngle
  self.node:setWorldPosition(x, y)
  -- as the node now is, so that only a script's change differs at the next step
  self.x, self.y, self.angle = place(self.node)
end

return Body
