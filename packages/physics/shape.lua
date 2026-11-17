-- What every shape's component of physics shares: its properties for Box2D's fixture, finding its body, and fixing itself
-- to it. A shape is on the body's node or on a node under it, and is fixed to the nearest body above, so a body of many
-- shapes holds them on nodes of their own (DESIGN 11.4). Each type gives _outline, its points in the body's space.
local onlr = require("onlr")

local shape = {}

-- The body nearest above a node, the node's own first.
local function bodyOf(node)
  while node do
    local own = node.components.physics
    if own and own.body then
      return own.body
    end
    node = node:getParent()
  end
end

-- A function that turns a point of the shape's node into the space of the body, as Box2D places a fixture in it.
local function toBody(node, b)
  local bx, by = b:getPosition()
  local cos, sin = math.cos(-b:getAngle()), math.sin(-b:getAngle())
  return function(x, y)
    local wx, wy = node:toWorld(x, y)
    local dx, dy = wx - bx, wy - by
    return dx * cos - dy * sin, dx * sin + dy * cos
  end
end

---Gives a shape's type the properties and functions that every shape has.
---@param Type table
---@param name string the type's name, such as "physics.box"
function shape.declare(Type, name)
  Type.friction = onlr.property.number(0.2, { min = 0, description = "How much it holds what slides on it: 0 is ice" })
  Type.bounce = onlr.property.number(0, { min = 0, description = "How much it bounces: 1 keeps all its speed" })
  Type.density = onlr.property.number(1, { min = 0, description = "How heavy it is for its size" })
  Type.sensor = onlr.property.bool(false, { description = "It stops nothing, and is still told of contacts" })

  -- Each time the shape starts to run: it fixes itself to the nearest body above it.
  function Type:enable()
    self.owner = bodyOf(self.node)
    if not self.owner then
      error(("%s on %s has no physics.body on its node or above it"):format(name, self.node.name), 0)
    end
    self.owner:_attach(self)
  end

  function Type:disable()
    if self.owner then
      self.owner:_detach(self)
      self.owner = nil
    end
  end

  ---The fixture of love.physics, for all that LÖVE's own functions do; nil while it is not fixed to a running body.
  ---@return love.Fixture?
  function Type:get()
    return self.fixture
  end

  -- Not called by scripts: the body calls them when it starts and stops.
  function Type:_fix()
    local b = self.owner.b
    local fixture = love.physics.newFixture(b, self:_outline(toBody(self.node, b)), self.density)
    fixture:setFriction(self.friction)
    fixture:setRestitution(self.bounce)
    fixture:setSensor(self.sensor)
    fixture:setUserData(self)
    self.fixture = fixture
  end

  function Type:_unfix()
    if self.fixture and not self.fixture:isDestroyed() then
      self.fixture:destroy()
    end
    self.fixture = nil
  end
end

---How large one unit of a node's space is in the world, for a circle's radius.
---@param node onlr.Node
---@return number
function shape.scale(node)
  local x0, y0 = node:toWorld(0, 0)
  local x1, y1 = node:toWorld(1, 0)
  return math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
end

return shape
