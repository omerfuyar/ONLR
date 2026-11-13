-- Making nodes from node files (DESIGN 5 and 9): plain nodes, instances with their changes, and variants.
-- It works in steps. First it makes every node, and notes for each component the values that the file
-- and each change of an instance give it. Then it makes every component, and then gives them their values,
-- so a property that names a node finds it, wherever in the file that node is.

local data = require("onlr.data")
local life = require("onlr.life")
local component = require("onlr.component")
local property = require("onlr.property")
local nodes = require("onlr.node")

local build = {}

---What one build shares.
---@class onlr.BuildContext
---@field lenient boolean? in the node view: a problem is noted on its node, and the rest is made
---@field stack table<string, boolean> the node files that are being made, to find one that holds itself
---@field todo onlr.Node[] the nodes whose components wait for the next steps

---The nodes of one node file, as one instance of it holds them: ids are read in the file that writes them (DESIGN 9).
---@class onlr.Scope
---@field file string the node file
---@field prefix string the path of ids before its nodes' ids, from the file that the build started with
---@field nodes table<string, onlr.Node> its nodes, by id, or by a path of ids inside an instance

---The changes that one instance lays over its base's nodes.
---@class onlr.Overlay
---@field changes table<string, table> by the id that the changed node has in the file being made
---@field scope onlr.Scope the file that wrote the changes, where their ids are read
---@field overlays onlr.Overlay[] the overlays over that file's own nodes
---@field used table<string, boolean> the keys that found their node
---@field parent onlr.Overlay? the overlay that this one is a part of
---@field keys table<string, string>? this overlay's keys in the parent

-- The key, in an overlay, of a change to the first node of the file being made.
local FIRST = {}

local FIELDS = { "name", "posX", "posY", "rot", "sclX", "sclY" }

local function note(node, ctx, message)
  if ctx.lenient then
    node._errors = node._errors or {}
    node._errors[#node._errors + 1] = message
    return
  end
  error(message, 0)
end

local function use(overlay, key)
  overlay.used[key] = true
  if overlay.parent then
    use(overlay.parent, overlay.keys[key])
  end
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
  if entry.components ~= nil then
    node._layers[#node._layers + 1] = { components = entry.components, scope = scope }
  end
end

local buildFile

---@param entry table a node's entry
---@param scope onlr.Scope
---@param overlays onlr.Overlay[]
---@param ctx onlr.BuildContext
---@return onlr.Node
local function buildEntry(entry, scope, overlays, ctx)
  local id = entry.id
  if type(id) ~= "string" then
    error(scope.file .. ": a node has no id", 0)
  end
  if scope.nodes[id] then
    error(("%s: the id %s is there twice"):format(scope.file, id), 0)
  end

  if entry.instance then
    local instance = entry.instance
    if type(instance) ~= "table" or type(instance.base) ~= "string" then
      error(("%s: the instance %s names no base"):format(scope.file, id), 0)
    end
    -- The instance's own changes are laid over first, then those that reach it from outside.
    local own = { changes = instance.changes or {}, scope = scope, overlays = overlays, used = {} }
    local inner = { own }
    local prefix = id .. "/"
    for _, o in ipairs(overlays) do
      local sub, keys, any = {}, {}, false
      for key, change in pairs(o.changes) do
        if key == id then
          sub[FIRST], keys[FIRST], any = change, key, true
        elseif type(key) == "string" and key:sub(1, #prefix) == prefix then
          local rest = key:sub(#prefix + 1)
          sub[rest], keys[rest], any = change, key, true
        end
      end
      if any then
        inner[#inner + 1] = { changes = sub, scope = o.scope, overlays = o.overlays, used = {}, parent = o, keys = keys }
      end
    end
    local node, innerScope = buildFile(instance.base, inner, ctx, scope.prefix .. id)
    scope.nodes[id] = node
    for path, other in pairs(innerScope.nodes) do
      if other ~= node then
        scope.nodes[prefix .. path] = other
      end
    end
    for key in pairs(own.changes) do
      if not own.used[key] then
        note(node, ctx, ("%s: the instance %s changes %s, which names no node"):format(scope.file, id, tostring(key)))
      end
    end
    return node
  end

  local node = nodes.new(entry.name)
  node._id = id
  node._path = scope.prefix .. id
  node._layers = {}
  node._file = scope.file
  scope.nodes[id] = node
  ctx.todo[#ctx.todo + 1] = node
  lay(node, entry, scope)

  local added = {}
  for _, o in ipairs(overlays) do
    local change = o.changes[id]
    if change then
      use(o, id)
      lay(node, change, o.scope)
      if change.children then
        added[#added + 1] = { children = change.children, overlay = o }
      end
    end
  end

  for _, child in ipairs(entry.children or {}) do
    nodes.attach(buildEntry(child, scope, overlays, ctx), node)
  end
  -- Children that a change adds are nodes of the file that wrote the change.
  for _, add in ipairs(added) do
    for _, child in ipairs(add.children) do
      nodes.attach(buildEntry(child, add.overlay.scope, add.overlay.overlays, ctx), node)
    end
  end
  return node
end

---@param path string a node file
---@param overlays onlr.Overlay[]
---@param ctx onlr.BuildContext
---@param firstPath string? the path of ids of its first node, when an instance holds the file
---@return onlr.Node first
---@return onlr.Scope scope
function buildFile(path, overlays, ctx, firstPath)
  if ctx.stack[path] then
    error(path .. ": a node file cannot hold itself", 0)
  end
  local fileData = data.load("node", path)
  ctx.stack[path] = true
  ---@type onlr.Scope
  local scope = { file = path, prefix = firstPath and (firstPath .. "/") or "", nodes = {} }
  -- A change to the instance's first node is written, from outside, under the instance's id.
  for _, o in ipairs(overlays) do
    if o.changes[FIRST] and type(fileData.id) == "string" then
      o.changes[fileData.id] = o.changes[FIRST]
      o.keys[fileData.id] = o.keys[FIRST]
    end
  end
  local first = buildEntry(fileData, scope, overlays, ctx)
  if firstPath then
    first._path = firstPath
  end
  ctx.stack[path] = nil
  return first, scope
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
      property.load(ctx, name, "sound", value, decl.options.stream or false)
    elseif kind == "font" then
      property.load(ctx, name, "font", type(value) == "table" and value.path or nil,
        type(value) == "table" and value.size or decl.options.size or 12)
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
  local ctx = { lenient = lenient or life.mode == "edit", stack = {}, todo = {} }
  local first, scope = buildFile(path, {}, ctx)
  for _, node in ipairs(ctx.todo) do
    make(node, ctx)
  end
  for _, node in ipairs(ctx.todo) do
    assign(node, ctx)
  end
  return first, scope
end

return build
