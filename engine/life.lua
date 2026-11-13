-- The life of components (DESIGN 6.4), and the lists that a frame walks (DESIGN 8.2).
-- The engine keeps a record for each component: whether it is on, whether it runs, and whether it has started.
-- Scripts never see the records; they call node:setActive, component:setEnabled and the like, which act here.
-- A list holds the records of the components that have one function, in the tree's order, or for draw in the order of drawing.
-- A list that a change touches is built again from the tree the next time it is walked.

local life = {}

---A component's record, which only the engine keeps.
---@class onlr.Record
---@field component onlr.Component
---@field node onlr.Node
---@field type onlr.Type
---@field enabled boolean the component is on
---@field running boolean it is on, its node is in the tree and active, and it was not taken out
---@field alive boolean it has not been destroyed
---@field loaded boolean its load was called
---@field started boolean its start was called
---@field live boolean it gets start, events and the updates: it runs, is not paused, and a frame has ended since it started to run
---@field drawn boolean it draws: it runs, and a frame has ended since it started to run
---@field pending boolean it waits for the end of the frame, to become live or drawn
---@field removing boolean node:removeComponent was called on it
---@field removed boolean it was taken out, or is being taken out, of the tree
---@field holds string[] the keys of the files that it holds

---@type table<onlr.Component, onlr.Record>
life.records = {}

---The top node, which the tree sets (DESIGN 5).
---@type onlr.Node?
life.top = nil

---"game", or "edit" in the node view, where nothing changes the tree (DESIGN 6.5).
life.mode = "game"

-- Frame functions that lists keep: the updates, and the events that loop.event was asked for.
local walked = { fixedUpdate = true, update = true, lateUpdate = true }

---@type table<string, onlr.Record[]>
local lists = {}
local listsDirty = true

-- The tree's draw groups (DESIGN 5): the top's, and one for each node that draws as a group.
local topGroup
local drawDirty = true

---@type onlr.Record[]
local pending = {}
---@type onlr.Node[]
local doomed = {}
---@type onlr.Record[]
local removals = {}

---Raises an error when the node view runs: the functions that change the tree change nothing there (DESIGN 6.5).
---@param what string
function life.guard(what)
  if life.mode == "edit" then
    error(what .. " changes nothing in the node view", 3)
  end
end

local function dirty()
  listsDirty = true
  drawDirty = true
end
life.dirty = dirty

-- The records of a node and all under it, in the tree's order.
local function collect(node, out)
  for _, r in ipairs(node._records) do
    out[#out + 1] = r
  end
  for _, child in ipairs(node._children) do
    collect(child, out)
  end
  return out
end
life.collect = collect

local function call(r, name)
  local fn = r.component[name]
  if fn then
    fn(r.component)
  end
end

local function wait(r)
  if not r.pending then
    r.pending = true
    pending[#pending + 1] = r
  end
end

-- Starts or stops a component to match its flags, and calls enable or disable.
local function refresh(r)
  local run = r.alive and r.loaded and r.enabled and r.node._activeIn and not r.removed
  if run and not r.running then
    r.running = true
    wait(r)
    call(r, "enable")
  elseif not run and r.running then
    r.running = false
    r.live = false
    if r.drawn then
      r.drawn = false
      drawDirty = true
    end
    listsDirty = true
    call(r, "disable")
  end
end

---Calls load of every component of the nodes that just entered the tree, then enable of every one that runs (DESIGN 6.4).
---@param records onlr.Record[] in the tree's order
function life.enter(records)
  for _, r in ipairs(records) do
    r.loaded = true
    call(r, "load")
  end
  for _, r in ipairs(records) do
    refresh(r)
  end
  dirty()
end

-- Sets the flags that a node takes from those above it, for it and all under it.
local function inherit(node)
  local parent = node._parent
  node._activeIn = node._active and (not parent or parent._activeIn)
  node._pausedIn = node._paused or (parent ~= nil and parent._pausedIn)
  for _, child in ipairs(node._children) do
    inherit(child)
  end
end
life.inherit = inherit

-- Starts and stops the components of a node and all under it after a change of the flags:
-- what starts goes in the tree's order, and what stops in the reverse.
local function settle(node)
  local records = collect(node, {})
  for _, r in ipairs(records) do
    if not r.running then
      refresh(r)
    end
  end
  for i = #records, 1, -1 do
    if records[i].running then
      refresh(records[i])
    end
  end
end

---After node:setActive or node:setParent.
---@param node onlr.Node
function life.changed(node)
  local wasPaused = node._pausedIn
  inherit(node)
  settle(node)
  if wasPaused ~= node._pausedIn then
    life.paused(node)
  end
  dirty()
end

---After node:setPaused: a paused node's components stop getting calls at once, and a resumed one's get them from the next frame on.
---@param node onlr.Node
function life.paused(node)
  inherit(node)
  for _, r in ipairs(collect(node, {})) do
    if r.node._pausedIn then
      r.live = false
    elseif r.running then
      wait(r)
    end
  end
  listsDirty = true
end

---component:setEnabled.
---@param r onlr.Record
---@param enabled boolean
function life.setEnabled(r, enabled)
  r.enabled = enabled and true or false
  refresh(r)
end

---Marks a node for destruction when the frame ends.
---@param node onlr.Node
function life.destroy(node)
  if node._destroyed then
    return
  end
  local function mark(n)
    n._destroyed = true
    for _, child in ipairs(n._children) do
      mark(child)
    end
  end
  mark(node)
  doomed[#doomed + 1] = node
end

---Marks a component for removal when the frame ends.
---@param r onlr.Record
function life.remove(r)
  if not r.removing then
    r.removing = true
    removals[#removals + 1] = r
  end
end

-- Ends components: disable of those that run, then destroy, each in the reverse of the order given.
local function finish(records, data)
  for i = #records, 1, -1 do
    local r = records[i]
    if r.running then
      r.removed = true
      refresh(r)
    end
  end
  for i = #records, 1, -1 do
    local r = records[i]
    r.alive = false
    r.removed = true
    if r.loaded then
      call(r, "destroy")
    end
    for _, key in ipairs(r.holds) do
      data.release(key)
    end
    life.records[r.component] = nil
  end
end

---Ends every component of a node and all under it, and takes the node out of the tree.
---@param node onlr.Node
---@param data table the data module, which lets go of the files that they held
function life.finish(node, data)
  finish(collect(node, {}), data)
  local parent = node._parent
  if parent then
    local children = parent._children
    for i = #children, 1, -1 do
      if children[i] == node then
        table.remove(children, i)
      end
    end
    node._parent = nil
  end
  local function gone(n)
    n._gone = true
    for _, child in ipairs(n._children) do
      gone(child)
    end
  end
  gone(node)
  dirty()
end

---Takes out what was destroyed and removed. Called when the frame ends (DESIGN 8.1).
---@param data table the data module
function life.takeOut(data)
  while #doomed > 0 or #removals > 0 do
    local nodes, records = doomed, removals
    doomed, removals = {}, {}
    for _, node in ipairs(nodes) do
      if not node._gone then
        life.finish(node, data)
      end
    end
    for _, r in ipairs(records) do
      if r.alive then
        finish({ r }, data)
        local node = r.node
        for i, other in ipairs(node._records) do
          if other == r then
            table.remove(node._records, i)
            break
          end
        end
        require("onlr.component").take(node, r.type.name)
        dirty()
      end
    end
  end
end

-- The records that wait, in the tree's order.
local function waiting()
  local out = {}
  local function walk(node)
    for _, r in ipairs(node._records) do
      if r.pending then
        out[#out + 1] = r
      end
    end
    for _, child in ipairs(node._children) do
      walk(child)
    end
  end
  if life.top then
    walk(life.top)
  end
  for _, r in ipairs(pending) do
    r.pending = false
  end
  pending = {}
  return out
end

---Calls start of the components that started to run, and lets them draw and get the frame's functions from the next frame on.
---Called when the frame ends, and when the top node and the first root have loaded.
function life.startWaiting()
  while #pending > 0 do
    for _, r in ipairs(waiting()) do
      if r.running then
        if not r.drawn then
          r.drawn = true
          drawDirty = true
        end
        if not r.node._pausedIn and not r.live then
          if not r.started then
            r.started = true
            call(r, "start")
          end
          if r.running and not r.node._pausedIn then
            r.live = true
            listsDirty = true
          end
        end
      end
    end
  end
end

-- Builds every list of frame functions again from the tree.
local function rebuild()
  local names = {}
  for name in pairs(walked) do
    names[#names + 1] = name
    lists[name] = {}
  end
  local function walk(node)
    for _, r in ipairs(node._records) do
      if r.live then
        local component = r.component
        for _, name in ipairs(names) do
          if component[name] then
            local list = lists[name]
            list[#list + 1] = r
          end
        end
      end
    end
    for _, child in ipairs(node._children) do
      walk(child)
    end
  end
  if life.top then
    walk(life.top)
  end
  listsDirty = false
end

---Calls a function in every component that has it and is live, in the tree's order.
---@param name string
---@return boolean any whether a call returned true, which matters for quit only
function life.call(name, ...)
  if not walked[name] then
    walked[name] = true
    listsDirty = true
  end
  if listsDirty then
    rebuild()
  end
  local list = lists[name]
  local any = false
  for i = 1, #list do
    local r = list[i]
    if r.live then
      local component = r.component
      if component[name](component, ...) then
        any = true
      end
    end
  end
  return any
end

-- Draw groups (DESIGN 5). A group holds entries in the order of drawing: a component that draws, or a group inside it.
---@class onlr.Group
---@field node onlr.Node?
---@field trees onlr.Record[] the components whose drawTree draws the group, the first outermost
---@field entries table[]
---@field draw fun() draws the group, through its drawTree functions

local drawEntries

local function drawGroup(group)
  for _, entry in ipairs(group.entries) do
    local r = entry.record
    if r then
      if r.drawn then
        love.graphics.push()
        love.graphics.applyTransform(r.node:_drawTransform(life.drawing))
        r.component:draw()
        love.graphics.pop()
      end
    else
      entry.group.draw()
    end
  end
end
drawEntries = drawGroup

local function newGroup(node, trees)
  local group = { node = node, trees = trees, entries = {} }
  local fn = function()
    drawEntries(group)
  end
  for i = #trees, 1, -1 do
    local inner = fn
    local tree = trees[i].component
    fn = function()
      tree:drawTree(inner)
    end
  end
  group.draw = fn
  return group
end

local function byOrder(a, b)
  if a.z ~= b.z then
    return a.z < b.z
  end
  return a.seq < b.seq
end

local function rebuildDraw()
  local seq = 0
  local groups = {}
  local function walk(node, group, z)
    z = z + node._z
    local trees
    for _, r in ipairs(node._records) do
      if r.drawn and r.component.drawTree then
        trees = trees or {}
        trees[#trees + 1] = r
      end
    end
    if trees then
      local inner = newGroup(node, trees)
      seq = seq + 1
      group.entries[#group.entries + 1] = { group = inner, z = z, seq = seq }
      groups[#groups + 1] = inner
      group = inner
    end
    for _, r in ipairs(node._records) do
      if r.drawn and r.component.draw then
        seq = seq + 1
        group.entries[#group.entries + 1] = { record = r, z = z, seq = seq }
      end
    end
    for _, child in ipairs(node._children) do
      walk(child, group, z)
    end
  end
  topGroup = newGroup(nil, {})
  groups[1] = topGroup
  if life.top then
    walk(life.top, topGroup, 0)
  end
  for _, group in ipairs(groups) do
    local entries = group.entries
    for i = 2, #entries do
      if entries[i].z < entries[i - 1].z then
        table.sort(entries, byOrder)
        break
      end
    end
  end
  drawDirty = false
end

---Draws the tree: the components' draw in the order of drawing, and each group's drawTree in its place.
function life.draw()
  if drawDirty then
    rebuildDraw()
  end
  life.drawing = (life.drawing or 0) + 1
  topGroup.draw()
end

return life
