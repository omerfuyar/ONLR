-- The walk over a node file's nodes and its instances (DESIGN 5 and 9), which the engine's build and the editor's trees share:
-- an instance's own changes are laid over its base's nodes first, then those that reach it from outside, and an id is read in
-- the file that writes it. What a node is, and what laying an entry over it does, is the maker's: the engine makes nodes with
-- components, and the editor makes the nodes that its panels show. This file requires nothing, so the editor loads it from
-- ONLR's own engine.

local instances = {}

---The nodes of one node file, as one instance of it holds them: ids are read in the file that writes them (DESIGN 9).
---@class onlr.Scope
---@field file string the node file
---@field prefix string the path of ids before its nodes' ids, from the file that the walk started with
---@field nodes table<string, any> its nodes, by id, or by a path of ids inside an instance
---@field top boolean whether it is the file that the walk started with

---The changes that one instance lays over its base's nodes.
---@class onlr.Overlay
---@field changes table<any, table> by the id that the changed node has in the file being walked
---@field scope onlr.Scope the file that wrote the changes, where their ids are read
---@field overlays onlr.Overlay[] the overlays over that file's own nodes
---@field used table<any, boolean> the keys that found their node
---@field parent onlr.Overlay? the overlay that this one is a part of
---@field keys table<any, any>? this overlay's keys in the parent

---What a walk asks of its maker.
---@class onlr.Maker
---@field file fun(path: string): table a node file's table, or an error when it does not load
---@field node fun(entry: table, scope: onlr.Scope): any makes the node of a plain entry, before anything is laid over it
---@field lay fun(node: any, entry: table, scope: onlr.Scope, change: boolean) lays a node's entry over it, and then each change of it, in order: change tells that a change wrote it, and scope is the file that wrote it
---@field attach fun(child: any, parent: any) makes a node a child of another, in the order of the file
---@field first fun(node: any, path: string) gives the first node of an instance's base the instance's path of ids
---@field instance fun(node: any, entry: table, scope: onlr.Scope, unused: any[]) tells that an instance's nodes are made: node is its first one, and unused holds the keys of its own changes that name no node
---@field failed? fun(entry: table, scope: onlr.Scope, message: string): any makes the node of an instance whose base does not load, so the rest of the file still loads; without it, the error goes on

-- The key, in an overlay, of a change to the first node of the file being walked.
local FIRST = {}

local function use(overlay, key)
  overlay.used[key] = true
  if overlay.parent then
    use(overlay.parent, overlay.keys[key])
  end
end

local walkFile

---@param entry table a node's entry
---@param scope onlr.Scope
---@param overlays onlr.Overlay[]
---@param maker onlr.Maker
---@param stack table<string, boolean> the node files that are being walked, to find one that holds itself
local function walkEntry(entry, scope, overlays, maker, stack)
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
    local own = { changes = type(instance.changes) == "table" and instance.changes or {}, scope = scope, overlays = overlays, used = {} }
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
    local node, innerScope
    if maker.failed then
      -- A base that does not load, such as a deleted node file, makes this instance a node of the maker's, and the rest of the
      -- file still loads.
      local walking = {}
      for file in pairs(stack) do
        walking[file] = true
      end
      local ok, first, made = pcall(walkFile, instance.base, inner, maker, stack, scope.prefix .. id)
      if not ok then
        for file in pairs(stack) do
          stack[file] = walking[file]
        end
        node = maker.failed(entry, scope, tostring(first))
        scope.nodes[id] = node
        return node
      end
      node, innerScope = first, made
    else
      node, innerScope = walkFile(instance.base, inner, maker, stack, scope.prefix .. id)
    end
    scope.nodes[id] = node
    for path, other in pairs(innerScope.nodes) do
      if other ~= node then
        scope.nodes[prefix .. path] = other
      end
    end
    local unused = {}
    for key in pairs(own.changes) do
      if not own.used[key] then
        unused[#unused + 1] = key
      end
    end
    maker.instance(node, entry, scope, unused)
    return node
  end

  local node = maker.node(entry, scope)
  scope.nodes[id] = node
  maker.lay(node, entry, scope, false)
  local added = {}
  for _, o in ipairs(overlays) do
    local change = o.changes[id]
    if change then
      use(o, id)
      maker.lay(node, change, o.scope, true)
      if type(change.children) == "table" then
        added[#added + 1] = { children = change.children, overlay = o }
      end
    end
  end

  for _, child in ipairs(type(entry.children) == "table" and entry.children or {}) do
    maker.attach(walkEntry(child, scope, overlays, maker, stack), node)
  end
  -- Children that a change adds are nodes of the file that wrote the change.
  for _, add in ipairs(added) do
    for _, child in ipairs(add.children) do
      maker.attach(walkEntry(child, add.overlay.scope, add.overlay.overlays, maker, stack), node)
    end
  end
  return node
end

---@param path string a node file
---@param overlays onlr.Overlay[]
---@param maker onlr.Maker
---@param stack table<string, boolean>
---@param firstPath string? the path of ids of its first node, when an instance holds the file
function walkFile(path, overlays, maker, stack, firstPath)
  if stack[path] then
    error(path .. ": a node file cannot hold itself", 0)
  end
  local fileData = maker.file(path)
  stack[path] = true
  ---@type onlr.Scope
  local scope = { file = path, prefix = firstPath and (firstPath .. "/") or "", nodes = {}, top = firstPath == nil }
  -- A change to the instance's first node is written, from outside, under the instance's id.
  for _, o in ipairs(overlays) do
    if o.changes[FIRST] and type(fileData.id) == "string" then
      o.changes[fileData.id] = o.changes[FIRST]
      o.keys[fileData.id] = o.keys[FIRST]
    end
  end
  local first = walkEntry(fileData, scope, overlays, maker, stack)
  if firstPath then
    maker.first(first, firstPath)
  end
  stack[path] = nil
  return first, scope
end

---Walks a node file's nodes, its instances' with their changes, and the children that changes add, and makes each with maker.
---@param path string a node file, such as "nodes/coin.lua"
---@param maker onlr.Maker
---@return any first the file's first node
---@return onlr.Scope scope the file's nodes by their ids
function instances.walk(path, maker)
  return walkFile(path, {}, maker, {})
end

return instances
