-- The component type sti.physics: the tiles of its node's map that collide are fixtures of one static body of Box2D's world
-- (DESIGN 11.7), so a physics.body falls onto them and rests. Which tiles collide, Tiled says, by the property collidable.
-- A contact names the map's node.
local onlr = require("onlr")
local solid = require("sti.solid")

---@class sti.physics : onlr.Component
---@field private world physics.world
---@field private b love.Body? the static body, while it runs
local Physics = {}

Physics.needs = { "sti.map" }

Physics.friction = onlr.property.number(0.2, { min = 0, description = "How much the tiles hold what slides on them, as a fixture's" })
Physics.restitution = onlr.property.number(0, { min = 0, description = "How much what hits them bounces, as a fixture's" })
Physics.sensor = onlr.property.bool(false, { description = "Bodies pass through the tiles, and are still told of the contact" })

-- Once: finds the root's one physics.world, and adds one to the root when the tree has none, as physics.body does.
function Physics:load()
  self.world = onlr.tree.findComponent("physics.world") or onlr.tree.root:addComponent("physics.world")
end

-- Each time it starts to run: a static body at the node's place and angle, and a rectangle for each tile, scaled as the node.
function Physics:enable()
  local node = self.node
  local x, y = node:toWorld(0, 0)
  local ax, ay = node:toWorld(1, 0)
  local bx, by = node:toWorld(0, 1)
  local sx, sy = math.sqrt((ax - x) ^ 2 + (ay - y) ^ 2), math.sqrt((bx - x) ^ 2 + (by - y) ^ 2)
  local b = love.physics.newBody(self.world:get(), x, y, "static")
  b:setAngle(math.atan2(ay - y, ax - x))
  for _, r in ipairs(solid.rectangles(solid.mapOf(node, "sti.physics"))) do
    local shape = love.physics.newRectangleShape((r.x + r.width / 2) * sx, (r.y + r.height / 2) * sy, r.width * sx, r.height * sy)
    local fixture = love.physics.newFixture(b, shape)
    fixture:setFriction(self.friction)
    fixture:setRestitution(self.restitution)
    fixture:setSensor(self.sensor)
    -- the world's contacts name a fixture's owner's node (packages/physics/components/world.lua)
    fixture:setUserData({ owner = self, tile = r })
  end
  self.b = b
end

-- Each time it stops running: the body leaves the world.
function Physics:disable()
  if self.b and not self.b:isDestroyed() then
    self.b:destroy()
  end
  self.b = nil
end

-- Not called by the engine: scripts call it. Box2D's static body, whose fixtures' user data hold tile: the rectangle, its
-- layer and its properties.
---@return love.Body?
function Physics:getBody()
  return self.b
end

return Physics
