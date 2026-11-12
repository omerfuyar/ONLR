---@meta onlr

-- The engine, as definitions only: every function and file format of DESIGN.md, without code.
-- In a real project this folder holds the engine itself, and these annotations are in its source.

---@class onlr
local onlr = {}

-- Starting ------------------------------------------------------------------

---Starts the engine. Called from main.lua.
function onlr.start() end

---Sets LÖVE's settings from the project file. Called from conf.lua.
---@param t table what love.conf gets
function onlr.conf(t) end

-- The running scene ---------------------------------------------------------

---@class onlr.scene
onlr.scene = {}

---Ends the running scene and loads another, when the current frame ends.
---@param path string a scene's file, such as "scenes/menu.scene.lua"
function onlr.scene.load(path) end

---Gives the first object of that name.
---@param name string
---@return onlr.Object?
function onlr.scene.find(name) end

---Gives the scene's first component of a type, in the tree's order.
---@generic T
---@param type `T` a component type, such as "bump.world"
---@return T?
function onlr.scene.get(type) end

---Makes an instance of a prefab in the running scene.
---@param prefab string a prefab's file
---@param x? number
---@param y? number
---@param parent? onlr.Object
---@return onlr.Object
function onlr.scene.spawn(prefab, x, y, parent) end

---Makes an empty object.
---@param name string
---@param parent? onlr.Object
---@return onlr.Object
function onlr.scene.add(name, parent) end

-- Objects -------------------------------------------------------------------

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

-- Components ----------------------------------------------------------------

---What every component has. A type also defines the functions it wants called:
---load(), update(dt), draw(), destroy(), any callback of LÖVE, bounds(), drawEditor(chosen).
---@class onlr.Component
---@field object onlr.Object
---@field enabled boolean

-- Properties ----------------------------------------------------------------

---@class onlr.PropertyOptions
---@field description? string shown in the inspector
---@field min? number for integer and number
---@field max? number
---@field choices? string[] for choice

---Each function declares a property, and its annotation says what the component reads.
---@class onlr.property
onlr.property = {}

---@return boolean
function onlr.property.bool(default, options) end
---@return integer
function onlr.property.integer(default, options) end
---@return number
function onlr.property.number(default, options) end
---@return string
function onlr.property.string(default, options) end
---@return string
function onlr.property.choice(default, options) end
---@return number[] red, green, blue and alpha, from 0 to 1
function onlr.property.color(default, options) end
---@return {x: number, y: number}
function onlr.property.vector(x, y, options) end
---@return love.Image?
function onlr.property.image(options) end
---@return love.Source?
function onlr.property.sound(options) end
---@return love.Font?
function onlr.property.font(options) end
---@return string? a path
function onlr.property.file(options) end
---@return string? a scene's path
function onlr.property.scene(options) end
---@return string? a prefab's path
function onlr.property.prefab(options) end
---@return onlr.Object?
function onlr.property.object(options) end
---@generic T
---@param fields T a table of properties
---@return T
function onlr.property.group(fields, options) end
---@generic T
---@param item T a property
---@return T[]
function onlr.property.list(item, options) end

-- File formats --------------------------------------------------------------

---@class onlr.Project
---@field format integer
---@field name string
---@field id string
---@field version string
---@field love string
---@field engine string
---@field scene string
---@field width integer
---@field height integer
---@field exclude? string[]

---@class onlr.ComponentData
---@field type string a component type, as require takes it
---@field [string] any the properties' values

---@class onlr.ObjectData
---@field id string
---@field name string
---@field x? number
---@field y? number
---@field rotation? number
---@field scaleX? number
---@field scaleY? number
---@field z? number
---@field active? boolean
---@field components? onlr.ComponentData[]
---@field children? onlr.ObjectData[]
---@field prefab? string
---@field overrides? table

---@class onlr.Scene
---@field format integer
---@field objects onlr.ObjectData[]

---@class onlr.Prefab : onlr.ObjectData
---@field format integer

---@class onlr.Pack
---@field format integer
---@field name string
---@field description string
---@field version string
---@field source string
---@field license string
---@field components string[]

return onlr
