-- The nodes of a node file as the game makes them (DESIGN 5 and 9): plain nodes, and instances with their changes laid over
-- their bases. The engine's build.lua does the same for the game; here no component is made, and each node remembers
-- where the editor writes a change of it.

local ecs = require("ecs")
local format = require("format")
-- The walk over instances is the engine's own, from ONLR's engine beside the plugin (DESIGN 13.1).
local instances = assert(loadfile(ecs.plugin.folder .. "../../packages/onlr/library/instances.lua"))()

local resolve = {}

---What the resolver asks of the project.
---@class onlr.editor.Source
---@field file fun(path: string): table?, string? a node file's table, or nil and why it does not load
---@field space table the names that components can hold: true for a type, a table for a folder or a package
---@field properties fun(type: string): table[]? a type's properties, as the preview answers them, when known

---A node of a node file, as the panels show it.
---@class onlr.editor.Node
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
---@field componentOrder string[]? the types that its components show and run in the order of, the rest after by their names
---@field base table<string, any> the fields without the shown file's change, which a change that is taken out goes back to
---@field changed table<string, boolean> the fields that the shown file's change sets
---@field components table<string, onlr.editor.Component> by type name
---@field children onlr.editor.Node[]
---@field parent onlr.editor.Node?
---@field errors string[]

---A component of such a node.
---@class onlr.editor.Component
---@field values table<string, any> its values, as the files write them
---@field base table<string, any>? the values without the shown file's change. Nil when that change adds the component
---@field changed table<string, boolean> the values that the shown file's change sets
---@field prefix table<string, string> for each value, the path before the ids that it names

local FIELDS = { "name", "posX", "posY", "rot", "sclX", "sclY", "z", "active", "componentOrder" }

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
      ---@diagnostic disable-next-line: return-type-mismatch
      return nil
    end
    t = {}
    entry.components = t
  end
  for part in typeName:gmatch("[^.]+") do
    if type(t[part]) ~= "table" then
      if not create then
        ---@diagnostic disable-next-line: return-type-mismatch
        return nil
      end
      t[part] = {}
    end
    t = t[part]
  end
  return t
end

---Type names in the order that a node's components show and run in: those that its componentOrder names, in that order, then
---the rest by their names (DESIGN 5).
---@param order string[]? the node's componentOrder
---@param names string[] the type names to order
---@return string[]
function resolve.ordered(order, names)
  local rank = {}
  for i, name in ipairs(order or {}) do
    rank[name] = rank[name] or i
  end
  local out = {}
  for i, name in ipairs(names) do
    out[i] = name
  end
  table.sort(out, function(a, b)
    local ra, rb = rank[a] or math.huge, rank[b] or math.huge
    if ra ~= rb then
      return ra < rb
    end
    return a < b
  end)
  return out
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

-- The editor's maker of nodes for the walk over a file's instances, which the engine's build shares (instances.lua): the nodes
-- that the panels show, each with where the editor writes a change of it.
local function maker(ctx)
  return {
    file = function(path)
      -- a file that does not load is one of the tree's files too, so the tree is made again when it changes
      ctx.files[path] = true
      local data, err = ctx.source.file(path)
      if not data then
        error(err or (path .. ": no such file"), 0)
      end
      return data
    end,
    node = function(entry, scope)
      ---@type onlr.editor.Node
      local node = {
        path = scope.prefix .. entry.id, id = entry.id, file = scope.file, own = scope.top,
        posX = 0, posY = 0, rot = 0, sclX = 1, sclY = 1, z = 0, active = true,
        -- the base starts with format.DEFAULTS, and the file's layers that are no change are laid over it
        base = { posX = 0, posY = 0, rot = 0, sclX = 1, sclY = 1, z = 0, active = true },
        changed = {}, components = {}, children = {}, errors = {},
      }
      if node.own then
        node.raw = entry
      end
      ctx.index[node.path] = node
      ctx.order[#ctx.order + 1] = node
      return node
    end,
    -- A change that the shown file writes is the node's change; the others are its base.
    lay = function(node, e, scope, change)
      change = change and scope.top
      for _, field in ipairs(FIELDS) do
        if e[field] ~= nil then
          node[field] = e[field]
          if change then
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
            c = { values = {}, changed = {}, prefix = {}, base = not change and {} or nil }
            node.components[typeName] = c
          end
          local decls = kinds(ctx.source, typeName)
          for name, value in pairs(values) do
            c.values[name] = over(decls[name], c.values[name], value)
            c.prefix[name] = scope.prefix
            if change then
              c.changed[name] = true
            elseif c.base then
              c.base[name] = over(decls[name], c.base[name], value)
            end
          end
        end
      end
    end,
    attach = function(child, parent)
      child.parent = parent
      parent.children[#parent.children + 1] = child
    end,
    first = function(node, path)
      ctx.index[node.path] = nil
      node.path = path
      ctx.index[path] = node
    end,
    instance = function(node, entry, scope, unused)
      node.instanceOf = entry.instance.base
      if scope.top then
        ctx.instances[entry.id] = entry
        for _, key in ipairs(unused) do
          node.errors[#node.errors + 1] = ("the instance changes %s, which names no node"):format(tostring(key))
        end
        ctx.unused[entry.id] = unused
      end
    end,
    -- A base that does not load, such as a deleted node file, makes this instance a node with an error, and the rest of the file
    -- still loads, so the user can delete the instance or give it its file back.
    failed = function(entry, scope, message)
      if scope.top then
        ctx.instances[entry.id] = entry
      end
      ---@type onlr.editor.Node
      local broken = {
        path = scope.prefix .. entry.id, id = entry.id, file = scope.file, own = false, instanceOf = entry.instance.base,
        posX = 0, posY = 0, rot = 0, sclX = 1, sclY = 1, z = 0, active = true,
        base = {}, changed = {}, components = {}, children = {}, errors = { message },
      }
      ctx.index[broken.path] = broken
      ctx.order[#ctx.order + 1] = broken
      return broken
    end,
  }
end

---The nodes of a node file.
---@class onlr.editor.Tree
---@field file string the node file
---@field first onlr.editor.Node? its first node. Nil when the file does not load
---@field error string? why it does not load
---@field index table<string, onlr.editor.Node> every node, by its path
---@field order onlr.editor.Node[] every node, in the order of the tree
---@field instances table<string, table> the file's own instances, by id: their tables in the file
---@field unused table<string, string[]> for each of them, the keys of its changes that name no node
---@field files table<string, boolean> the node files that it is made of

---Makes the nodes of a node file.
---@param path string the node file
---@param source onlr.editor.Source
---@return onlr.editor.Tree
function resolve.tree(path, source)
  local ctx = { source = source, index = {}, order = {}, instances = {}, unused = {}, files = {} }
  local ok, first = pcall(instances.walk, path, maker(ctx))
  ---@type onlr.editor.Tree
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
---@param tree onlr.editor.Tree
---@param source onlr.editor.Source
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
