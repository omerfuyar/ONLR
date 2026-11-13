---@meta bump

-- The library's definitions, named as the package. A code editor reads them, and the game never does.
-- They are written with the package, since bump ships none: the functions that the package's components use.

---@class bump.World
local World = {}

---Adds an item to the world, as a box.
---@param item any
---@param x number
---@param y number
---@param w number
---@param h number
function World:add(item, x, y, w, h) end

---Takes an item out of the world.
---@param item any
function World:remove(item) end

---Moves an item to a place, without checking what it hits.
---@param item any
---@param x number
---@param y number
function World:update(item, x, y) end

---Whether an item is in the world.
---@param item any
---@return boolean
function World:hasItem(item) end

---Moves an item toward a place, and stops it where it hits another.
---@param item any
---@param goalX number
---@param goalY number
---@param filter? fun(item: any, other: any): string|false what happens when it meets another: "slide", "cross", "touch" or "bounce"
---@return number actualX, number actualY, table[] collisions, integer count
function World:move(item, goalX, goalY, filter) end

---@class bump
local bump = {}

---Makes a world, whose cells are cellSize pixels wide.
---@param cellSize? number
---@return bump.World
function bump.newWorld(cellSize) end

return bump
