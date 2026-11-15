-- onlr.property: each function declares a property of a component type (DESIGN 6.2),
-- and its annotation says what the component reads.
-- When the engine loads a type, it puts each property's default in the declaration's place.
-- A component holds the values that its node file gives, and finds the others in its type.
-- Each function takes the default, then a table of options. A kind that names a file, a node or a component
-- has no default and takes the options only.
-- This file also turns a node file's values into what a component gets, such as a path into a LÖVE image.

local data = require("onlr.data")

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

---A declaration, as the engine keeps it, and as the edit player sends it to the editor (DESIGN 12.5).
---@class onlr.Declaration
---@field kind string the function's name, such as "number"
---@field default any the default value, as a node file holds it
---@field options table the options
---@field order integer the order of declaration
---@field fields? table<string, onlr.Declaration> a group's properties
---@field item? onlr.Declaration a list's property
---@field type? string a component property's type

---@class onlr.property
local property = {}

local Declaration = {}
Declaration.__index = Declaration

local count = 0

-- The kinds that take each option.
local TAKEN = {
  description = true,
  label = true,
  min = { integer = true, number = true },
  max = { integer = true, number = true },
  choices = { choice = true },
  stream = { sound = true },
  size = { font = true },
  extensions = { file = true },
  preload = { nodeFile = true },
}

-- The kinds that name something else of the project (DESIGN 6.2).
property.REFERENCES = { image = true, sound = true, font = true, file = true, nodeFile = true, node = true, component = true }

local function fail(message)
  error(message, 4)
end

---@return any
local function declare(kind, default, options, extra)
  if options ~= nil and type(options) ~= "table" then
    fail(("the options of a %s are a table"):format(kind))
  end
  options = options or {}
  for name in pairs(options) do
    local kinds = TAKEN[name]
    if kinds ~= true and not (kinds and kinds[kind]) then
      fail(("a %s takes no option %s"):format(kind, tostring(name)))
    end
  end
  count = count + 1
  local d = setmetatable({ kind = kind, default = default, options = options, order = count }, Declaration)
  for k, v in pairs(extra or {}) do
    d[k] = v
  end
  return d
end

local function expect(kind, value, luaType)
  if value ~= nil and type(value) ~= luaType then
    fail(("the default of a %s is a %s"):format(kind, luaType))
  end
end

---Whether a value is a declaration, which a type's field holds before the engine loads the type.
---@param value any
---@return boolean
function property.isDeclaration(value)
  return getmetatable(value) == Declaration
end

---@param default? boolean false when left out
---@param options? onlr.PropertyOptions
---@return boolean
function property.bool(default, options)
  expect("bool", default, "boolean")
  return declare("bool", default or false, options)
end

---@param default? integer 0 when left out
---@param options? onlr.NumberOptions
---@return integer
function property.integer(default, options)
  expect("integer", default, "number")
  if default and default ~= math.floor(default) then
    fail("the default of an integer is a whole number")
  end
  return declare("integer", default or 0, options)
end

---@param default? number 0 when left out
---@param options? onlr.NumberOptions
---@return number
function property.number(default, options)
  expect("number", default, "number")
  return declare("number", default or 0, options)
end

---@param default? string empty when left out
---@param options? onlr.PropertyOptions
---@return string
function property.string(default, options)
  expect("string", default, "string")
  return declare("string", default or "", options)
end

---@param default? string one of options.choices; the first when left out
---@param options onlr.ChoiceOptions
---@return string
function property.choice(default, options)
  if type(options) ~= "table" or type(options.choices) ~= "table" or #options.choices == 0 then
    fail("a choice needs its choices")
  end
  default = default or options.choices[1]
  local found = false
  for _, choice in ipairs(options.choices) do
    found = found or choice == default
  end
  if not found then
    fail(("the default %s is not one of the choices"):format(tostring(default)))
  end
  return declare("choice", default, options)
end

---A colour: red, green, blue and alpha, from 0 to 1, as love.graphics.setColor takes it. A node file keeps it as a list of four numbers.
---@param default? number[] white when left out
---@param options? onlr.PropertyOptions
---@return number[]
function property.color(default, options)
  default = default or { 1, 1, 1, 1 }
  if type(default) ~= "table" or #default < 3 then
    fail("the default of a color is a list of red, green, blue and alpha")
  end
  return declare("color", { default[1], default[2], default[3], default[4] or 1 }, options)
end

---Two numbers. A node file keeps them as { x = 1, y = 2 }, and the component gets the same.
---@param x? number 0 when left out
---@param y? number 0 when left out
---@param options? onlr.PropertyOptions
---@return {x: number, y: number}
function property.vector(x, y, options)
  expect("vector", x, "number")
  expect("vector", y, "number")
  return declare("vector", { x = x or 0, y = y or 0 }, options)
end

---An image file of the project. The component gets a LÖVE image, which every component that names the file shares.
---@param options? onlr.PropertyOptions
---@return love.Image?
function property.image(options)
  return declare("image", nil, options)
end

---A sound file of the project. Each component gets a LÖVE source of its own, so two can play at once.
---@param options? onlr.SoundOptions
---@return love.Source?
function property.sound(options)
  return declare("sound", nil, options)
end

---A font file and a size. A node file keeps it as { path = "fonts/main.ttf", size = 16 }.
---Without a path, the component gets LÖVE's default font at that size.
---@param options? onlr.FontOptions
---@return love.Font
function property.font(options)
  if options and options.size ~= nil and type(options.size) ~= "number" then
    fail("the size of a font is a number")
  end
  return declare("font", nil, options)
end

---A file of the project. The component gets its path.
---@param options? onlr.FileOptions
---@return string? path
function property.file(options)
  return declare("file", nil, options)
end

---A node file of the project. The component gets its path, for onlr.tree.loadRoot and onlr.tree.spawn.
---@param options? onlr.NodeFileOptions
---@return string? path
function property.nodeFile(options)
  return declare("nodeFile", nil, options)
end

---A node of the same file. A node file keeps its id, or a path of ids inside an instance (DESIGN 9).
---@param options? onlr.PropertyOptions
---@return onlr.Node?
function property.node(options)
  return declare("node", nil, options)
end

---A node of the same file that has a component of the type. The component gets that component.
---@generic T
---@param type `T` a type's name, dots and all: "bump.body"
---@param options? onlr.PropertyOptions
---@return T?
function property.component(type, options)
  if _G.type(type) ~= "string" then
    fail("a component property names its type")
  end
  return declare("component", nil, options, { type = type })
end

---Properties under one heading. The component gets a table with a field for each: self.box.width.
---A node file keeps the fields that differ from their defaults, and an instance's change lays them over field by field.
---@generic T
---@param fields T a table of properties
---@param options? onlr.PropertyOptions
---@return T
function property.group(fields, options)
  if type(fields) ~= "table" then
    fail("a group holds a table of properties")
  end
  local default = {}
  for name, field in pairs(fields) do
    if not property.isDeclaration(field) then
      fail(("the field %s of a group is not a property"):format(tostring(name)))
    end
    default[name] = field.default
  end
  return declare("group", default, options, { fields = fields })
end

---Rows of one kind, which the user adds and removes. The component gets a list: self.frames[1].
---@generic T
---@param item T a property
---@param options? onlr.PropertyOptions
---@return T[]
function property.list(item, options)
  if not property.isDeclaration(item) then
    fail("a list holds one property")
  end
  return declare("list", {}, options, { item = item })
end

-- Turning a node file's values into a component's.

---What a conversion needs: where the value is, to name it in an error, and what to do with what it loads.
---@class onlr.ValueContext
---@field file string the node file
---@field node string the node's name
---@field holds string[] the keys of the files that the component holds
---@field lenient boolean? in the node view: a missing file gives nil, and is noted in errors
---@field errors string[]? the problems found, when lenient
---@field preload fun(path: string)? loads a preloaded node file, with the files that it names

local function copyValue(value)
  if type(value) ~= "table" then
    return value
  end
  local c = {}
  for k, v in pairs(value) do
    c[k] = copyValue(v)
  end
  return c
end
property.copy = copyValue

local LUA_TYPES = {
  bool = "boolean", integer = "number", number = "number", string = "string", choice = "string",
  color = "table", vector = "table", list = "table", group = "table",
}

local function problem(ctx, name, message)
  local text = ("%s, node %s, property %s: %s"):format(ctx.file, ctx.node, name, message)
  if ctx.lenient then
    ctx.errors = ctx.errors or {}
    ctx.errors[#ctx.errors + 1] = text
    return
  end
  error(text, 0)
end

---Loads a file for a component, and holds it in the component's name.
---@param ctx onlr.ValueContext
---@param name string the property's name, for errors
---@param kind "image"|"font"|"sound"|"node"
---@param path string?
---@param option any
---@return any
function property.load(ctx, name, kind, path, option)
  local ok, value, key = pcall(data.load, kind, path, option)
  if not ok then
    problem(ctx, name, value)
    return nil
  end
  data.hold(key)
  ctx.holds[#ctx.holds + 1] = key
  return value
end

---Turns one value of a node file into what the component gets. A node or a component is found through resolve.
---@param decl onlr.Declaration
---@param value any as the node file holds it
---@param ctx onlr.ValueContext
---@param name string the property's name, for errors
---@param resolve fun(id: string): onlr.Node? finds a node by an id of the file that wrote the value
---@return any
function property.convert(decl, value, ctx, name, resolve)
  local kind = decl.kind
  local luaType = LUA_TYPES[kind]
  if luaType and type(value) ~= luaType then
    problem(ctx, name, ("a %s, not a %s"):format(kind, type(value)))
    return copyValue(decl.default)
  end
  if kind == "list" then
    local list = {}
    for i, item in ipairs(value) do
      list[i] = property.convert(decl.item, item, ctx, name .. "[" .. i .. "]", resolve)
    end
    return list
  elseif kind == "group" then
    local group = copyValue(decl.default)
    for field, fieldDecl in pairs(decl.fields) do
      if value[field] ~= nil then
        group[field] = property.convert(fieldDecl, value[field], ctx, name .. "." .. field, resolve)
      else
        group[field] = property.convert(fieldDecl, fieldDecl.default, ctx, name .. "." .. field, resolve)
      end
    end
    return group
  elseif kind == "color" or kind == "vector" then
    return copyValue(value)
  elseif kind == "image" then
    return value and property.load(ctx, name, "image", value)
  elseif kind == "sound" then
    local source = value and property.load(ctx, name, "sound", value, decl.options.stream or false)
    if not source then
      return nil
    end
    local clone = source:clone()
    data.paths[clone] = value
    return clone
  elseif kind == "font" then
    local path, size = nil, decl.options.size or 12
    if type(value) == "table" then
      path, size = value.path, value.size or size
    end
    return property.load(ctx, name, "font", path, size)
  elseif kind == "file" or kind == "nodeFile" then
    if value == nil then
      return nil
    end
    if not data.exists(value) then
      problem(ctx, name, tostring(value) .. ": no such file")
      return nil
    end
    if kind == "nodeFile" and decl.options.preload and ctx.preload then
      ctx.preload(value)
    end
    return value
  elseif kind == "node" or kind == "component" then
    if value == nil then
      return nil
    end
    local target = resolve(value)
    if not target then
      problem(ctx, name, ("the id %s names no node"):format(tostring(value)))
      return nil
    end
    if kind == "node" then
      return target
    end
    local c = target._byType[decl.type]
    if not c then
      problem(ctx, name, ("the node %s has no %s"):format(tostring(value), decl.type))
    end
    return c
  end
  return value
end

---The value of one property from layers of values, each laid over the one before: a node file's own,
---then each change of an instance (DESIGN 9). A group is laid over field by field; any other value is replaced whole.
---Gives nil when no layer holds the property and its default is not a table, so the component finds the default in its type.
---@param decl onlr.Declaration
---@param layers {value: any, resolve: fun(id: string): onlr.Node?}[]
---@param ctx onlr.ValueContext
---@param name string
---@return any value
---@return boolean set whether the component holds a value of its own
function property.merge(decl, layers, ctx, name)
  if decl.kind == "group" then
    local group = {}
    for field, fieldDecl in pairs(decl.fields) do
      local fieldLayers = {}
      for _, layer in ipairs(layers) do
        if type(layer.value) == "table" and layer.value[field] ~= nil then
          fieldLayers[#fieldLayers + 1] = { value = layer.value[field], resolve = layer.resolve }
        end
      end
      local value, set = property.merge(fieldDecl, fieldLayers, ctx, name .. "." .. field)
      if set then
        group[field] = value
      else
        group[field] = copyValue(fieldDecl.default)
      end
    end
    return group, true
  end
  local last = layers[#layers]
  if last then
    return property.convert(decl, last.value, ctx, name, last.resolve), true
  end
  if decl.kind == "font" then
    return property.convert(decl, nil, ctx, name, function() return nil end), true
  end
  if type(decl.default) == "table" then
    return copyValue(decl.default), true
  end
  return nil, false
end

return property
