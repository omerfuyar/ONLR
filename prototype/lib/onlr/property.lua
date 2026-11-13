---@meta onlr.property

-- onlr.property: each function declares a property of a component type,
-- and its annotation says what the component reads.
-- When the engine loads a type, it puts each property's default in the declaration's place.
-- A component holds the values that its scene gives, and finds the others in its type.
-- A property cannot be named enabled, node or needs, or as a function of its type.

---@class onlr.PropertyOptions
---@field description? string shown in the inspector
---@field min? number for integer and number
---@field max? number
---@field choices? string[] for choice

---@class onlr.property
local property = {}

---@param default? boolean
---@param options? onlr.PropertyOptions
---@return boolean
function property.bool(default, options) end

---@param default? integer
---@param options? onlr.PropertyOptions
---@return integer
function property.integer(default, options) end

---@param default? number
---@param options? onlr.PropertyOptions
---@return number
function property.number(default, options) end

---@param default? string
---@param options? onlr.PropertyOptions
---@return string
function property.string(default, options) end

---@param default string one of options.choices
---@param options onlr.PropertyOptions
---@return string
function property.choice(default, options) end

---@param default? number[] red, green, blue and alpha, from 0 to 1
---@param options? onlr.PropertyOptions
---@return number[]
function property.color(default, options) end

---@param x? number
---@param y? number
---@param options? onlr.PropertyOptions
---@return {x: number, y: number}
function property.vector(x, y, options) end

---@param options? onlr.PropertyOptions
---@return love.Image?
function property.image(options) end

---@param options? onlr.PropertyOptions
---@return love.Source?
function property.sound(options) end

---@param options? onlr.PropertyOptions
---@return love.Font?
function property.font(options) end

---@param options? onlr.PropertyOptions
---@return string? path
function property.file(options) end

---@param options? onlr.PropertyOptions
---@return string? path a node file, for onlr.scene.load and onlr.scene.spawn
function property.nodeFile(options) end

---@param options? onlr.PropertyOptions
---@return onlr.Node? a node of the same file
function property.node(options) end

---@generic T
---@param fields T a table of properties
---@param options? onlr.PropertyOptions
---@return T
function property.group(fields, options) end

---@generic T
---@param item T a property
---@param options? onlr.PropertyOptions
---@return T[]
function property.list(item, options) end

return property
