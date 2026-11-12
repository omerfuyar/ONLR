---@meta onlr.scene

-- onlr.scene: the running scene.

---@class onlr.scene
local scene = {}

---Ends the running scene and loads another, when the current frame ends.
---@param path string a scene's file, such as "scenes/menu.scene.lua"
function scene.load(path) end

---Gives the first object of that name.
---@param name string
---@return onlr.Object?
function scene.find(name) end

---Gives the scene's first component of a type, in the tree's order.
---@generic T
---@param type `T` a component type, such as "bump.world"
---@return T?
function scene.get(type) end

---Makes an instance of a prefab in the running scene.
---@param prefab string a prefab's file
---@param x? number
---@param y? number
---@param parent? onlr.Object
---@return onlr.Object
function scene.spawn(prefab, x, y, parent) end

---Makes an empty object.
---@param name string
---@param parent? onlr.Object
---@return onlr.Object
function scene.add(name, parent) end

return scene
