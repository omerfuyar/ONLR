-- The life of components (DESIGN 6.4), and the lists that a frame walks (DESIGN 8.2).
-- The engine keeps a record for each component: whether it is on, whether it runs, and whether it has started.
-- Scripts never see the records; they call node:setActive, component:setEnabled and the like, which act here.
-- A list holds the records of the components that have one function, in the tree's order, or for draw in the order of drawing.
-- A record that stops stays in its list, which passes over it, and a record that starts again where it was needs nothing; one that
-- starts after the last of a list joins its end. Any other change builds the list again from the tree the next time it is walked.
---@diagnostic disable: invisible -- the engine reads the fields of its nodes that a script does not see

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
---@field entry table? its entry in its group's order of drawing
---@field listed integer? the build of the lists that holds it, which is listsBuild while it is in them
---@field shown integer? the build of the draw groups that holds its entry, which is drawBuild while it is in them

---@type table<onlr.Component, onlr.Record>
life.records = {}

---The top node, which the tree sets (DESIGN 5).
---@type onlr.Node?
life.top = nil

---The record whose function the engine calls now, which an error names (DESIGN 12.2). It is nil between the calls.
---@type onlr.Record?
life.current = nil

---"game", or "preview" in the node view, where nothing changes the tree (DESIGN 6.5).
life.mode = "game"

-- Frame functions that lists keep: the updates, and the events that loop.event was asked for.
local walked = { fixedUpdate = true, update = true, lateUpdate = true }

---@type table<string, onlr.Record[]>
local lists = {}
local listsDirty = true
-- Which build of the lists this is, and how many records in them stopped since, which they pass over until the next build.
local listsBuild, stale, listed = 0, 0, 0

-- The tree's draw groups (DESIGN 5): the top's, and one for each node that draws as a group.
local topGroup
local drawDirty = true
-- Which build of the draw groups this is, and how many of their entries stopped drawing since.
local drawBuild, drawStale, shown = 0, 0, 0
-- The group of each node that draws as one, as the last build made them.
local groupOf = setmetatable({}, { __mode = "k" })

---@type onlr.Record[]
local pending = {}
---@type onlr.Node[]
local doomed = {}
---@type onlr.Record[]
local removals = {}

---Raises an error when the node view runs: the functions that change the tree change nothing there (DESIGN 6.5).
---@param what string
function life.guard(what)
  if life.mode == "preview" then
    error(what .. " changes nothing in the node view", 3)
  end
end

---A number that each change of the tree raises: a node that joins, leaves, moves or is turned on or off, and a component that joins
---or leaves. A node's name is a field, which raises nothing. The game's runner sends the tree only when it changed (DESIGN 12.6).
life.version = 0

local function touched()
  life.version = life.version + 1
end

-- A change of the tree's order, such as a node that moved: every list is built again.
local function dirty()
  listsDirty = true
  drawDirty = true
  touched()
end
life.dirty = dirty

---After node:setZ: only the order of drawing changes.
function life.zChanged()
  drawDirty = true
end

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
    local outer = life.current
    life.current = r
    fn(r.component)
    life.current = outer
  end
end

local function wait(r)
  if not r.pending then
    r.pending = true
    pending[#pending + 1] = r
  end
end

local join, show

-- Starts or stops a component to match its flags, and calls enable or disable.
local function refresh(r)
  local run = r.alive and r.loaded and r.enabled and r.node._activeIn and not r.removed
  if run and not r.running then
    r.running = true
    wait(r)
    call(r, "enable")
  elseif not run and r.running then
    r.running = false
    if r.live and r.listed == listsBuild then
      stale = stale + 1
    end
    r.live = false
    if r.drawn then
      r.drawn = false
      -- a draw is passed over where it stands, but a group's drawTree draws the group whole
      if r.type.table.drawTree then
        drawDirty = true
      elseif r.shown == drawBuild then
        drawStale = drawStale + 1
      end
    end
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
  -- they join the lists when they start to run, at the frame's end
  touched()
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

---After node:setActive, or node:setParent, which moves it in the tree's order.
---@param node onlr.Node
---@param moved boolean?
function life.changed(node, moved)
  local wasPaused = node._pausedIn
  inherit(node)
  settle(node)
  if wasPaused ~= node._pausedIn then
    life.paused(node)
  end
  if moved then
    dirty()
  else
    touched()
  end
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
  -- what ended is destroyed, as destroy marks it, so a component that holds one of its nodes knows (DESIGN 6.4)
  local function gone(n)
    n._gone, n._destroyed = true, true
    for _, child in ipairs(n._children) do
      gone(child)
    end
  end
  gone(node)
  touched()
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
        require("onlr.library.component").take(node, r.type.name)
        touched()
      end
    end
  end
end

-- The tree's order.
local function depthOf(node)
  local depth = 0
  while node._parent do
    depth = depth + 1
    node = node._parent
  end
  return depth
end

-- Whether sibling a comes before sibling b. New nodes are the last children, so it looks from the end.
local function siblingBefore(a, b)
  local children = a._parent._children
  for i = #children, 1, -1 do
    local child = children[i]
    if child == a then
      return false
    elseif child == b then
      return true
    end
  end
  return false
end

-- Whether record a comes before record b in the tree's order: a node's own records, in their order, then its children's.
local function before(a, b)
  local na, nb = a.node, b.node
  if na == nb then
    for _, r in ipairs(na._records) do
      if r == a then
        return r ~= b
      elseif r == b then
        return false
      end
    end
    return false
  end
  local da, db = depthOf(na), depthOf(nb)
  local x, y = na, nb
  for _ = db + 1, da do
    x = x._parent
  end
  for _ = da + 1, db do
    y = y._parent
  end
  if x == y then
    -- one is above the other, and its records come first
    return da < db
  end
  while x._parent ~= y._parent do
    x, y = x._parent, y._parent
  end
  return not siblingBefore(y, x)
end

-- The records that wait, in the tree's order. A few are sorted; many, as when a level loads, are found by a walk of the tree.
local function waiting()
  if #pending <= 256 then
    local out = pending
    pending = {}
    for _, r in ipairs(out) do
      r.pending = false
    end
    for i = #out, 1, -1 do
      -- as the walk does, only the records of the tree
      local top = out[i].node
      while top and top._parent do
        top = top._parent
      end
      if top ~= life.top then
        table.remove(out, i)
      end
    end
    table.sort(out, before)
    return out
  end
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
          show(r)
        end
        if not r.node._pausedIn and not r.live then
          if not r.started then
            r.started = true
            call(r, "start")
          end
          if r.running and not r.node._pausedIn then
            r.live = true
            join(r)
          end
        end
      end
    end
  end
end

-- The frame functions that each type has, among those that lists are kept for. It is worked out again when a new name is walked.
local walkedVersion = 0

local function namesOf(info)
  if info.walkedVersion ~= walkedVersion then
    local names = {}
    for name in pairs(walked) do
      if type(info.table[name]) == "function" then
        names[#names + 1] = name
      end
    end
    info.walked, info.walkedVersion = names, walkedVersion
  end
  return info.walked
end

-- The last record of a list that is still live: what stopped is passed over.
local function lastLive(list)
  for i = #list, 1, -1 do
    if list[i].live then
      return list[i]
    end
  end
end

-- A record that started to run: it is in the lists already when it stopped and started again since they were built, or it joins
-- their ends when it comes after their last record. Else they are built again. Many stopped records build them again too, so
-- the lists do not grow.
function join(r)
  if listsDirty or r.listed == listsBuild then
    return
  end
  local names = namesOf(r.type)
  for i = 1, #names do
    local list = lists[names[i]]
    local last = list and lastLive(list)
    if not list or (last and not before(last, r)) then
      listsDirty = true
      return
    end
  end
  if stale > 64 + listed / 4 then
    listsDirty = true
    return
  end
  for i = 1, #names do
    local list = lists[names[i]]
    list[#list + 1] = r
  end
  r.listed = listsBuild
  listed = listed + 1
end

-- Builds every list of frame functions again from the tree.
local function rebuild()
  listsBuild, stale, listed = listsBuild + 1, 0, 0
  for name in pairs(walked) do
    lists[name] = {}
  end
  local function walk(node)
    local records = node._records
    for i = 1, #records do
      local r = records[i]
      if r.live then
        r.listed = listsBuild
        listed = listed + 1
        local names = namesOf(r.type)
        for j = 1, #names do
          local list = lists[names[j]]
          list[#list + 1] = r
        end
      end
    end
    local children = node._children
    for i = 1, #children do
      walk(children[i])
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
    walkedVersion = walkedVersion + 1
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
      life.current = r
      if component[name](component, ...) then
        any = true
      end
    end
  end
  life.current = nil
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
        life.current = r
        -- a draw that set a shader and did not set it back shades nothing after it; the shader is set only when it differs, since
        -- setting one ends a batch of LÖVE's draws (DESIGN 6.3)
        local shader = love.graphics.getShader()
        r.component:draw()
        if love.graphics.getShader() ~= shader then
          love.graphics.setShader(shader)
        end
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
    local record = trees[i]
    local tree = record.component
    fn = function()
      life.current = record
      tree:drawTree(inner)
    end
  end
  group.draw = fn
  return group
end

-- Puts a group's entries in the order of drawing: by z, and in the tree's order within one z.
-- The entries come in the tree's order, so they are split by z and joined again, the lowest z first.
local function order(group)
  local entries = group.entries
  local sorted = true
  for i = 2, #entries do
    if entries[i].z < entries[i - 1].z then
      sorted = false
      break
    end
  end
  if sorted then
    return
  end
  local byZ, zs = {}, {}
  for i = 1, #entries do
    local entry = entries[i]
    local bucket = byZ[entry.z]
    if not bucket then
      bucket = {}
      byZ[entry.z] = bucket
      zs[#zs + 1] = entry.z
    end
    bucket[#bucket + 1] = entry
  end
  table.sort(zs)
  local out = {}
  for _, z in ipairs(zs) do
    local bucket = byZ[z]
    for i = 1, #bucket do
      out[#out + 1] = bucket[i]
    end
  end
  group.entries = out
end

local function rebuildDraw()
  drawBuild, drawStale, shown = drawBuild + 1, 0, 0
  groupOf = setmetatable({}, { __mode = "k" })
  local groups = {}
  local function walk(node, group, z)
    z = z + node._z
    local records = node._records
    local trees
    for i = 1, #records do
      local r = records[i]
      if r.drawn and r.type.table.drawTree then
        trees = trees or {}
        trees[#trees + 1] = r
      end
    end
    if trees then
      local inner = newGroup(node, trees)
      group.entries[#group.entries + 1] = { group = inner, z = z }
      groups[#groups + 1] = inner
      groupOf[node] = inner
      group = inner
    end
    local entries = group.entries
    for i = 1, #records do
      local r = records[i]
      if r.drawn and r.type.table.draw then
        local entry = r.entry
        if not entry then
          entry = { record = r }
          r.entry = entry
        end
        entry.z = z
        r.shown = drawBuild
        shown = shown + 1
        entries[#entries + 1] = entry
      end
    end
    local children = node._children
    for i = 1, #children do
      walk(children[i], group, z)
    end
  end
  topGroup = newGroup(nil, {})
  groups[1] = topGroup
  if life.top then
    walk(life.top, topGroup, 0)
  end
  for _, group in ipairs(groups) do
    order(group)
  end
  drawDirty = false
end

-- A record that started to draw: its entry is in its group already when it stopped and started again since the groups were built.
-- Else the groups are built again, as they are after many stopped.
local function drawsAsGroup(node)
  for _, other in ipairs(node._records) do
    if other.drawn and other.type.table.drawTree then
      return true
    end
  end
  return false
end

-- A record that started to draw: its entry is in its group already when it stopped and started again since the groups were built.
-- A new one joins its group after the entries of its z and of lower ones, when they all come before it in the tree's order, as
-- a node spawned last does. Else the groups are built again, as they are after many stopped.
function show(r)
  if drawDirty or r.shown == drawBuild then
    return
  end
  local functions = r.type.table
  if functions.drawTree or drawStale > 64 + shown / 4 then
    drawDirty = true
    return
  elseif not functions.draw then
    return
  end
  -- its group, the nearest node above that draws as one, and its z, its own added to those above
  local group, z = nil, 0
  local node = r.node
  while node do
    z = z + node._z
    if not group then
      group = groupOf[node]
      if not group and drawsAsGroup(node) then
        -- a group that the last build did not make
        drawDirty = true
        return
      end
    end
    node = node._parent
  end
  group = group or topGroup
  local entries = group.entries
  local at = #entries
  while at >= 1 and entries[at].z > z do
    at = at - 1
  end
  for i = at, 1, -1 do
    local entry = entries[i]
    local other = entry.record or entry.group.trees[1]
    if other.drawn then
      if not before(other, r) then
        drawDirty = true
        return
      end
      break
    end
  end
  local entry = r.entry or { record = r }
  r.entry, entry.z, r.shown = entry, z, drawBuild
  shown = shown + 1
  table.insert(entries, at + 1, entry)
end

---Draws the tree: the components' draw in the order of drawing, and each group's drawTree in its place.
function life.draw()
  if drawDirty then
    rebuildDraw()
  end
  life.drawing = (life.drawing or 0) + 1
  topGroup.draw()
  life.current = nil
end

return life
