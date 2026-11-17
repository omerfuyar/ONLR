-- The component type physics.world: a world of love.physics, as a component of the root.
-- Each root has its own, so a level's bodies end with it, and its node file keeps the world's settings.
-- It steps the world at the fixed rate, keeps each body and its node in step, and tells the nodes of their contacts.
local onlr = require("onlr")

---@class physics.world : onlr.Component
---@field private world love.World?
---@field private bodies physics.body[] the running bodies, in the order they started
---@field private contacts table[] what Box2D told during the last step, which the nodes are told after it
local World = {}

World.gravity = onlr.property.vector(0, 640, { description = "Pixels a second, each second: 640 down is about Earth's at the default meter" })
World.meter = onlr.property.number(64, { min = 1, description = "How many pixels are a meter. Box2D works best with bodies of 0.1 to 10 meters" })

-- Not called by the engine: bodies call it. It makes the world at the first call, so it does not matter whose load runs first.
---@return love.World
function World:get()
  if not self.world then
    love.physics.setMeter(self.meter)
    self.world = love.physics.newWorld(self.gravity.x, self.gravity.y, true)
    self.bodies, self.contacts = {}, {}
    -- Box2D tells of contacts during its step, when nothing may change the world: they wait until it ends.
    local contacts = self.contacts
    local function nodes(a, b)
      local sa, sb = a:getUserData(), b:getUserData()
      return sa and sa.owner and sa.owner.node, sb and sb.owner and sb.owner.node
    end
    self.world:setCallbacks(function(a, b, contact)
      local na, nb = nodes(a, b)
      local nx, ny = contact:getNormal()
      contacts[#contacts + 1] = { "contact", na, nb, nx, ny }
    end, function(a, b)
      local na, nb = nodes(a, b)
      contacts[#contacts + 1] = { "contactEnd", na, nb }
    end)
  end
  return self.world
end

---@param body physics.body
function World:_add(body)
  self:get()
  self.bodies[#self.bodies + 1] = body
end

---@param body physics.body
function World:_remove(body)
  for i, other in ipairs(self.bodies or {}) do
    if other == body then
      table.remove(self.bodies, i)
      return
    end
  end
end

-- Box2D's normal points from the first body to the second. Each node is told the one that points away from the other,
-- as bump's contacts are: a body that lands on the ground gets 0, -1.
local function tell(contacts)
  local list = {}
  for i = 1, #contacts do
    list[i], contacts[i] = contacts[i], nil
  end
  for _, c in ipairs(list) do
    local name, na, nb = c[1], c[2], c[3]
    if na and nb then
      if not na:isDestroyed() then
        if c[4] then
          na:send(name, nb, -c[4], -c[5])
        else
          na:send(name, nb)
        end
      end
      if not nb:isDestroyed() then
        if c[4] then
          nb:send(name, na, c[4], c[5])
        else
          nb:send(name, na)
        end
      end
    end
  end
end

-- At the fixed rate: what scripts moved goes to Box2D, Box2D steps, and what it moved goes to the nodes.
function World:fixedUpdate(dt)
  if not self.world then
    return
  end
  -- contacts that came between two steps, such as when a body was taken out
  tell(self.contacts)
  for _, body in ipairs(self.bodies) do
    body:_push()
  end
  self.world:update(dt)
  for _, body in ipairs(self.bodies) do
    body:_pull()
  end
  tell(self.contacts)
end

return World
