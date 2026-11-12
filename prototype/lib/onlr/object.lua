---@meta

-- Objects and components, as a script sees them.

---@class onlr.Object
---@field name string
---@field x number in its parent, in pixels
---@field y number
---@field rotation number in radians, clockwise
---@field scaleX number
---@field scaleY number
---@field z number its order among its siblings
---@field active boolean
---@field parent onlr.Object?
---@field children onlr.Object[]
local Object = {}

---Gives the object's first component of a type.
---@generic T
---@param type `T`
---@return T?
function Object:get(type) end

---Gives the object a component, and returns it.
---@generic T
---@param type `T`
---@param values? table the properties' values
---@return T
function Object:add(type, values) end

---Calls the function of that name in each of the object's components that has it.
---@param name string
---@param ... any
function Object:send(name, ...) end

---Destroys the object and its children, when the current frame ends.
function Object:destroy() end

---Turns a point of the object's space into the world's.
---@return number x, number y
function Object:toWorld(x, y) end

---Turns a point of the world into the object's space.
---@return number x, number y
function Object:toLocal(x, y) end

---Moves the object to a point of the world, whatever its parents' places are.
function Object:setWorldPosition(x, y) end

---What every component has. A type also defines the functions it wants called:
---load(), update(dt), draw(), destroy(), any callback of LÖVE, bounds(), drawEditor(chosen).
---@class onlr.Component
---@field object onlr.Object
---@field enabled boolean
