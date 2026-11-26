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
  self.world = World.find(self, "shadows.caster")
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

-- How many of the outline's points the shadow is made of: a rectangle's 4 corners, a circle's middle and a point on its edge
-- across, so a scale of the node reaches the radius, or a polygon's corners; 0 for what casts nothing.
---@param shape onlr.shape
---@return integer
local function count(shape)
  local kind = shape.kind
  if kind == "rectangle" then
    return 4
  elseif kind == "circle" then
    return 2
  elseif kind == "polygon" and #shape.points >= 3 then
    return #shape.points
  end
  return 0
end

-- The outline's point i in its node's space, read from the shape's values as its outline() does, without the outline's
-- tables, as the world asks for them at each frame.
---@param shape onlr.shape
---@param i integer
---@return number x, number y
local function point(shape, i)
  local kind = shape.kind
  if kind == "polygon" then
    local p = shape.points[i]
    return p.x, p.y
  end
  local x, y = -shape.origin.x, -shape.origin.y
  if kind == "circle" then
    return i == 1 and x or x + shape.radius, y
  end
  local w, h = shape.width, shape.height
  if i == 1 then
    return x, y
  elseif i == 2 then
    return x + w, y
  elseif i == 3 then
    return x + w, y + h
  end
  return x, y + h
end

-- The world calls it before it draws: the shadow is made again when the shape's kind changed, and moves only when its points in
-- the world changed, as Shädows makes its shadows again for a shape that moved. The points are compared in place with those
-- given last, in one list that it keeps, so a frame in which nothing moved makes no garbage.
function Caster:_sync()
  local shape = self.node.components.onlr.shape --[[@as onlr.shape]]
  local n = count(shape)
  if n == 0 then
    self:_clear()
    return
  end
  local kind = shape.kind == "circle" and "circle" or "polygon"
  local placed = self.placed
  -- after _clear, which ends placed and kind together, the shadow is made again
  local remake = not placed or kind ~= self.kind or (kind == "polygon" and #placed ~= 2 * n)
  local moved = remake
  placed = placed or {}
  local node = self.node
  for i = 1, n do
    local x, y = node:toWorld(point(shape, i))
    local j = 2 * i - 1
    if placed[j] ~= x or placed[j + 1] ~= y then
      placed[j], placed[j + 1] = x, y
      moved = true
    end
  end
  for i = #placed, 2 * n + 1, -1 do
    placed[i] = nil
  end
  if not moved then
    return
  end
  if remake then
    self:_clear()
    self.body = Body:new(self.world:_world())
    if kind == "circle" then
      self.shadow = CircleShadow:new(self.body, 0, 0, 1)
    else
      self.shadow = PolygonShadow:new(self.body, unpack(placed))
    end
    self.kind = kind
  end
  self.placed = placed
  if kind == "circle" then
    local x, y, ex, ey = placed[1], placed[2], placed[3], placed[4]
    self.body:SetPosition(x, y)
    self.shadow:SetRadius(math.sqrt((ex - x) ^ 2 + (ey - y) ^ 2))
  else
    self.shadow:SetVertices(unpack(placed))
  end
end

---Not called by the engine: scripts call it. Shädows' shadow shape, for what the component does not do; nil for a shape that
---casts nothing.
---@return table?
function Caster:get()
  return self.shadow
end

return Caster
