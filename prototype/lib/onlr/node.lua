---@meta

-- Nodes and components, as a script sees them.

---@class onlr.Node
---@field name string
---@field x number in its parent, in pixels
---@field y number
---@field rotation number in radians, clockwise
---@field scaleX number
---@field scaleY number
---@field z number its order in drawing, added to its parent's
---@field active boolean
---@field parent onlr.Node?
---@field children onlr.Node[]
---@field components onlr.Components the node's components, by their types' names: node.components.bump.body
local Node = {}

---Gives the node a component of a type that it lacks, and returns it.
---The components that the type needs are added first. Its load is called before add returns.
---@generic T
---@param type `T` a type's name, dots and all: "bump.world"
---@param values? table the properties' values
---@return T
function Node:add(type, values) end

---Calls the function of that name in each of the node's components that has it.
---@param name string
---@param ... any
function Node:send(name, ...) end

---Marks the node. It and its children are destroyed when the current frame ends:
---destroy of the children's components is called, then of its own.
function Node:destroy() end

---Turns a point of the node's space into the world's.
---@return number x, number y
function Node:toWorld(x, y) end

---Turns a point of the world into the node's space.
---@return number x, number y
function Node:toLocal(x, y) end

---Moves the node to a point of the world, whatever its parents' places are.
function Node:setWorldPosition(x, y) end

---A node's components. The editor writes a field for each component type of the project
---into .onlr/, so a code editor knows what node.components.player is.
---In this prototype the fields are written here by hand.
---@class onlr.Components
---@field player? player
---@field coin? coin
---@field bump? {body: bump.body?, world: bump.world?}
---@field onlr? table the engine's own: sprite, text, shape and camera

---What every component has. A type also defines the functions it wants called:
---load(), update(dt), draw(), destroy(), any callback of LÖVE, bounds(), drawEditor(chosen),
---and names the types that it needs on its node: Type.needs = { "bump.body" }.
---A type does not inherit another: the colon in a type's annotation only tells a code editor
---that its components have these fields.
---@class onlr.Component
---@field node onlr.Node
---@field enabled boolean
