-- The component type bump.body: a box of bump, as a component.
-- It is written as a script is. It does what a game with bump does by hand:
-- it adds its box to bump's world, moves it, and removes it.
local onlr = require("onlr")

---@class bump.body : onlr.Component
local Body = {}

Body.width = onlr.property.number(32, { min = 0 })
Body.height = onlr.property.number(32, { min = 0 })
-- A vector: two numbers in one row. Read as self.offset.x.
Body.offset = onlr.property.vector(0, 0, { description = "The box's corner, from the object's place" })

function Body:load()
  -- The scene's one world: found by its type, and made when the scene has none.
  local world = onlr.scene.get("bump.world") or onlr.scene.add("World"):add("bump.world")
  self.world = world:get()
  self.x, self.y = self.object:toWorld(self.offset.x, self.offset.y)
  self.world:add(self, self.x, self.y, self.width, self.height)
end

-- Not called by the engine: scripts call it. The box goes as far as bump lets it,
-- and the object takes bump's answer.
function Body:move(x, y)
  local hits
  self.x, self.y, hits = self.world:move(self, x + self.offset.x, y + self.offset.y)
  self.object:setWorldPosition(self.x - self.offset.x, self.y - self.offset.y)
  for _, hit in ipairs(hits) do
    -- Calls contact(...) in each component of the object that defines it.
    self.object:send("contact", hit.other.object, hit.normal.x, hit.normal.y)
    hit.other.object:send("contact", self.object, -hit.normal.x, -hit.normal.y)
  end
end

-- The object's place is the truth, and bump's box is a copy.
-- When a script sets the object's place itself, tell bump.
function Body:update()
  local x, y = self.object:toWorld(self.offset.x, self.offset.y)
  if x ~= self.x or y ~= self.y then
    self.x, self.y = x, y
    self.world:update(self, x, y)
  end
end

function Body:destroy()
  self.world:remove(self)
end

-- For the editor: the rectangle that the component covers, in the object's own space.
function Body:bounds()
  return self.offset.x, self.offset.y, self.width, self.height
end

-- For the scene view: the box's outline, more visible when the object is chosen.
function Body:drawEditor(chosen)
  love.graphics.setColor(0, 1, 0, chosen and 1 or 0.4)
  love.graphics.rectangle("line", self.offset.x, self.offset.y, self.width, self.height)
end

return Body
