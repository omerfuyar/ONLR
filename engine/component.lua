-- Component types (DESIGN 6.1): finding a type's file by its name, loading it, and reading its properties and needs.
-- And a node's components: the table components, which holds them by their types' names, and the order they run in.

local life = require("onlr.life")
local property = require("onlr.property")

local component = {}

---What every component has. A type also defines the functions it wants called, here in the order
---of a component's life: load(), enable(), start(), then each frame any callback of LÖVE,
---fixedUpdate(dt), update(dt), lateUpdate(dt) and draw(), and at its end disable() and destroy().
---A type that has drawTree(draw) draws its node and all under it as a group: the engine calls it
---in place of drawing them, and draw draws them, so it sets up before and ends after.
---For the editor: bounds() and drawEditor(chosen).
---A type names the types that it needs on its node: Type.needs = { "bump.body" }.
---Its properties are plain fields, which other components read and set too: other.components.coin.worth.
---A type does not inherit another: the colon in a type's annotation only tells a code editor
---that its components have these fields.
---@class onlr.Component
---@field node onlr.Node
---@field needs? string[]
---@field isEnabled fun(self: onlr.Component): boolean whether the component is on. It runs when it is on and its node is active.
---@field setEnabled fun(self: onlr.Component, enabled: boolean) turns the component on or off, at once: enable or disable is called before it returns

---A node's components, by their types' names. The editor writes a field for each component type of the project
---into .onlr/, so a code editor knows what node.components.player is.
---In the game, the engine's name, each package's and each folder of components/ are always tables, empty on a node
---without their types: node.components.bump.body is nil on a node without a body, and components.bmup.body is an error.
---@class onlr.Components
---@field onlr {sprite: onlr.sprite?, text: onlr.text?, shape: onlr.shape?, camera: onlr.camera?}
---@field [string] any a script's component, or the table of a package or of a folder

---A component type, as the engine keeps it.
---@class onlr.Type
---@field name string such as "bump.body"
---@field table table the table that the type's file returns
---@field file string the type's file
---@field properties {name: string, decl: onlr.Declaration}[] in the order its file declares them
---@field needs string[] the types that its components need on their node (DESIGN 6.6)
---@field meta table the metatable that its components share

-- Names that a property cannot have, since a component or its type has them (DESIGN 6.2).
local RESERVED = { enabled = true, node = true, needs = true, isEnabled = true, setEnabled = true }

local KEYWORDS = {}
for word in ([[and break do else elseif end false for function goto if in local nil not or repeat return then true until while]]):gmatch("%a+") do
  KEYWORDS[word] = true
end

---Whether a text is a name in Lua, as each part of a type's name must be (DESIGN 6.1).
---@param text string
---@return boolean
function component.isName(text)
  return type(text) == "string" and text:match("^[%a_][%w_]*$") ~= nil and not KEYWORDS[text]
end

-- The names that components can hold: the types and the folders that group them, as a tree of spaces.
-- A space's names map to true for a type, to a space for a folder or a package, and to a text for a name that is refused.
---@class onlr.Space
---@field names table<string, true|onlr.Space|string>
---@field path string the names before it, with their dots, such as "bump."
---@field owner string? the package whose components it holds
---@field meta table? the metatable of its tables in components
---@field empty table? the empty table that stands for it on a node without its types

local root

local function newSpace(path, package)
  return { names = {}, path = path, owner = package }
end

local function scan(dir, space)
  for _, item in ipairs(love.filesystem.getDirectoryItems(dir)) do
    local full = dir .. "/" .. item
    local info = love.filesystem.getInfo(full)
    local name = item:match("^(.*)%.lua$")
    if info and info.type == "file" and name and component.isName(name) then
      if type(space.names[name]) == "table" then
        space.names[name] = ("both %s.lua and the folder %s/ are in %s"):format(name, name, dir)
      else
        space.names[name] = true
      end
    elseif info and info.type == "directory" and component.isName(item) then
      if love.filesystem.getInfo(full .. "/init.lua", "file") then
        space.names[item] = true
      elseif space.names[item] == true then
        space.names[item] = ("both %s.lua and the folder %s/ are in %s"):format(item, item, dir)
      elseif space.names[item] == nil then
        local inner = newSpace(space.path .. item .. ".", space.owner)
        space.names[item] = inner
        scan(full, inner)
      end
    end
  end
end

---The tree of names, read from components/ and from each package's components/ the first time it is needed.
---@return onlr.Space
function component.space()
  if root then
    return root
  end
  root = newSpace("")
  if love.filesystem.getInfo("components", "directory") then
    scan("components", root)
  end
  for _, package in ipairs(love.filesystem.getDirectoryItems("packages")) do
    local dir = "packages/" .. package .. "/components"
    if component.isName(package) and love.filesystem.getInfo(dir, "directory") then
      if root.names[package] ~= nil then
        root.names[package] = ("a script has the name of the package %s"):format(package)
      else
        local space = newSpace(package .. ".", package)
        root.names[package] = space
        scan(dir, space)
      end
    end
  end
  return root
end

local function split(name)
  local parts = {}
  for part in (name .. "."):gmatch("([^.]*)%.") do
    parts[#parts + 1] = part
  end
  return parts
end

-- The empty table that stands for a space on a node without its types, and that cannot be changed.
local function emptyOf(space)
  if not space.empty then
    space.empty = setmetatable({}, component.metaOf(space))
  end
  return space.empty
end

---The metatable of a space's tables in components: reading a name that is no type is an error, and nothing changes them but the engine.
---@param space onlr.Space
---@return table
function component.metaOf(space)
  if not space.meta then
    space.meta = {
      __index = function(_, key)
        local entry = space.names[key]
        if entry == true then
          return nil
        elseif type(entry) == "table" then
          return emptyOf(entry)
        elseif type(entry) == "string" then
          error(entry, 2)
        end
        error(("no component type %s%s"):format(space.path, tostring(key)), 2)
      end,
      __newindex = function()
        error("components cannot be changed: a script adds a component with node:addComponent", 2)
      end,
    }
  end
  return space.meta
end

---A new, empty components table for a node.
---@return onlr.Components
function component.newTable()
  return setmetatable({}, component.metaOf(component.space()))
end

-- Makes sure the tree of names holds a type, such as one whose file was made after the engine read the folders.
local function know(name)
  local space = component.space()
  local parts = split(name)
  for i = 1, #parts - 1 do
    local entry = space.names[parts[i]]
    if type(entry) ~= "table" then
      entry = newSpace(space.path .. parts[i] .. ".", space.owner)
      space.names[parts[i]] = entry
    end
    space = entry
  end
  space.names[parts[#parts]] = true
end

-- Finds a type's file: in the project's components/ first, then in a package's (DESIGN 6.1).
local function find(name)
  local parts = split(name)
  for _, part in ipairs(parts) do
    if not component.isName(part) then
      error(("%s is no type's name: each part of it is a name in Lua"):format(name), 0)
    end
  end
  local space = component.space()
  for i, part in ipairs(parts) do
    local entry = space.names[part]
    if type(entry) == "string" then
      error(name .. ": " .. entry, 0)
    end
    if type(entry) ~= "table" or i == #parts then
      break
    end
    space = entry
  end
  local first = component.space().names[parts[1]]
  local candidates
  if type(first) == "table" and first.owner and #parts > 1 then
    local rest = table.concat(parts, "/", 2)
    local dir = "packages/" .. parts[1] .. "/components/"
    candidates = { dir .. rest .. ".lua", dir .. rest .. "/init.lua" }
  else
    local rest = table.concat(parts, "/")
    candidates = { "components/" .. rest .. ".lua", "components/" .. rest .. "/init.lua" }
  end
  for _, file in ipairs(candidates) do
    if love.filesystem.getInfo(file, "file") then
      return file
    end
  end
  error(("no component type %s"):format(name), 0)
end

---@type table<string, onlr.Type>
local types = {}
local loading = {}

local function isEnabled(self)
  local r = life.records[self]
  return r ~= nil and r.enabled
end

local function setEnabled(self, enabled)
  life.guard("component:setEnabled")
  local r = life.records[self]
  if r then
    life.setEnabled(r, enabled)
  end
end

---The type of that name, loaded the first time it is asked for.
---A type is refused when its file does not return a table, when a property has a reserved name,
---or when types need each other in a circle (DESIGN 6.6).
---@param name string such as "bump.body"
---@return onlr.Type
function component.type(name)
  local info = types[name]
  if info then
    return info
  end
  if type(name) ~= "string" then
    error("a type's name is a text", 0)
  end
  if loading[name] then
    error(("the types %s need each other in a circle"):format(name), 0)
  end
  local file = find(name)
  local module = file:gsub("%.lua$", ""):gsub("/init$", ""):gsub("/", ".")
  local ok, t = pcall(require, module)
  if not ok then
    error(t, 0)
  end
  if type(t) ~= "table" then
    error(file .. ": a component type's file returns a table", 0)
  end
  if rawget(t, "isEnabled") and t.isEnabled ~= isEnabled or rawget(t, "setEnabled") and t.setEnabled ~= setEnabled then
    error(file .. ": isEnabled and setEnabled are the engine's", 0)
  end

  info = { name = name, table = t, file = file, properties = {}, needs = {}, meta = { __index = t } }
  for key, value in pairs(t) do
    if property.isDeclaration(value) then
      if RESERVED[key] then
        error(("%s: a property cannot be named %s"):format(file, key), 0)
      end
      info.properties[#info.properties + 1] = { name = key, decl = value }
    end
  end
  table.sort(info.properties, function(a, b)
    return a.decl.order < b.decl.order
  end)
  for _, p in ipairs(info.properties) do
    local default = p.decl.default
    t[p.name] = type(default) == "table" and property.copy(default) or default
  end
  t.isEnabled = isEnabled
  t.setEnabled = setEnabled

  loading[name] = true
  local ok2, err = pcall(function()
    for _, need in ipairs(t.needs or {}) do
      if type(need) ~= "string" then
        error(file .. ": needs is a list of types' names", 0)
      end
      if need == name then
        error(("the types %s need each other in a circle"):format(name), 0)
      end
      component.type(need)
      info.needs[#info.needs + 1] = need
    end
  end)
  loading[name] = nil
  if not ok2 then
    error(err, 0)
  end

  know(name)
  types[name] = info
  return info
end

---Every type that was loaded, by name, for the edit player's answers.
---@return table<string, onlr.Type>
function component.loaded()
  return types
end

---Puts a component into a node's components, under its type's name.
---@param node onlr.Node
---@param name string
---@param c onlr.Component
function component.put(node, name, c)
  local parts = split(name)
  local t = node.components
  local space = component.space()
  for i = 1, #parts - 1 do
    space = space.names[parts[i]] --[[@as onlr.Space]]
    local inner = rawget(t, parts[i])
    if not inner then
      inner = setmetatable({}, component.metaOf(space))
      rawset(t, parts[i], inner)
    end
    t = inner
  end
  rawset(t, parts[#parts], c)
  node._byType[name] = c
end

---Takes a component out of a node's components.
---@param node onlr.Node
---@param name string
function component.take(node, name)
  local parts = split(name)
  local t = node.components
  for i = 1, #parts - 1 do
    t = rawget(t, parts[i])
    if not t then
      return
    end
  end
  rawset(t, parts[#parts], nil)
  node._byType[name] = nil
end

-- Orders a node's records: by their types' names, and each after those that it needs (DESIGN 5).
local function order(node)
  local records = node._records
  table.sort(records, function(a, b)
    return a.type.name < b.type.name
  end)
  local byName = {}
  for _, r in ipairs(records) do
    byName[r.type.name] = r
  end
  local out, done = {}, {}
  local function visit(r)
    if done[r] then
      return
    end
    done[r] = true
    for _, need in ipairs(r.type.needs) do
      if byName[need] then
        visit(byName[need])
      end
    end
    out[#out + 1] = r
  end
  for _, r in ipairs(records) do
    visit(r)
  end
  node._records = out
end

---Makes a component of a type on a node, with no values yet, and its record. It does not enter the tree's life here.
---@param node onlr.Node
---@param info onlr.Type
---@return onlr.Record
function component.make(node, info)
  if node._byType[info.name] then
    error(("the node %s already has a %s"):format(tostring(node.name), info.name), 0)
  end
  local c = setmetatable({ node = node }, info.meta)
  ---@type onlr.Record
  local r = {
    component = c, node = node, type = info, enabled = true, running = false, alive = true, loaded = false, started = false,
    live = false, drawn = false, pending = false, removing = false, removed = false, holds = {},
  }
  life.records[c] = r
  node._records[#node._records + 1] = r
  component.put(node, info.name, c)
  order(node)
  return r
end

---The types that a node lacks among those that the given types need, with what they need in turn.
---@param node onlr.Node
---@param names string[]
---@return string[]
function component.missingNeeds(node, names)
  local have, out = {}, {}
  for _, name in ipairs(names) do
    have[name] = true
  end
  for name in pairs(node._byType) do
    have[name] = true
  end
  local function add(name)
    for _, need in ipairs(component.type(name).needs) do
      if not have[need] then
        have[need] = true
        out[#out + 1] = need
        add(need)
      end
    end
  end
  for _, name in ipairs(names) do
    add(name)
  end
  return out
end

return component
