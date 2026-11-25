-- The component type sti.bump: the tiles of its node's map that collide are boxes of bump's world (DESIGN 11.7), so a
-- bump.body stops at them, as at another solid body. Which tiles collide, Tiled says, by the property collidable.
-- A box's contact names the map's node: a script finds the tile with the map's toTile.
local onlr = require("onlr")
local solid = require("sti.solid")

---@class sti.bump : onlr.Component
---@field private world table bump's world
---@field private boxes table[] the map's boxes in it
---@field private reads table the boxes' metatable, which gives them the component's solid
local Bump = {}

Bump.needs = { "sti.map" }

Bump.solid = onlr.property.bool(true, { description = "Bodies stop at the tiles. They pass through when it is off, and are still told of the contact" })

-- Once: finds the tree's one bump.world, and adds one to the root when the tree has none, as bump.body does.
function Bump:load()
  local world = onlr.tree.findComponent("bump.world") or onlr.tree.root:addComponent("bump.world")
  self.world = world:get()
  self.boxes = {}
  self.reads = { __index = function(_, key)
    if key == "solid" then
      return self.solid
    end
  end }
end

-- Each time it starts to run: a box for each rectangle, where the node puts it in the world now. bump's boxes do not turn.
function Bump:enable()
  for _, r in ipairs(solid.rectangles(solid.mapOf(self.node, "sti.bump"))) do
    local x1, y1 = self.node:toWorld(r.x, r.y)
    local x2, y2 = self.node:toWorld(r.x + r.width, r.y + r.height)
    -- a box's solid is the component's, which a script may change at any time
    local box = setmetatable({ node = self.node, tile = r }, self.reads)
    self.world:add(box, math.min(x1, x2), math.min(y1, y2), math.abs(x2 - x1), math.abs(y2 - y1))
    self.boxes[#self.boxes + 1] = box
  end
end

-- Each time it stops running: the boxes leave the world, so a map that is turned off collides with nothing.
function Bump:disable()
  for _, box in ipairs(self.boxes) do
    if self.world:hasItem(box) then
      self.world:remove(box)
    end
  end
  self.boxes = {}
end

-- Not called by the engine: scripts call it. The boxes, each with tile: its rectangle in the map, its layer and properties.
---@return table[]
function Bump:getBoxes()
  return self.boxes
end

return Bump
