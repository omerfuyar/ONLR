---@meta

-- Nodes and components, as a script sees them.
-- A node's name, its place and its components are plain fields: node.posX = 10.
-- The engine does not watch them: it compares the place when it draws the node.
-- What the engine must act on when it changes is read and changed through functions,
-- as the values of LÖVE's own objects are: node:setActive(false) calls disable of the node's
-- components before it returns. So a change that does more than set a value is always a call.
-- A node file holds these values as plain fields: active, z and enabled.

---@class onlr.Node
---@field name string
---@field posX number its position in its parent, in pixels
---@field posY number
---@field rot number its angle in radians, clockwise
---@field sclX number its scale
---@field sclY number
---@field components onlr.Components the node's components, by their types' names: node.components.bump.body
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

---Whether the node runs: it and every node above it are active.
---@return boolean
function Node:isActive() end

---Turns the node, with all under it, on or off, at once:
---enable or disable of the components that start or stop is called before it returns.
---@param active boolean
function Node:setActive(active) end

---The node's order in drawing, added to its parent's.
---@return number
function Node:getZ() end

---Changes the node's z. The frame's next draw uses it.
---@param z number
function Node:setZ(z) end

---The node's parent: nil for the root and for a kept node.
---@return onlr.Node?
function Node:getParent() end

---The node's children, in their order. The list is the engine's own: read it, do not change it.
---@return onlr.Node[]
function Node:getChildren() end

---Moves the node, with all that is under it, to the end of another node's children, or to index among them.
---It keeps its own place, so it moves with its new parent; setWorldPosition after keeps it where it is.
---Components that it starts or stops get enable or disable at once.
---A node of the root that is moved under a kept node stays when the root changes.
---@param parent onlr.Node not the node itself, nor one under it
---@param index? integer
function Node:setParent(parent, index) end

---Marks the node and every node under it: their isDestroyed() is true from now on.
---They are destroyed when the current frame ends: disable and destroy of the children's components
---are called, then of its own.
function Node:destroy() end

---Whether node:destroy() was called on the node or on one above it,
---so a component that holds the node knows that it is gone.
---@return boolean
function Node:isDestroyed() end

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
---@field music? music
---@field bump {body: bump.body?, world: bump.world?}
---@field onlr {sprite: onlr.sprite?, text: onlr.text?, shape: onlr.shape?, camera: onlr.camera?}

---What every component has. A type also defines the functions it wants called, here in the order
---of a component's life: load(), enable(), start(), then each frame any callback of LÖVE,
---fixedUpdate(dt), update(dt), lateUpdate(dt) and draw(), and at its end disable() and destroy().
---For the editor: bounds() and drawEditor(chosen).
---A type names the types that it needs on its node: Type.needs = { "bump.body" }.
---Its properties are plain fields, which other components read and set too: other.components.coin.worth.
---A type does not inherit another: the colon in a type's annotation only tells a code editor
---that its components have these fields.
---@class onlr.Component
---@field node onlr.Node
local Component = {}

---Whether the component is on. It runs when it is on and its node is active.
---@return boolean
function Component:isEnabled() end

---Turns the component on or off, at once: enable or disable is called before it returns.
---The engine gives every type this function.
---@param enabled boolean
function Component:setEnabled(enabled) end
