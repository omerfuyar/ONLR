-- The component type physics.fixture: its node's onlr.shape, fixed to the nearest physics.body on its node or above it, as
-- LÖVE fixes a shape to a body (DESIGN 11.4). The node's outline is the one that paints and collides, so the user sizes it once.
-- A rectangle is a box, a circle a circle, a polygon a convex polygon of 3 to 8 corners, and a line an edge, or a chain of more
-- than two points, open or a loop. It turns and scales with its node, so a fixture on a node under the body may sit anywhere on it.
-- Before each step, a fixture whose node moved under its body, or whose shape changed, is made again, and a property that a
-- script changed is set (DESIGN 11.4).
local onlr = require("onlr")
local find = require("physics.find")

---@class physics.fixture : onlr.Component
---@field owner physics.body? the body that it is fixed to
---@field fixture love.Fixture?
---@field private seen any[]? its shape and its place in the body, at the last check
---@field private applied table<string, any> the properties as they were last set on the fixture
local Fixture = {}

Fixture.needs = { "onlr.shape" }

Fixture.friction = onlr.property.number(0.2, { min = 0, description = "How much it holds what slides on it: 0 is ice" })
Fixture.restitution = onlr.property.number(0, { min = 0, description = "How much it bounces: 1 keeps all its speed" })
Fixture.density = onlr.property.number(1, { min = 0, description = "How heavy it is for its size" })
Fixture.sensor = onlr.property.bool(false, { description = "It stops nothing, and is still told of contacts" })
Fixture.loop = onlr.property.bool(false, { description = "A line of more than two points closes into a loop, as Box2D's chain does, from its last point to its first" })

-- Each time the fixture starts to run: it fixes itself to the nearest body above it.
function Fixture:enable()
  self.owner = find.bodyOf(self.node)
  if not self.owner then
    error(("physics.fixture on %s has no physics.body on its node or above it"):format(self.node.name), 0)
  end
  self.owner:_attach(self)
end

function Fixture:disable()
  if self.owner then
    self.owner:_detach(self)
    self.owner = nil
  end
end

---The fixture of love.physics, for all that LÖVE's own functions do; nil while it is not fixed to a running body.
---@return love.Fixture?
function Fixture:get()
  return self.fixture
end

-- Points of the node's space, x, y, x, y, in the body's space.
local function inBody(node, b, points)
  local bx, by = b:getPosition()
  local cos, sin = math.cos(-b:getAngle()), math.sin(-b:getAngle())
  local out = {}
  for i = 1, #points, 2 do
    local wx, wy = node:toWorld(points[i], points[i + 1])
    local dx, dy = wx - bx, wy - by
    out[i], out[i + 1] = dx * cos - dy * sin, dx * sin + dy * cos
  end
  return out
end

-- Box2D's shape of the node's outline, in the body's space; nil while the outline has too few points to be one.
function Fixture:_shape(b)
  local o = self.node.components.onlr.shape:outline()
  local name = self.node.name
  if o.kind == "rectangle" then
    local x, y, w, h = o.x, o.y, o.width, o.height
    return love.physics.newPolygonShape(inBody(self.node, b, { x, y, x + w, y, x + w, y + h, x, y + h }))
  elseif o.kind == "circle" then
    local p = inBody(self.node, b, { o.x, o.y })
    return love.physics.newCircleShape(p[1], p[2], o.radius * find.scale(self.node))
  elseif o.kind == "polygon" then
    local corners = #o.points / 2
    if corners < 3 then
      return nil
    elseif corners > 8 then
      error(("physics.fixture on %s has a polygon of %d corners, and Box2D takes at most 8"):format(name, corners), 0)
    end
    local ok, made = pcall(love.physics.newPolygonShape, inBody(self.node, b, o.points))
    if not ok then
      error(("physics.fixture on %s has a polygon that is not convex, as Box2D needs: %s"):format(name, tostring(made)), 0)
    end
    return made
  end
  local count = #o.points / 2
  if count < 2 then
    return nil
  elseif count == 2 then
    local p = inBody(self.node, b, o.points)
    return love.physics.newEdgeShape(p[1], p[2], p[3], p[4])
  end
  return love.physics.newChainShape(self.loop, inBody(self.node, b, o.points))
end

-- Whether the node's outline or its place in the body changed since the last check, which then keeps them (find.start).
function Fixture:_changed()
  local shape = assert(self.node.components.onlr.shape)
  self.seen = self.seen or {}
  find.start(self.seen)
  find.note(shape.kind)
  find.note(shape.origin.x)
  find.note(shape.origin.y)
  find.note(shape.width)
  find.note(shape.height)
  find.note(shape.radius)
  find.note(self.loop)
  find.note(#shape.points)
  for _, point in ipairs(shape.points) do
    find.note(point.x)
    find.note(point.y)
  end
  find.place(self.node, self.owner.node)
  return find.finish()
end

-- What sets each property on the fixture of love.physics.
local SETTERS = {
  friction = function(f, v) f:setFriction(v) end,
  restitution = function(f, v) f:setRestitution(v) end,
  sensor = function(f, v) f:setSensor(v) end,
  density = function(f, v, c)
    f:setDensity(v)
    c.owner.b:resetMassData()
  end,
}

-- Sets on the fixture the properties that differ from those set last.
function Fixture:_apply()
  find.apply(self.applied, self, SETTERS, assert(self.fixture))
end

-- Not called by scripts: the body calls it before each step. A fixture whose shape or place changed is made again, which
-- Box2D needs, as its shapes do not change; else what a script changed in its properties is set.
function Fixture:_sync()
  if self:_changed() then
    self:_unfix()
    self:_fix()
  elseif self.fixture then
    self:_apply()
  end
end

-- Not called by scripts: the body calls them when it starts and stops.
function Fixture:_fix()
  local b = self.owner and self.owner.b
  if not b then
    return
  end
  self:_changed()
  local made = self:_shape(b)
  if not made then
    return
  end
  local fixture = love.physics.newFixture(b, made, self.density)
  fixture:setUserData(self)
  self.fixture = fixture
  self.applied = { density = self.density }
  self:_apply()
end

function Fixture:_unfix()
  if self.fixture and not self.fixture:isDestroyed() then
    self.fixture:destroy()
  end
  self.fixture = nil
end

return Fixture
