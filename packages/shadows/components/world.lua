-- The component type shadows.world: a group (DESIGN 5) that draws its node and all under it, then darkens them where
-- no light reaches. The lights are shadows.light components on its node or under it, and what blocks them are
-- shadows.caster components. It is Shädows' LightWorld, drawn where the drawing is, so a camera above it moves the light
-- with the world.
local onlr = require("onlr")
require("shadows") -- the library, which makes its modules ready to require
local LightWorld = require("shadows.LightWorld")

---@class shadows.world : onlr.Component
---@field private lit table? Shädows' LightWorld
---@field private members table[] its lights and casters, which it moves to their nodes before it draws
---@field private width number?
---@field private height number?
local World = {}

World.color = onlr.property.color({ 0, 0, 0, 1 }, {
  description = "The colour where no light reaches, which the scene is multiplied by: black is dark, white is no darkness",
})

-- Shädows' world, made when it is first needed: its lights and casters may load before it on the same node.
---@return table
function World:_world()
  if not self.lit then
    self.lit = LightWorld:new()
    self.width, self.height = self.lit:GetWidth(), self.lit:GetHeight()
  end
  return self.lit
end

function World:_add(member)
  self.members = self.members or {}
  self.members[#self.members + 1] = member
end

function World:_remove(member)
  for i, m in ipairs(self.members or {}) do
    if m == member then
      table.remove(self.members, i)
      return
    end
  end
end

function World:load()
  self.members = self.members or {}
  self:_world()
end

-- The engine calls it in place of drawing the group, and gives it draw, which draws the group.
---@param draw fun()
function World:drawTree(draw)
  local lit = self:_world()
  local canvas = love.graphics.getCanvas()
  local w, h
  if canvas then
    w, h = canvas:getDimensions()
  else
    w, h = love.graphics.getDimensions()
  end

  -- Where the world's points are in what it draws into, as a camera above it put them: Shädows takes a place and a
  -- scale, so a point p is at (p - x, y) * scale.
  local ox, oy = love.graphics.transformPoint(0, 0)
  local ax, ay = love.graphics.transformPoint(1, 0)
  local scale = math.sqrt((ax - ox) ^ 2 + (ay - oy) ^ 2)

  love.graphics.push("all")
  if w ~= self.width or h ~= self.height then
    lit:Resize(w, h)
    self.width, self.height = w, h
  end
  lit:SetColor(self.color[1], self.color[2], self.color[3], self.color[4] or 1)
  lit:SetPosition(-ox / scale, -oy / scale, scale)
  for _, member in ipairs(self.members) do
    member:_sync()
  end
  lit:Update()
  love.graphics.pop()

  draw()

  love.graphics.push("all")
  lit:Draw()
  love.graphics.pop()
end

function World:destroy()
  self.lit = nil
end

-- Not called by the engine: scripts call these.

-- Shädows' LightWorld, for what the components do not do, such as its rooms and stars.
---@return table
function World:get()
  return self:_world()
end

-- The shadows.world on a node or the nearest above it, for a light or a caster. When there is none, one is added to the root,
-- as a body of physics or of bump adds its world (DESIGN 11.3).
---@param component onlr.Component
---@return shadows.world
function World.find(component)
  local node = component.node ---@type onlr.Node?
  while node do
    local world = node.components.shadows.world
    if world then
      return world
    end
    node = node:getParent()
  end
  return onlr.tree.root:addComponent("shadows.world")
end

return World
