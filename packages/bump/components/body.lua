-- The component type bump.body: a box of bump, as a component.
-- It is written as a script is. It does what a game with bump does by hand:
-- it adds its box to bump's world, moves it, and removes it.
-- Its box is its node's onlr.shape, a rectangle, which it reads each time it uses it: the node's outline is the one that paints
-- and collides, so the user sizes it once. bump's boxes do not turn, so the node's angle and scale do not reach the box.
local onlr = require("onlr")

---@class bump.body : onlr.Component
local Body = {}

Body.needs = { "onlr.shape" }

Body.solid = onlr.property.bool(true, { description = "Other bodies stop at it. They pass through one that is not solid, and are still told of the contact" })

-- Once: finds the tree's one world. It is a component of the root, found by its type.
-- When the tree has none, the body adds one to the root. While the top node loads there is none, and that is an error.
function Body:load()
  local world = onlr.tree.findComponent("bump.world")
  if not world then
    -- while the top node loads, there is no root yet (DESIGN 5)
    if not onlr.tree.root then
      error(("bump.body on %s finds no bump.world, and there is no root to add one to while the top node loads: put a bump.world on the top node")
        :format(self.node.name), 0)
    end
    world = onlr.tree.root:addComponent("bump.world")
  end
  self.world = world:get()
end

-- The box from the node's place, as the shape's rectangle gives it: its corner and its size. A shape of another kind is an error
-- that names the node, as bump has boxes only. It reads the shape's values as its outline() does, without the outline's
-- tables, as update calls it at each frame.
function Body:_box()
  local shape = self.node.components.onlr.shape --[[@as onlr.shape]]
  if shape.kind ~= "rectangle" then
    error(("bump.body on %s takes a rectangle, and its onlr.shape is a %s"):format(self.node.name, shape.kind), 0)
  end
  local origin = shape.origin
  return -origin.x, -origin.y, shape.width, shape.height
end

-- Each time the body starts to run: after load, and when it or its node is turned on again.
function Body:enable()
  local ox, oy, w, h = self:_box()
  self.x, self.y = self.node:toWorld(ox, oy)
  self.w, self.h = w, h
  self.world:add(self, self.x, self.y, w, h)
end

-- Each time the body stops running, and before it is destroyed.
-- So a node that is turned off collides with nothing.
function Body:disable()
  if self.world:hasItem(self) then
    self.world:remove(self)
  end
end

-- Not called by the engine: scripts call it. The box goes as far as bump lets it,
-- and the node takes bump's answer.
-- What bump does when a moving box meets another: it slides along a solid one, and crosses any other.
local function meet(_, other)
  return other.solid and "slide" or "cross"
end

function Body:move(x, y)
  local ox, oy = self:_box()
  local hits
  self.x, self.y, hits = self.world:move(self, x + ox, y + oy, meet)
  self.node:setWorldPosition(self.x - ox, self.y - oy)
  for _, hit in ipairs(hits) do
    -- Calls contact(...) in each component of the node that defines it.
    self.node:send("contact", hit.other.node, hit.normal.x, hit.normal.y)
    hit.other.node:send("contact", self.node, -hit.normal.x, -hit.normal.y)
  end
end

-- A body that was turned off while it was told of a contact is no longer in bump's world.
function Body:destroy()
  self.world = nil
end

-- The node's place and its shape are the truth, and bump's box is a copy.
-- When a script sets the node's place or the shape's size itself, tell bump.
function Body:update()
  local ox, oy, w, h = self:_box()
  local x, y = self.node:toWorld(ox, oy)
  if x ~= self.x or y ~= self.y or w ~= self.w or h ~= self.h then
    self.x, self.y, self.w, self.h = x, y, w, h
    self.world:update(self, x, y, w, h)
  end
end

return Body
