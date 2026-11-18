-- The component type moonshine.chain: a group (DESIGN 5) that draws its node and all under it through moonshine's
-- effects. The effects are the components of moonshine's other types on the same node, such as moonshine.vignette,
-- applied in their order on the node. An effect whose component is off is skipped, and a property that a script or a
-- tween changes reaches the effect in the next frame.
local moonshine = require("moonshine")

---@class moonshine.chain : onlr.Component
---@field private effects table[] the effects' components, in the order they loaded
---@field private built table? moonshine's chain
---@field private dirty boolean? the effects changed since the chain was made
---@field private width number?
---@field private height number?
local Chain = {}

function Chain:load()
  self.effects = self.effects or {}
end

-- An effect's component joins the chain when it loads, and leaves it when it is destroyed.
function Chain:_add(component)
  self.effects = self.effects or {}
  self.effects[#self.effects + 1] = component
  self.dirty = true
end

function Chain:_remove(component)
  for i, c in ipairs(self.effects) do
    if c == component then
      table.remove(self.effects, i)
      self.dirty = true
      return
    end
  end
end

-- A value as a key, to tell whether it changed: numbers, strings, and tables of them.
local function key(v)
  if type(v) ~= "table" then
    return tostring(v)
  end
  local parts = {}
  for i = 1, #v do
    parts[i] = tostring(v[i])
  end
  return table.concat(parts, ",")
end

-- Makes moonshine's chain anew, at a size, with the effects of the components.
function Chain:_build(w, h)
  local first = self.effects[1]
  local built = moonshine(w, h, moonshine.effects[first._effect])
  for i = 2, #self.effects do
    built.chain(moonshine.effects[self.effects[i]._effect])
  end
  for _, c in ipairs(self.effects) do
    c._sent = {}
  end
  self.built, self.width, self.height, self.dirty = built, w, h, false
end

-- Turns effects on and off by their components, and sends the parameters that changed.
function Chain:_settle()
  local built = assert(self.built)
  for _, c in ipairs(self.effects) do
    local name = c._effect
    if c:isEnabled() then
      built.enable(name)
    else
      built.disable(name)
    end
    local sent = c._sent
    for k, v in pairs(c:_params()) do
      local now = key(v)
      if sent[k] ~= now then
        built[name][k] = v
        sent[k] = now
      end
    end
  end
end

local placed

-- The engine calls it in place of drawing the group, and gives it draw, which draws the group.
-- moonshine draws the scene into canvases of the size of what it draws into: the window, or push's canvas when a
-- push.screen holds it. It draws its result where the drawing is, so the group's nodes are drawn with the drawing's
-- place, and the result with none, or they would be moved twice.
---@param draw fun()
function Chain:drawTree(draw)
  if #self.effects == 0 then
    draw()
    return
  end
  local canvas = love.graphics.getCanvas()
  local w, h
  if canvas then
    w, h = canvas:getDimensions()
  else
    w, h = love.graphics.getDimensions()
  end
  if self.dirty or not self.built then
    self:_build(w, h)
  elseif w ~= self.width or h ~= self.height then
    self.built.resize(w, h)
    self.width, self.height = w, h
  end
  self:_settle()

  local ox, oy = love.graphics.transformPoint(0, 0)
  local ax, ay = love.graphics.transformPoint(1, 0)
  local bx, by = love.graphics.transformPoint(0, 1)
  placed = placed or love.math.newTransform()
  placed:setMatrix(ax - ox, bx - ox, 0, ox, ay - oy, by - oy, 0, oy, 0, 0, 1, 0, 0, 0, 0, 1)
  love.graphics.push()
  love.graphics.origin()
  self.built.draw(function()
    love.graphics.push()
    love.graphics.applyTransform(placed)
    draw()
    love.graphics.pop()
  end)
  love.graphics.pop()
end

-- moonshine's chain, for what the components do not do. It is made at the first frame that draws, and made again
-- when an effect joins or leaves.
---@return table?
function Chain:get()
  return self.built
end

return Chain
