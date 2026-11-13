---@meta onlr.scene

-- onlr.scene: the running scene.

---@class onlr.scene
---@field root onlr.Object the root of the running scene: the object that the scene's file returns
local scene = {}

---Ends the running scene and loads another, when the current frame ends.
---@param path string a scene's file, such as "scenes/menu.scene.lua"
function scene.load(path) end

---Gives the first object of that name.
---@param name string
---@return onlr.Object?
function scene.find(name) end

---Gives the scene's first component of a type, in the tree's order, the root's first.
---@generic T
---@param type `T` a component type, such as "bump.world"
---@return T?
function scene.get(type) end

---Makes an instance of a scene in the running scene, and returns it.
---It exists at once, and load of its components is called before spawn returns.
---@param path string a scene's file, such as "scenes/coin.scene.lua"
---@param x? number in its parent
---@param y? number
---@param parent? onlr.Object the root when left out
---@return onlr.Object
function scene.spawn(path, x, y, parent) end

---Makes an empty object, and returns it.
---@param name string
---@param parent? onlr.Object the root when left out
---@return onlr.Object
function scene.add(name, parent) end

return scene
