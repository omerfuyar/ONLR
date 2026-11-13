---@meta onlr.tree

-- onlr.node: the root, which is the node that the game runs, and the tree under it.

---@class onlr.node
---@field root onlr.Node the root: the node of the node file that was loaded last
local node = {}

---Ends the root and loads another node file as the root, when the current frame ends.
---@param path string a node file, such as "nodes/menu.lua"
function node.loadRoot(path) end

---Gives the tree's first node of that name.
---@param name string
---@return onlr.Node?
function node.find(name) end

---Gives the tree's first component of a type, in the tree's order, the root's first.
---@generic T
---@param type `T` a type's name, dots and all: "bump.world"
---@return T?
function node.findComponent(type) end

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
