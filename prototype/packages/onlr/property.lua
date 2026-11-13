---@meta onlr.property

-- onlr.property: each function declares a property of a component type,
-- and its annotation says what the component reads.
-- When the engine loads a type, it puts each property's default in the declaration's place.
-- A component holds the values that its node file gives, and finds the others in its type.
-- A property cannot be named enabled, node or needs, or as a function of its type.
-- Each function takes the default, then a table of options; the options of each kind are below.

---The options that every kind takes. An option that a kind does not take is an error when the type loads.
---@class onlr.PropertyOptions
---@field description? string shown in the inspector with the property
---@field label? string shown in place of the name. Without it, cellSize shows as "Cell size".

---@class onlr.NumberOptions : onlr.PropertyOptions
---@field min? number the least value; the inspector keeps the value between min and max
---@field max? number the most value

---@class onlr.ChoiceOptions : onlr.PropertyOptions
---@field choices string[] the texts to choose from

---@class onlr.SoundOptions : onlr.PropertyOptions
---@field stream? boolean LÖVE streams the file while it plays, as music needs, and does not decode it whole

---@class onlr.FontOptions : onlr.PropertyOptions
---@field size? number the size that the property starts with; 12, LÖVE's own, when left out

---@class onlr.FileOptions : onlr.PropertyOptions
---@field extensions? string[] the endings of the files that the inspector offers, such as { "json", "lua" }

---@class onlr.NodeFileOptions : onlr.PropertyOptions
---@field preload? boolean the node file, and the files that it names, load with the component's own node file,
---so a spawn of it reads nothing from disk

---@class onlr.property
local property = {}

---@param default? boolean
---@param options? onlr.PropertyOptions
---@return boolean
function property.bool(default, options) end

---@param default? integer
---@param options? onlr.NumberOptions
---@return integer
function property.integer(default, options) end

---@param default? number
---@param options? onlr.NumberOptions
---@return number
function property.number(default, options) end

---@param default? string
---@param options? onlr.PropertyOptions
---@return string
function property.string(default, options) end

---@param default string one of options.choices
---@param options onlr.ChoiceOptions
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

---@param options? onlr.SoundOptions
---@return love.Source?
function property.sound(options) end

---A node file keeps it as { path = "fonts/main.ttf", size = 16 }. Without a path, LÖVE's default font.
---@param options? onlr.FontOptions
---@return love.Font
function property.font(options) end

---@param options? onlr.FileOptions
---@return string? path
function property.file(options) end

---@param options? onlr.NodeFileOptions
---@return string? path a node file, for onlr.tree.loadRoot and onlr.tree.spawn
function property.nodeFile(options) end

---@param options? onlr.PropertyOptions
---@return onlr.Node? a node of the same file
function property.node(options) end

---A node of the same file that has a component of the type. A node file keeps the node's id.
---@generic T
---@param type `T` a type's name, dots and all: "bump.body"
---@param options? onlr.PropertyOptions
---@return T?
function property.component(type, options) end

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
