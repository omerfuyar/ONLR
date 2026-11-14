-- The nodes of a node file as the game makes them (DESIGN 5 and 9): plain nodes, and instances with their changes laid over
-- their bases. The engine's build.lua does the same for the game; here no component is made, and each node remembers
-- where the editor writes a change of it.

local format = require("format")

local resolve = {}

---What the resolver asks of the project.
---@class onlr_project.Source
---@field file fun(path: string): table?, string? a node file's table, or nil and why it does not load
---@field space table the names that components can hold: true for a type, a table for a folder or a package
---@field properties fun(type: string): table[]? a type's properties, as the edit player answers them, when known

---A node of a node file, as the panels show it.
---@class onlr_project.Node
---@field path string its path of ids, from the file that is shown: an id, or an instance's id, a slash and the rest
---@field id string its id in the file that writes it
---@field file string the node file that writes it
---@field own boolean a plain node of the shown file. Any other comes from an instance's base, and is changed by a change
---@field raw table? an own node's table in the file
---@field holder table? the table, in the shown file, of the instance that a node comes from, or of the instance itself
---@field key string? the key of the node's change in that instance
---@field instanceOf string? the base, when the node is the first node of an instance
---@field name string?
---@field posX number
---@field posY number
---@field rot number
---@field sclX number
---@field sclY number
---@field z number
---@field active boolean
---@field base table<string, any> the fields without the shown file's change, which a change that is taken out goes back to
---@field changed table<string, boolean> the fields that the shown file's change sets
---@field components table<string, onlr_project.Component> by type name
---@field children onlr_project.Node[]
---@field parent onlr_project.Node?
---@field errors string[]

---A component of such a node.
---@class onlr_project.Component
---@field values table<string, any> its values, as the files write them
---@field base table<string, any>? the values without the shown file's change. Nil when that change adds the component
---@field changed table<string, boolean> the values that the shown file's change sets
---@field prefix table<string, string> for each value, the path before the ids that it names

local FIELDS = { "name", "posX", "posY", "rot", "sclX", "sclY", "z", "active" }
local FIRST = {}

---Splits a node file's components, tables in tables by the dots of their names, into tables by type name.
---A name that the project does not know is taken for a type, so its values are kept.
---@param components table
---@param space table
---@param prefix string?
---@param out table<string, table>?
---@return table<string, table>
function resolve.flatten(components, space, prefix, out)
  out = out or {}
  prefix = prefix or ""
  for key, value in pairs(components) do
    if type(value) == "table" and type(key) == "string" then
      local entry = space[key]
      if type(entry) == "table" then
        resolve.flatten(value, entry, prefix .. key .. ".", out)
      else
        out[prefix .. key] = value
      end
    end
  end
  return out
end

---The table of a component's values in a node's entry or in a change, by its type's name.
---@param entry table the node's entry, or the change
---@param typeName string such as "onlr.sprite"
---@param create boolean? makes the tables that are missing
---@return table values nil when a table is missing and none is made
function resolve.component(entry, typeName, create)
  local t = entry.components
  if not t then
    if not create then
      return nil --[[@as table]]
    end
    t = {}
    entry.components = t
  end
  for part in typeName:gmatch("[^.]+") do
    if type(t[part]) ~= "table" then
      if not create then
        return nil --[[@as table]]
      end
      t[part] = {}
    end
    t = t[part]
  end
  return t
end

---Takes a component's table out of a node's entry or a change, with the tables that it leaves empty.
---@param entry table
---@param typeName string
function resolve.dropComponent(entry, typeName)
  local chain = { entry }
  local t = entry.components
  local names = { "components" }
  for part in typeName:gmatch("[^.]+") do
    if type(t) ~= "table" then
      return
    end
    chain[#chain + 1] = t
    names[#names + 1] = part
    t = t[part]
  end
  for i = #chain, 1, -1 do
    chain[i][names[i]] = nil
    if next(chain[i]) ~= nil or i == 1 then
      break
    end
  end
end

local function kinds(source, typeName)
  local properties = source.properties(typeName)
  local byName = {}
  for _, p in ipairs(properties or {}) do
    byName[p.name] = p
  end
  return byName
end

-- Lays a value over another: whole, apart from a group, which is laid field by field (DESIGN 9).
local function over(decl, under, value)
  if decl and decl.kind == "group" and type(under) == "table" and type(value) == "table" then
    local merged = format.copy(under)
    for _, field in ipairs(decl.fields or {}) do
      if value[field.name] ~= nil then
        merged[field.name] = over(field, under[field.name], value[field.name])
      end
    end
    return merged
  end
  return value
end

local expandFile

local function expandEntry(entry, scope, overlays, ctx)
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
    if scope.top then
      ctx.instances[id] = entry
    end
    local node, innerScope = expandFile(instance.base, inner, ctx, scope.prefix .. id)
    node.instanceOf = instance.base
    scope.nodes[id] = node
    for path, other in pairs(innerScope.nodes) do
      if other ~= node then
        scope.nodes[prefix .. path] = other
      end
    end
    if scope.top then
      local unused = {}
      for key in pairs(own.changes) do
        if not own.used[key] then
          unused[#unused + 1] = key
          node.errors[#node.errors + 1] = ("the instance changes %s, which names no node"):format(tostring(key))
        end
      end
      ctx.unused[id] = unused
    end
    return node
  end

  ---@type onlr_project.Node
  local node = {
    path = scope.prefix .. id, id = id, file = scope.file, own = scope.top or false,
    posX = 0, posY = 0, rot = 0, sclX = 1, sclY = 1, z = 0, active = true,
    base = {}, changed = {}, components = {}, children = {}, errors = {},
  }
  if node.own then
    node.raw = entry
  end
  scope.nodes[id] = node
  ctx.index[node.path] = node
  ctx.order[#ctx.order + 1] = node

  local layers = { { entry = entry, scope = scope } }
  local added = {}
  local function use(o, key)
    o.used[key] = true
    if o.parent then
      use(o.parent, o.keys[key])
    end
  end
  for _, o in ipairs(overlays) do
    local change = o.changes[id]
    if change then
      use(o, id)
      layers[#layers + 1] = { entry = change, scope = o.scope, change = o.scope.top }
      if type(change.children) == "table" then
        added[#added + 1] = { children = change.children, overlay = o }
      end
    end
  end

  for _, layer in ipairs(layers) do
    local e = layer.entry
    for _, field in ipairs(FIELDS) do
      if e[field] ~= nil then
        node[field] = e[field]
        if layer.change then
          node.changed[field] = true
        else
          node.base[field] = e[field]
        end
      end
    end
    if type(e.components) == "table" then
      for typeName, values in pairs(resolve.flatten(e.components, ctx.source.space)) do
        local c = node.components[typeName]
        if not c then
          c = { values = {}, changed = {}, prefix = {}, base = not layer.change and {} or nil }
          node.components[typeName] = c
        end
        local decls = kinds(ctx.source, typeName)
        for name, value in pairs(values) do
          c.values[name] = over(decls[name], c.values[name], value)
          c.prefix[name] = layer.scope.prefix
          if layer.change then
            c.changed[name] = true
          elseif c.base then
            c.base[name] = over(decls[name], c.base[name], value)
          end
        end
      end
    end
  end
  for _, field in ipairs(FIELDS) do
    if node.base[field] == nil then
      node.base[field] = format.DEFAULTS[field]
    end
  end

  local function attach(child)
    child.parent = node
    node.children[#node.children + 1] = child
  end
  for _, child in ipairs(type(entry.children) == "table" and entry.children or {}) do
    attach(expandEntry(child, scope, overlays, ctx))
  end
  for _, add in ipairs(added) do
    for _, child in ipairs(add.children) do
      attach(expandEntry(child, add.overlay.scope, add.overlay.overlays, ctx))
    end
  end
  return node
end

function expandFile(path, overlays, ctx, firstPath)
  if ctx.stack[path] then
    error(path .. ": a node file cannot hold itself", 0)
  end
  local data, err = ctx.source.file(path)
  if not data then
    error(err or (path .. ": no such file"), 0)
  end
  ctx.stack[path] = true
  ctx.files[path] = true
  local scope = { file = path, prefix = firstPath and (firstPath .. "/") or "", nodes = {}, top = firstPath == nil }
  for _, o in ipairs(overlays) do
    if o.changes[FIRST] and type(data.id) == "string" then
      o.changes[data.id] = o.changes[FIRST]
      o.keys[data.id] = o.keys[FIRST]
    end
  end
  local first = expandEntry(data, scope, overlays, ctx)
  if firstPath then
    ctx.index[first.path] = nil
    first.path = firstPath
    ctx.index[firstPath] = first
  end
  ctx.stack[path] = nil
  return first, scope
end

---The nodes of a node file.
---@class onlr_project.Tree
---@field file string the node file
---@field first onlr_project.Node? its first node. Nil when the file does not load
---@field error string? why it does not load
---@field index table<string, onlr_project.Node> every node, by its path
---@field order onlr_project.Node[] every node, in the order of the tree
---@field instances table<string, table> the file's own instances, by id: their tables in the file
---@field unused table<string, string[]> for each of them, the keys of its changes that name no node
---@field files table<string, boolean> the node files that it is made of

---Makes the nodes of a node file.
---@param path string the node file
---@param source onlr_project.Source
---@return onlr_project.Tree
function resolve.tree(path, source)
  local ctx = { source = source, stack = {}, index = {}, order = {}, instances = {}, unused = {}, files = {} }
  local ok, first = pcall(expandFile, path, {}, ctx)
  ---@type onlr_project.Tree
  local tree = { file = path, index = ctx.index, order = ctx.order, instances = ctx.instances, unused = ctx.unused, files = ctx.files }
  if not ok then
    tree.error = tostring(first)
    tree.index, tree.order = {}, {}
    return tree
  end
  tree.first = first
  -- A node that comes from an instance is changed in the shown file's instance that holds it.
  for _, node in ipairs(ctx.order) do
    if not node.own then
      local holderId, rest = node.path:match("^([^/]+)/(.*)$")
      holderId = holderId or node.path
      node.holder = ctx.instances[holderId]
      if rest then
        node.key = rest
      else
        local base = node.holder and source.file(node.holder.instance.base)
        node.key = base and base.id
      end
    end
  end
  return tree
end

---Calls a function for every value that a file writes itself: those of its own nodes' components, and of its instances' changes.
---@param tree onlr_project.Tree
---@param source onlr_project.Source
---@param visit fun(values: table, name: string, decl: table?, typeName: string, entry: table) the table that holds the value, its property's name and declaration, and the entry that writes it
function resolve.values(tree, source, visit)
  local function entry(e)
    if type(e.components) == "table" then
      for typeName, values in pairs(resolve.flatten(e.components, source.space)) do
        local decls = kinds(source, typeName)
        for name in pairs(values) do
          visit(values, name, decls[name], typeName, e)
        end
      end
    end
    for _, child in ipairs(type(e.children) == "table" and e.children or {}) do
      if type(child.instance) == "table" then
        for _, change in pairs(child.instance.changes or {}) do
          entry(change)
        end
      else
        entry(child)
      end
    end
  end
  local data = source.file(tree.file)
  if not data then
    return
  end
  if type(data.instance) == "table" then
    for _, change in pairs(data.instance.changes or {}) do
      entry(change)
    end
  else
    entry(data)
  end
end

return resolve
