-- The component type bump.body: a box of bump, as a component.
-- It is written as a script is. It does what a game with bump does by hand:
-- it adds its box to bump's world, moves it, and removes it.
local onlr = require("onlr")

---@class bump.body : onlr.Component
local Body = {}

Body.width = onlr.property.number(32, { min = 0 })
Body.height = onlr.property.number(32, { min = 0 })
-- A vector: two numbers in one row. Read as self.offset.x.
Body.offset = onlr.property.vector(0, 0, { description = "The box's corner, from the node's place" })

-- Once: finds the tree's one world. It is a component of the root, found by its type.
-- When the tree has none, the body adds one to the root.
function Body:load()
  local world = onlr.node.findComponent("bump.world") or onlr.node.root:add("bump.world")
  self.world = world:get()
end

-- Each time the body starts to run: after load, and when it or its node is turned on again.
function Body:enable()
  self.x, self.y = self.node:toWorld(self.offset.x, self.offset.y)
  self.world:add(self, self.x, self.y, self.width, self.height)
end

-- Each time the body stops running, and before it is destroyed.
-- So a node that is turned off collides with nothing.
function Body:disable()
  self.world:remove(self)
end

-- Not called by the engine: scripts call it. The box goes as far as bump lets it,
-- and the node takes bump's answer.
function Body:move(x, y)
  local hits
  self.x, self.y, hits = self.world:move(self, x + self.offset.x, y + self.offset.y)
  self.node:setWorldPosition(self.x - self.offset.x, self.y - self.offset.y)
  for _, hit in ipairs(hits) do
    -- Calls contact(...) in each component of the node that defines it.
    self.node:send("contact", hit.other.node, hit.normal.x, hit.normal.y)
    hit.other.node:send("contact", self.node, -hit.normal.x, -hit.normal.y)
  end
end

-- The node's place is the truth, and bump's box is a copy.
-- When a script sets the node's place itself, tell bump.
function Body:update()
  local x, y = self.node:toWorld(self.offset.x, self.offset.y)
  if x ~= self.x or y ~= self.y then
    self.x, self.y = x, y
    self.world:update(self, x, y)
  end
end

-- For the editor: the rectangle that the component covers, in the node's own space.
function Body:bounds()
  return self.offset.x, self.offset.y, self.width, self.height
end

-- For the node view: the box's outline, more visible when the node is chosen.
function Body:drawEditor(chosen)
  love.graphics.setColor(0, 1, 0, chosen and 1 or 0.4)
  love.graphics.rectangle("line", self.offset.x, self.offset.y, self.width, self.height)
end

return Body
