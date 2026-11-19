-- The component type shadows.caster: its node's onlr.shape blocks light, and casts shadows (DESIGN 11.14). The node's outline
-- is the one that paints, collides and casts, so the user sizes it once. A rectangle, a circle and a convex polygon cast; a line
-- casts nothing. It belongs to the nearest shadows.world on its node or above it, and follows its node's place, angle and scale.
require("shadows") -- the library, which makes its modules ready to require
local Body = require("shadows.Body")
local PolygonShadow = require("shadows.ShadowShapes.PolygonShadow")
local CircleShadow = require("shadows.ShadowShapes.CircleShadow")
local World = require("packages.shadows.components.world")

---@class shadows.caster : onlr.Component
---@field private world shadows.world?
---@field private body table? Shädows' Body, which its shadow shape is on
---@field private shadow table? Shädows' shadow shape
---@field private kind string? the shape's kind that the shadow shape was made for
---@field private placed number[]? the points in the world that it was last given
local Caster = {}

Caster.needs = { "onlr.shape" }

function Caster:enable()
  self.world = World.find(self)
  self.world:_add(self)
  self:_sync()
end

-- Takes Shädows' body and shape out of its world.
function Caster:_clear()
  if self.body then
    self.body:Remove()
  end
  self.body, self.shadow, self.kind, self.placed = nil, nil, nil, nil
end

function Caster:disable()
  if self.world then
    self.world:_remove(self)
  end
  self:_clear()
  self.world = nil
end

-- The outline's points that the shadow is made of, in its node's space: a rectangle's corners, a circle's middle and a point
-- on its edge across, so a scale of the node reaches the radius, or a polygon's corners; nil for what casts nothing.
local function points(o)
  if o.kind == "rectangle" then
    local x, y, w, h = o.x, o.y, o.width, o.height
    return { x, y, x + w, y, x + w, y + h, x, y + h }
  elseif o.kind == "circle" then
    return { o.x, o.y, o.x + o.radius, o.y }
  elseif o.kind == "polygon" and #o.points >= 6 then
    return o.points
  end
end

-- The world calls it before it draws: the shadow is made again when the shape's kind changed, and moves only when its points in
-- the world changed, as Shädows makes its shadows again for a shape that moved.
function Caster:_sync()
  local o = self.node.components.onlr.shape:outline()
  local own = points(o)
  if not own then
    self:_clear()
    return
  end
  local world = {}
  for i = 1, #own, 2 do
    world[i], world[i + 1] = self.node:toWorld(own[i], own[i + 1])
  end
  local kind = o.kind == "circle" and "circle" or "polygon"
  if kind ~= self.kind or (kind == "polygon" and self.placed and #self.placed ~= #world) then
    self:_clear()
    self.body = Body:new(self.world:_world())
    if kind == "circle" then
      self.shadow = CircleShadow:new(self.body, 0, 0, 1)
    else
      self.shadow = PolygonShadow:new(self.body, unpack(world))
    end
    self.kind = kind
  end
  local placed = self.placed
  if placed and #placed == #world then
    local same = true
    for i = 1, #world do
      same = same and placed[i] == world[i]
    end
    if same then
      return
    end
  end
  self.placed = world
  if kind == "circle" then
    local x, y, ex, ey = world[1], world[2], world[3], world[4]
    self.body:SetPosition(x, y)
    self.shadow:SetRadius(math.sqrt((ex - x) ^ 2 + (ey - y) ^ 2))
  else
    self.shadow:SetVertices(unpack(world))
  end
end

---Not called by the engine: scripts call it. Shädows' shadow shape, for what the component does not do; nil for a shape that
---casts nothing.
---@return table?
function Caster:get()
  return self.shadow
end

return Caster
