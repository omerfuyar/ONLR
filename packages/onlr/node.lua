-- Nodes and their functions, as a script sees them (DESIGN 7).
-- A node's name, its place and its components are plain fields: node.posX = 10.
-- The engine does not watch them: it compares the place when it uses the node's place in the world.
-- What the engine must act on when it changes is read and changed through functions,
-- as the values of LÖVE's own objects are: node:setActive(false) calls disable of the node's
-- components before it returns. So a change that does more than set a value is always a call.
-- The fields whose names start with an underscore are the engine's.

local life = require("onlr.life")
local component = require("onlr.component")
local property = require("onlr.property")

---@class onlr.Node
---@field name string
---@field posX number its position in its parent, in pixels
---@field posY number
---@field rot number its angle in its parent, in radians, clockwise
---@field sclX number its scale in its parent
---@field sclY number
---@field components onlr.Components the node's components, by their types' names: node.components.bump.body
---@field _parent onlr.Node? the engine's, as every field below: read them through the node's functions
---@field _children onlr.Node[]
---@field _records onlr.Record[] its components' records, in the order they run in
---@field _byType table<string, onlr.Component> its components by their types' names, dots and all
---@field _active boolean its own active
---@field _paused boolean its own paused
---@field _z number
---@field _activeIn boolean it and every node above it are active
---@field _pausedIn boolean it or a node above it is paused
---@field _destroyed boolean
---@field _gone boolean? it was taken out of the tree
---@field _id string? its id in its node file
---@field _path string? its path of ids from the node file that was loaded
---@field _file string? the node file that wrote it
---@field _layers table? its components' values, while its node file is made
---@field _errors string[]? what was wrong with it, in the node view
---@field _a number the place in the world, as a matrix
---@field _b number
---@field _c number
---@field _d number
---@field _tx number
---@field _ty number
---@field _wv integer the version of that matrix
---@field _ws integer? the draw that worked it out last
---@field _tv integer? the version that _transform holds
---@field _transform love.Transform?
---@field _px number? the place that the matrix was worked out from
---@field _py number?
---@field _pr number?
---@field _psx number?
---@field _psy number?
---@field _ppv integer?
local Node = {}

local meta = { __index = Node }

local nodes = {}

---Whether a value is a node.
---@param value any
---@return boolean
function nodes.isNode(value)
  return getmetatable(value) == meta
end

---A new node, not yet in the tree.
---@param name string?
---@return onlr.Node
function nodes.new(name)
  return setmetatable({
    name = name or "",
    posX = 0,
    posY = 0,
    rot = 0,
    sclX = 1,
    sclY = 1,
    components = component.newTable(),
    _children = {},
    _records = {},
    _byType = {},
    _active = true,
    _paused = false,
    _z = 0,
    _activeIn = true,
    _pausedIn = false,
    _destroyed = false,
    _wv = 0,
  }, meta)
end

---Puts a node under a parent, at the end of its children or at index, without calling anything.
---@param node onlr.Node
---@param parent onlr.Node
---@param index integer?
function nodes.attach(node, parent, index)
  node._parent = parent
  local children = parent._children
  if index then
    table.insert(children, math.max(1, math.min(index, #children + 1)), node)
  else
    children[#children + 1] = node
  end
  life.inherit(node)
end

---Whether a node is in the tree that runs: under the top node, and not taken out.
---@param node onlr.Node
---@return boolean
local function inTree(node)
  local up = node
  while up do
    if up == life.top then
      return true
    end
    up = up._parent
  end
  return false
end
nodes.inTree = inTree

local function check(self, what)
  life.guard(what)
  if self._gone then
    error(what .. ": the node was destroyed", 3)
  end
end

---Gives the node a component of a type that it lacks, and returns it.
---Giving it a second of a type is an error. The types that it needs are added first, with their defaults.
---Its load and enable are called before addComponent returns (DESIGN 6.4).
---values are the properties' values as the component gets them; a file may be given as its path, as a node file holds it.
---@generic T
---@param type `T` a type's name, dots and all: "bump.world"
---@param values? table
---@return T
function Node:addComponent(type, values)
  check(self, "node:addComponent")
  local info = component.type(type)
  if self._byType[type] then
    error(("the node %s already has a %s"):format(self.name, type), 2)
  end
  local names = component.missingNeeds(self, { type })
  local made = {}
  for i = #names, 1, -1 do
    made[#made + 1] = component.make(self, component.type(names[i]))
  end
  local r = component.make(self, info)
  made[#made + 1] = r
  for _, m in ipairs(made) do
    nodes.assign(m, m == r and values or nil)
  end
  if inTree(self) then
    life.enter(made)
  end
  return r.component
end

---Sets a new component's properties from values that a script gives, and the defaults for the others.
---@param r onlr.Record
---@param values table?
function nodes.assign(r, values)
  local c = r.component
  local ctx = { file = "a script", node = r.node.name, holds = r.holds }
  for _, p in ipairs(r.type.properties) do
    local decl, value = p.decl, values and values[p.name]
    local kind = decl.kind
    if value ~= nil and (kind == "image" or kind == "sound") and _G.type(value) == "string" then
      value = property.convert(decl, value, ctx, p.name, function() return nil end)
    elseif value ~= nil and kind == "font" and _G.type(value) == "table" and not value.typeOf then
      value = property.convert(decl, value, ctx, p.name, function() return nil end)
    elseif value == nil then
      value = property.merge(decl, {}, ctx, p.name)
    end
    if value ~= nil then
      c[p.name] = value
    end
  end
  if values and values.enabled == false then
    r.enabled = false
  end
end

---Takes the node's component of a type off it when the frame ends (DESIGN 6.4):
---until then it stays, and its functions are called; then its disable and destroy are called.
---Removing a component that another of the node needs is an error.
---@param type string a type's name, dots and all: "shield"
function Node:removeComponent(type)
  check(self, "node:removeComponent")
  local c = self._byType[type]
  if not c then
    error(("the node %s has no %s"):format(self.name, type), 2)
  end
  for _, r in ipairs(self._records) do
    if not r.removing then
      for _, need in ipairs(r.type.needs) do
        if need == type then
          error(("the node %s's %s needs its %s"):format(self.name, r.type.name, type), 2)
        end
      end
    end
  end
  life.remove(life.records[c])
end

---Calls the function of that name in each of the node's components that runs and has it, in their order,
---as a direct call would: a paused component is called too (DESIGN 7.2).
---@param name string
---@param ... any
function Node:send(name, ...)
  life.guard("node:send")
  for _, r in ipairs(self._records) do
    if r.running then
      local fn = r.component[name]
      if fn then
        fn(r.component, ...)
      end
    end
  end
end

---Whether the node runs: it and every node above it are active.
---@return boolean
function Node:isActive()
  return self._activeIn
end

---Turns the node, with all under it, on or off, at once:
---enable or disable of the components that start or stop is called before it returns.
---@param active boolean
function Node:setActive(active)
  check(self, "node:setActive")
  active = active and true or false
  if self._active ~= active then
    self._active = active
    if inTree(self) then
      life.changed(self)
    else
      life.inherit(self)
    end
  end
end

---Whether the node, or a node above it, is paused.
---@return boolean
function Node:isPaused()
  return self._pausedIn
end

---Pauses or resumes the node, with all under it. A paused node still draws, and its components get
---no start, events, fixedUpdate, update or lateUpdate. Pausing calls neither enable nor disable.
---A node file does not hold it: every node starts unpaused.
---@param paused boolean
function Node:setPaused(paused)
  check(self, "node:setPaused")
  paused = paused and true or false
  if self._paused ~= paused then
    self._paused = paused
    life.paused(self)
  end
end

---The node's order in drawing, added to its parent's.
---@return number
function Node:getZ()
  return self._z
end

---Changes the node's z. The frame's next draw uses it.
---@param z number
function Node:setZ(z)
  check(self, "node:setZ")
  if _G.type(z) ~= "number" then
    error("z is a number", 2)
  end
  self._z = z
  life.dirty()
end

---The node's parent: nil for the top node.
---@return onlr.Node?
function Node:getParent()
  return self._parent
end

---The node's children, in their order. The list is the engine's own: read it, do not change it.
---@return onlr.Node[]
function Node:getChildren()
  return self._children
end

---Moves the node, with all that is under it, to the end of another node's children, or to index among them.
---It keeps its own place, so it moves with its new parent; setWorldPosition after keeps it where it is.
---Components that it starts or stops get enable or disable at once.
---A node of the root that is moved under the top node, or under one of the top node's own nodes, stays when the root changes.
---The top node and the root cannot be moved.
---@param parent onlr.Node not the node itself, nor one under it
---@param index? integer
function Node:setParent(parent, index)
  check(self, "node:setParent")
  if not nodes.isNode(parent) or parent._gone then
    error("node:setParent takes a node that is in the tree", 2)
  end
  local tree = require("onlr.tree")
  if self == tree.top or self == tree.root then
    error("the top node and the root cannot be moved", 2)
  end
  local up = parent
  while up do
    if up == self then
      error("a node cannot be moved under itself", 2)
    end
    up = up._parent
  end
  local old = self._parent
  local wasIn = inTree(self)
  if old then
    for i, child in ipairs(old._children) do
      if child == self then
        table.remove(old._children, i)
        break
      end
    end
  end
  nodes.attach(self, parent, index)
  local nowIn = inTree(self)
  if nowIn and not wasIn then
    life.enter(life.collect(self, {}))
  elseif wasIn then
    life.changed(self)
  end
end

---Marks the node and every node under it: their isDestroyed() is true from now on.
---They are destroyed when the frame ends: disable and destroy of their components are called, children first.
---The top node and the root are not destroyed: onlr.tree.loadRoot ends the root.
function Node:destroy()
  check(self, "node:destroy")
  local tree = require("onlr.tree")
  if self == tree.top or self == tree.root then
    error("the top node and the root are not destroyed: onlr.tree.loadRoot ends the root", 2)
  end
  if inTree(self) then
    life.destroy(self)
  else
    self._destroyed = true
  end
end

---Whether node:destroy() was called on the node or on one above it,
---so a component that holds the node knows that it is gone.
---@return boolean
function Node:isDestroyed()
  return self._destroyed
end

-- The place in the world: a matrix of six numbers, from the node's place and its parent's (DESIGN 8.2).
-- It is worked out again only when the node's place, or its parent's matrix, differs from the one used last.
local version = 0

local function world(n, stamp)
  if stamp and n._ws == stamp then
    return
  end
  local p = n._parent
  local pv = 0
  if p then
    world(p, stamp)
    pv = p._wv
  end
  local x, y, r, sx, sy = n.posX, n.posY, n.rot, n.sclX, n.sclY
  if x ~= n._px or y ~= n._py or r ~= n._pr or sx ~= n._psx or sy ~= n._psy or pv ~= n._ppv or n._wv == 0 then
    n._px, n._py, n._pr, n._psx, n._psy, n._ppv = x, y, r, sx, sy, pv
    local cos, sin = math.cos(r), math.sin(r)
    local a, b, c, d = cos * sx, sin * sx, -sin * sy, cos * sy
    if p then
      local pa, pb, pc, pd = p._a, p._b, p._c, p._d
      n._a, n._b = pa * a + pc * b, pb * a + pd * b
      n._c, n._d = pa * c + pc * d, pb * c + pd * d
      n._tx, n._ty = pa * x + pc * y + p._tx, pb * x + pd * y + p._ty
    else
      n._a, n._b, n._c, n._d, n._tx, n._ty = a, b, c, d, x, y
    end
    version = version + 1
    n._wv = version
  end
  n._ws = stamp
end

---The node's place in the world as a LÖVE transform, which the engine applies around its components' draw.
---@param stamp integer? the draw that asks, which works out each node once
---@return love.Transform
function Node:_drawTransform(stamp)
  world(self, stamp)
  local t = self._transform
  if not t then
    t = love.math.newTransform()
    self._transform = t
  end
  if self._tv ~= self._wv then
    t:setMatrix(self._a, self._c, 0, self._tx, self._b, self._d, 0, self._ty, 0, 0, 1, 0, 0, 0, 0, 1)
    self._tv = self._wv
  end
  return t
end

---The node's place in the world as six numbers: x and y of the x axis, x and y of the y axis, and the origin.
---@return number a, number b, number c, number d, number tx, number ty
function Node:_world()
  world(self)
  return self._a, self._b, self._c, self._d, self._tx, self._ty
end

---Turns a point of the node's space into the world's.
---@param x? number 0 when left out
---@param y? number 0 when left out
---@return number x, number y
function Node:toWorld(x, y)
  world(self)
  x, y = x or 0, y or 0
  return self._a * x + self._c * y + self._tx, self._b * x + self._d * y + self._ty
end

---Turns a point of the world into the node's space.
---@param x number
---@param y number
---@return number x, number y
function Node:toLocal(x, y)
  world(self)
  local a, b, c, d = self._a, self._b, self._c, self._d
  local det = a * d - b * c
  local dx, dy = x - self._tx, y - self._ty
  return (d * dx - c * dy) / det, (a * dy - b * dx) / det
end

---Moves the node to a point of the world, whatever its parents' places are.
---@param x number
---@param y number
function Node:setWorldPosition(x, y)
  local parent = self._parent
  if parent then
    x, y = parent:toLocal(x, y)
  end
  self.posX, self.posY = x, y
end

nodes.Node = Node
return nodes
