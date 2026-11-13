---@meta onlr.tree

-- onlr.node: the root, which is the node that the game runs, and the tree.
-- The tree is the kept nodes, which the manifest names and the game keeps, and the root,
-- with all under them. Its order is the kept nodes', in the manifest's order, then the root's.

---@class onlr.node
---@field root onlr.Node the root: the node of the node file that was loaded last
local node = {}

---Ends the root and loads another node file as the root, when the current frame ends.
---The kept nodes stay.
---@param path string a node file, such as "nodes/menu.lua"
function node.loadRoot(path) end

---Gives the tree's first node of that name, in the tree's order.
---@param name string
---@return onlr.Node?
function node.find(name) end

---Gives the tree's first component of a type, in the tree's order.
---@generic T
---@param type `T` a type's name, dots and all: "bump.world"
---@return T?
function node.findComponent(type) end

---Gives a list of the tree's nodes of that name, in the tree's order.
---@param name string
---@return onlr.Node[]
function node.findAll(name) end

---Gives a list of the tree's components of a type, in the tree's order.
---A component type is a tag: an empty script enemy on every enemy, and findAllComponents("enemy").
---@generic T
---@param type `T`
---@return T[]
function node.findAllComponents(type) end

---Makes an instance of a node file in the tree, and returns it.
---It exists at once: load and enable of its components are called before spawn returns.
---Their start is called in the next frame, so it finds the values that the script sets after spawn.
---@param path string a node file, such as "nodes/coin.lua"
---@param x? number in its parent
---@param y? number
---@param parent? onlr.Node the root when left out
---@return onlr.Node
function node.spawn(path, x, y, parent) end

---Makes an empty node, and returns it.
---@param name string
---@param parent? onlr.Node the root when left out
---@return onlr.Node
function node.add(name, parent) end

return node
