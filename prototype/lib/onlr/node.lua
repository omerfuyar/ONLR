---@meta

-- Nodes and components, as a script sees them.
-- A script reads and sets their fields as plain fields: node.posX = 10, node.active = false.
-- The engine sees a write to four of them, since they change which functions run or their order:
-- a node's active, z and parent, and a component's enabled. It acts at once:
-- node.active = false calls disable of the node's components before the assignment returns.
-- The place, posX to sclY, is not watched: the engine compares it when it draws the node.

---@class onlr.Node
---@field name string
---@field posX number its position in its parent, in pixels
---@field posY number
---@field rot number its angle in radians, clockwise
---@field sclX number its scale
---@field sclY number
---@field z number its order in drawing, added to its parent's. The next draw uses a new one.
---@field active boolean whether it and its children run. Setting it acts at once.
---@field parent onlr.Node? read only: node:setParent moves the node. nil for the root.
---@field children onlr.Node[] read only: node:setParent, onlr.node.add and onlr.node.spawn change it
---@field components onlr.Components the node's components, by their types' names: node.components.bump.body
---@field destroyed boolean read only: true from node:destroy() on, so whoever holds the node knows it is gone
local Node = {}

---Gives the node a component of a type that it lacks, and returns it.
---Giving it a second of a type is an error. The components that the type needs are added first.
---Its load and enable are called before add returns.
---@generic T
---@param type `T` a type's name, dots and all: "bump.world"
---@param values? table the properties' values
---@return T
function Node:add(type, values) end

---Calls the function of that name in each of the node's components that has it.
---@param name string
---@param ... any
function Node:send(name, ...) end

---Moves the node, with all that is under it, to the end of another node's children, or to index among them.
---It keeps its own place, so it moves with its new parent; setWorldPosition after keeps it where it is.
---Components that it starts or stops get enable or disable at once.
---@param parent onlr.Node not the node itself, nor one under it
---@param index? integer
function Node:setParent(parent, index) end

---Marks the node and every node under it: their destroyed is true from now on.
---They are destroyed when the current frame ends: disable and destroy of the children's components
---are called, then of its own.
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
---In the game, onlr and bump are always tables, empty on a node without their types:
---node.components.bump.body is nil on a node without a body, and components.bmup.body is an error.
---@class onlr.Components
---@field player? player
---@field coin? coin
---@field spin? spin
---@field bump {body: bump.body?, world: bump.world?}
---@field onlr {sprite: onlr.sprite?, text: onlr.text?, shape: onlr.shape?, camera: onlr.camera?}

---What every component has. A type also defines the functions it wants called, here in the order
---of a component's life: load(), enable(), start(), then each frame any callback of LÖVE,
---update(dt), lateUpdate(dt) and draw(), and at its end disable() and destroy().
---For the editor: bounds() and drawEditor(chosen).
---A type names the types that it needs on its node: Type.needs = { "bump.body" }.
---A type does not inherit another: the colon in a type's annotation only tells a code editor
---that its components have these fields.
---@class onlr.Component
---@field node onlr.Node
---@field enabled boolean whether it runs. Setting it acts at once: enable or disable is called before it returns.
