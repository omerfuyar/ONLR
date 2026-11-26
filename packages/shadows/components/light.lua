-- The component type shadows.light: a light at its node, which casters in its way cast shadows from. It belongs to the
-- nearest shadows.world on its node or above it, and follows its node's place and angle.
local onlr = require("onlr")
require("shadows")
local Light = require("shadows.Light")
local World = require("packages.shadows.components.world")

---@class shadows.light : onlr.Component
---@field private world shadows.world?
---@field private light table? Shädows' Light
local Lamp = {}

Lamp.radius = onlr.property.number(200, { min = 1, description = "How far it reaches, in the world's pixels" })
Lamp.color = onlr.property.color({ 1, 1, 1, 1 }, { description = "Its colour. Its alpha is how bright it is" })
Lamp.arc = onlr.property.number(2 * math.pi, {
  min = 0,
  max = 2 * math.pi,
  angle = true,
  description = "The angle that it lights around its node's way: a whole turn lights all around, a sixth of one is a torch's beam",
})
Lamp.blur = onlr.property.bool(true, { description = "Soft edges of its shadows, which harden near what casts them" })
Lamp.sizeRadius = onlr.property.number(10, { min = 0, description = "How large the light's source is: larger softens far shadows more" })

function Lamp:enable()
  self.world = World.find(self, "shadows.light")
  self.light = Light:new(self.world:_world(), self.radius)
  self.world:_add(self)
  self:_sync()
end

function Lamp:disable()
  if self.world then
    self.world:_remove(self)
  end
  if self.light then
    self.light:Remove()
  end
  self.world, self.light = nil, nil
end

-- Gives Shädows the node's place and angle, and what a script changed. The world calls it before it draws.
function Lamp:_sync()
  local light = self.light
  if not light then
    return
  end
  local x, y = self.node:toWorld(0, 0)
  local ax, ay = self.node:toWorld(1, 0)
  light:SetPosition(x, y)
  -- Shädows' beam points up at its angle 0, and the node's way is along its x axis, so a quarter turn more
  light:SetAngle(math.deg(math.atan2(ay - y, ax - x)) + 90)
  if light:GetRadius() ~= self.radius then
    light:SetRadius(self.radius)
  end
  light:SetColor(self.color[1], self.color[2], self.color[3], self.color[4] or 1)
  -- Shädows takes the arc in degrees, and lights all around from 360
  light.Arc, light.Blur, light.SizeRadius = math.min(360, math.deg(self.arc)), self.blur, self.sizeRadius
end

-- In the node view, its reach as a circle, or its beam as an arc.
function Lamp:drawEditor(chosen)
  local c = self.color
  love.graphics.setColor(c[1], c[2], c[3], chosen and 0.9 or 0.5)
  love.graphics.circle("fill", 0, 0, 4)
  love.graphics.setLineWidth(1)
  if self.arc >= 2 * math.pi then
    love.graphics.circle("line", 0, 0, self.radius)
  else
    local half = self.arc / 2
    love.graphics.arc("line", "pie", 0, 0, self.radius, -half, half)
  end
end

function Lamp:bounds()
  return -8, -8, 16, 16
end

-- Not called by the engine: scripts call these.

-- Shädows' Light, for what the component does not do, such as SetImage.
---@return table?
function Lamp:get()
  return self.light
end

return Lamp
