---@meta onlr.scene

-- onlr.scene: the scene, which is the node that the game runs, with all that is under it.

---@class onlr.scene
---@field root onlr.Node the scene's root: the node of the node file that was loaded
local scene = {}

---Ends the scene and makes another node file the scene, when the current frame ends.
---@param path string a node file, such as "nodes/menu.lua"
function scene.load(path) end

---Gives the scene's first node of that name.
---@param name string
---@return onlr.Node?
function scene.find(name) end

---Gives the scene's first component of a type, in the tree's order, the root's first.
---@generic T
---@param type `T` a type's name, dots and all: "bump.world"
---@return T?
function scene.get(type) end

---Makes an instance of a node file in the scene, and returns it.
---It exists at once, and load of its components is called before spawn returns.
---@param path string a node file, such as "nodes/coin.lua"
---@param x? number in its parent
---@param y? number
---@param parent? onlr.Node the root when left out
---@return onlr.Node
function scene.spawn(path, x, y, parent) end

---Makes an empty node, and returns it.
---@param name string
---@param parent? onlr.Node the root when left out
---@return onlr.Node
function scene.add(name, parent) end

return scene
