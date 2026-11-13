-- onlr.tree: the top node, the root, which is the node that the game runs, and the tree (DESIGN 5 and 7).
-- The tree is the top node, which the manifest names and the game keeps, with all under it.
-- The root runs as the top node's last child, so the tree's order is the top node's own nodes, then the root's.

local data = require("onlr.data")
local life = require("onlr.life")
local nodes = require("onlr.node")
local build = require("onlr.build")

---@class onlr.tree
---@field top onlr.Node the top node: the node of the manifest's topNode, or an empty node
---@field root onlr.Node the root: the node of the node file that was loaded last. nil while the top node loads.
local tree = {}

-- The node file that loadRoot asked for, which loads when the frame ends.
local nextRoot

-- The node file that Play This File names in place of the manifest's start node (DESIGN 12.1).
---@type string?
tree._startNode = nil

-- Walks the tree in its order, and stops when visit returns true.
local function walk(node, visit)
  if visit(node) then
    return true
  end
  for _, child in ipairs(node._children) do
    if walk(child, visit) then
      return true
    end
  end
  return false
end

local function makeRoot(path, index)
  local root = build.file(path)
  nodes.attach(root, tree.top, index)
  tree.root = root
  life.enter(life.collect(root, {}))
end

---Loads the top node and the first root. onlr.loop.load calls it.
function tree._load()
  local manifest = data.manifest()
  local top
  if manifest.topNode then
    top = build.file(manifest.topNode)
  else
    top = nodes.new("")
  end
  tree.top = top
  life.top = top
  life.inherit(top)
  life.enter(life.collect(top, {}))
  local start = tree._startNode or manifest.startNode
  if type(start) ~= "string" then
    error("manifest.lua: startNode names no node file", 0)
  end
  if start == manifest.topNode then
    start = manifest.startNode
  end
  makeRoot(start)
  life.startWaiting()
end

---Ends the frame for the tree: takes out what was destroyed, loads a new root if a script asked for one,
---and calls start of the components that started to run. onlr.loop.endFrame calls it.
function tree._endFrame()
  life.takeOut(data)
  while nextRoot do
    local path = nextRoot
    nextRoot = nil
    local old = tree.root
    local index
    for i, child in ipairs(tree.top._children) do
      if child == old then
        index = i
      end
    end
    if old then
      life.finish(old, data)
    end
    tree.root = nil
    makeRoot(path, index)
    life.takeOut(data)
    data.collect()
  end
  life.startWaiting()
end

---Ends the root and loads another node file as the root, when the current frame ends.
---The new root takes the old one's place among the top node's children. The top node and its own nodes stay.
---@param path string a node file, such as "nodes/menu.lua"
function tree.loadRoot(path)
  life.guard("onlr.tree.loadRoot")
  if type(path) ~= "string" then
    error("onlr.tree.loadRoot takes a node file's path", 2)
  end
  nextRoot = path
end

---Gives the tree's first node of that name, in the tree's order.
---@param name string
---@return onlr.Node?
function tree.find(name)
  local found
  walk(tree.top, function(node)
    if node.name == name then
      found = node
      return true
    end
  end)
  return found
end

---Gives a list of the tree's nodes of that name, in the tree's order.
---@param name string
---@return onlr.Node[]
function tree.findAll(name)
  local found = {}
  walk(tree.top, function(node)
    if node.name == name then
      found[#found + 1] = node
    end
  end)
  return found
end

---Gives the tree's first component of a type, in the tree's order.
---@generic T
---@param type `T` a type's name, dots and all: "bump.world"
---@return T?
function tree.findComponent(type)
  local found
  walk(tree.top, function(node)
    found = node._byType[type]
    return found ~= nil
  end)
  return found
end

---Gives a list of the tree's components of a type, in the tree's order.
---A component type is a tag: an empty script enemy on every enemy, and findAllComponents("enemy").
---@generic T
---@param type `T`
---@return T[]
function tree.findAllComponents(type)
  local found = {}
  walk(tree.top, function(node)
    local c = node._byType[type]
    if c then
      found[#found + 1] = c
    end
  end)
  return found
end

local function parentOf(parent, what)
  parent = parent or tree.root
  if not nodes.isNode(parent) or parent._gone then
    error(what .. ": the parent is no node of the tree", 3)
  end
  return parent
end

---Makes an instance of a node file in the tree, and returns it (DESIGN 9).
---It exists at once: load and enable of its components are called before spawn returns.
---Their start is called when the frame ends, so it finds the values that the script sets after spawn.
---@param path string a node file, such as "nodes/coin.lua"
---@param x? number in its parent; the file's own when left out
---@param y? number
---@param parent? onlr.Node the root when left out
---@return onlr.Node
function tree.spawn(path, x, y, parent)
  life.guard("onlr.tree.spawn")
  parent = parentOf(parent, "onlr.tree.spawn")
  local node = build.file(path)
  node.posX, node.posY = x or node.posX, y or node.posY
  nodes.attach(node, parent)
  if nodes.inTree(node) then
    life.enter(life.collect(node, {}))
  end
  return node
end

---Makes an empty node, and returns it.
---@param name string
---@param parent? onlr.Node the root when left out
---@return onlr.Node
function tree.newNode(name, parent)
  life.guard("onlr.tree.newNode")
  parent = parentOf(parent, "onlr.tree.newNode")
  local node = nodes.new(name)
  nodes.attach(node, parent)
  return node
end

return tree
