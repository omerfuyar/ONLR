-- Making nodes from node files (DESIGN 5 and 9): plain nodes, instances with their changes, and variants.
-- It works in steps. First it makes every node, and notes for each component the values that the file
-- and each change of an instance give it. Then it makes every component, and then gives them their values,
-- so a property that names a node finds it, wherever in the file that node is.
---@diagnostic disable: invisible -- the engine reads the fields of its nodes that a script does not see

local data = require("onlr.library.data")
local life = require("onlr.library.life")
local component = require("onlr.library.component")
local property = require("onlr.library.property")
local nodes = require("onlr.library.node")
local instances = require("onlr.library.instances")

local build = {}

---What one build shares.
---@class onlr.BuildContext
---@field lenient boolean? in the node view: a problem is noted on its node, and the rest is made
---@field todo onlr.Node[] the nodes whose components wait for the next steps

local FIELDS = { "name", "posX", "posY", "rot", "sclX", "sclY" }

local function note(node, ctx, message)
  if ctx.lenient then
    node._errors = node._errors or {}
    node._errors[#node._errors + 1] = message
    return
  end
  error(message, 0)
end

-- Lays the fields of a node's entry, or of a change, over a node, and notes its components' values.
local function lay(node, entry, scope)
  for _, field in ipairs(FIELDS) do
    if entry[field] ~= nil then
      node[field] = entry[field]
    end
  end
  if entry.z ~= nil then
    node._z = entry.z
  end
  if entry.active ~= nil then
    node._active = entry.active and true or false
  end
  if entry.componentOrder ~= nil then
    node._componentOrder = entry.componentOrder
  end
  if entry.components ~= nil then
    node._layers[#node._layers + 1] = { components = entry.components, scope = scope }
  end
end

-- The engine's maker of nodes for the walk over a file's instances (instances.lua): nodes with their fields, whose components
-- wait in ctx.todo for the next steps.
---@param ctx onlr.BuildContext
---@return onlr.Maker
local function maker(ctx)
  return {
    file = function(path)
      return data.load("node", path)
    end,
    node = function(entry, scope)
      local node = nodes.new(entry.name)
      node._id = entry.id
      node._path = scope.prefix .. entry.id
      node._layers = {}
      node._file = scope.file
      ctx.todo[#ctx.todo + 1] = node
      return node
    end,
    lay = lay,
    attach = nodes.attach,
    first = function(node, path)
      node._path = path
    end,
    instance = function(node, entry, scope, unused)
      for _, key in ipairs(unused) do
        note(node, ctx, ("%s: the instance %s changes %s, which names no node"):format(scope.file, entry.id, tostring(key)))
      end
    end,
  }
end

-- Splits a node file's components, tables in tables by the dots of their names, into entries by type name.
local function flatten(components, space, prefix, out, node, ctx, file)
  for key, value in pairs(components) do
    local entry = space.names[key]
    if type(value) ~= "table" then
      note(node, ctx, ("%s, node %s: the component %s%s is not a table"):format(file, node.name, prefix, tostring(key)))
    elseif type(entry) == "table" then
      flatten(value, entry, prefix .. key .. ".", out, node, ctx, file)
    elseif entry == true then
      out[prefix .. key] = value
    elseif type(entry) == "string" then
      note(node, ctx, ("%s, node %s: %s"):format(file, node.name, entry))
    else
      note(node, ctx, ("%s, node %s: no component type %s%s"):format(file, node.name, prefix, tostring(key)))
    end
  end
end

-- Loads the files that a node file's values name, without making its nodes, and holds them in a component's name:
-- what a nodeFile property with preload asks for (DESIGN 6.2).
local function preload(path, ctx, name, seen)
  if seen[path] then
    return
  end
  seen[path] = true
  local fileData = property.load(ctx, name, "node", path)
  if not fileData then
    return
  end
  local function values(decl, value)
    local kind = decl.kind
    if kind == "list" and type(value) == "table" then
      for _, item in ipairs(value) do
        values(decl.item, item)
      end
    elseif kind == "group" and type(value) == "table" then
      for field, fieldDecl in pairs(decl.fields) do
        values(fieldDecl, value[field])
      end
    elseif kind == "image" and value then
      property.load(ctx, name, "image", value)
    elseif kind == "sound" and value then
      local path, stream = property.soundOf(decl, value)
      if path then
        property.load(ctx, name, "sound", path, stream)
      end
    elseif kind == "font" then
      property.load(ctx, name, "font", type(value) == "table" and value.path or nil,
        type(value) == "table" and value.size or decl.options.size or 12)
    elseif kind == "shader" and value then
      property.load(ctx, name, "shader", value)
    elseif kind == "values" and type(value) == "table" then
      -- a text among a shader's values is an image's path
      for _, item in pairs(value) do
        if type(item) == "string" then
          property.load(ctx, name, "image", item)
        end
      end
    elseif kind == "nodeFile" and value and decl.options.preload then
      preload(value, ctx, name, seen)
    end
  end
  local function entries(entry)
    if type(entry.instance) == "table" then
      preload(entry.instance.base, ctx, name, seen)
      for _, change in pairs(entry.instance.changes or {}) do
        entries(change)
      end
    end
    local flat = {}
    pcall(flatten, entry.components or {}, component.space(), "", flat, {}, { lenient = true }, path)
    for typeName, held in pairs(flat) do
      local ok, info = pcall(component.type, typeName)
      if ok then
        for _, p in ipairs(info.properties) do
          values(p.decl, held[p.name])
        end
      end
    end
    for _, child in ipairs(entry.children or {}) do
      entries(child)
    end
  end
  entries(fileData)
end

-- The second step: makes a node's components, with those that they need. Their values wait for the third step,
-- since a property may name a component of a node that comes later.
local function make(node, ctx)
  local layers = node._layers
  node._layers = nil
  -- For each type, the values that each layer gives it, the file's own first.
  local byType, order = {}, {}
  for _, layer in ipairs(layers) do
    local flat = {}
    flatten(layer.components, component.space(), "", flat, node, ctx, layer.scope.file)
    for name, values in pairs(flat) do
      if not byType[name] then
        byType[name] = {}
        order[#order + 1] = name
      end
      local scope = layer.scope
      byType[name][#byType[name] + 1] = {
        values = values,
        resolve = function(id)
          return scope.nodes[id]
        end,
      }
    end
  end
  table.sort(order)

  local names = {}
  for _, name in ipairs(order) do
    local ok, err = pcall(component.type, name)
    if ok then
      names[#names + 1] = name
    else
      note(node, ctx, ("%s, node %s: %s"):format(node._file, node.name, tostring(err)))
    end
  end
  for _, need in ipairs(component.missingNeeds(node, names)) do
    names[#names + 1] = need
    byType[need] = {}
  end

  for _, name in ipairs(names) do
    component.make(node, component.type(name))
  end
  node._layers = byType
end

-- The third step: gives a node's components their values.
local function assign(node, ctx)
  local byType = node._layers
  node._layers = nil
  for _, r in ipairs(node._records) do
    local info, name = r.type, r.type.name
    local c = r.component
    ---@type onlr.ValueContext
    local vctx = { file = node._file, node = node.name, holds = r.holds, lenient = ctx.lenient }
    vctx.preload = function(path)
      preload(path, vctx, name, {})
    end
    for _, p in ipairs(info.properties) do
      local propLayers = {}
      for _, layer in ipairs(byType[name]) do
        if layer.values[p.name] ~= nil then
          propLayers[#propLayers + 1] = { value = layer.values[p.name], resolve = layer.resolve }
        end
      end
      local value, set = property.merge(p.decl, propLayers, vctx, p.name)
      if set then
        c[p.name] = value
      end
    end
    for _, layer in ipairs(byType[name]) do
      if layer.values.enabled ~= nil then
        r.enabled = layer.values.enabled and true or false
      end
    end
    for _, message in ipairs(vctx.errors or {}) do
      note(node, ctx, message)
    end
  end
end

---Makes the nodes of a node file, with their components and values. The nodes are not in the tree yet.
---@param path string a node file, such as "nodes/coin.lua"
---@param lenient boolean? in the node view: problems are noted on their nodes as _errors, and the rest is made
---@return onlr.Node first the file's first node
---@return onlr.Scope scope the file's nodes by their ids
function build.file(path, lenient)
  if type(path) ~= "string" then
    error("a node file is named by its path", 0)
  end
  ---@type onlr.BuildContext
  local ctx = { lenient = lenient or life.mode == "preview", todo = {} }
  local first, scope = instances.walk(path, maker(ctx))
  for _, node in ipairs(ctx.todo) do
    make(node, ctx)
  end
  for _, node in ipairs(ctx.todo) do
    assign(node, ctx)
  end
  return first, scope
end

return build
