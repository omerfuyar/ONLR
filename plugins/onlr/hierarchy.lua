-- The node hierarchy (DESIGN 13.4): the tree of the node file whose view has the focus, from its first node.
-- An instance's nodes show from its base, marked as an instance's (DESIGN 13.5). It keeps the rows it shows until the tree, the
-- open nodes, the marks or the search change, and builds only those in view.

local ecs = require("ecs")
local ui = require("ui")
local project = require("project")
local nodeview = require("nodeview")
local console = require("console")
local fs = require("fs")
local shared = require("shared")

local STYLES = ui.styles()
local STATE_VERSION = 1

---A panel of the node hierarchy.
---@class onlr.editor.Hierarchy
---@field panel ecs.Panel
---@field open table<string, true> the open nodes of the node file, by path
---@field openFile string? the node file whose nodes open holds
---@field opened integer how many times open changed, which the kept rows compare
---@field openRunning table<integer, true> the open nodes of the running game, by number
---@field seenRunning table<integer, true> the running game's nodes shown once, which open the first time
---@field search string? the search's text
---@field renaming { file: string, path: string, text: string }? the node whose name the field above the tree asks for
---@field clicked string? the node clicked last, for a second click within 0.4 seconds
---@field rows table? the kept rows: the tree's nodes, the shown ones' paths, and what they were made from
local Hierarchy = {}
Hierarchy.__index = Hierarchy

-- the events whose change the panel shows (DESIGN 13.1)
local EVENTS = {
  "onlr.opened", "onlr.closed", "onlr.changed", "onlr.chosen", "onlr.state", "onlr.running:tree",
  "onlr.settings:hidden", "onlr.settings:locked",
}

local function say(_, message)
  if message then
    console.add(message, "warn")
  end
end

-- Whether a node matches a search: its name holds each word of the text, as every search of the tool matches
-- (ui.matches), or with "t:" first, the name of one of its components' types holds them, as Unity's search does.
-- Case does not count.
local function matches(node, search)
  local typeName = search:match("^t:%s*(.*)$")
  if typeName then
    for name in pairs(node.components or {}) do
      if ui.matches(typeName, name) then
        return true
      end
    end
    return false
  end
  return ui.matches(search, node.name or "")
end

-- The nodes of the tree element, from a node of the file: a closed node's children are not made, as they do not show. With a search,
-- only the nodes that match and those above them show, all open; nil when none under the node matches.
local function treeNodes(node, open, search, opened, marked)
  local label = node.name or "(no name)"
  if node.instanceOf then
    label = label .. "  (" .. node.instanceOf:match("[^/]*$") .. ")"
  end
  -- the eye and the lock of the node view (DESIGN 13.4): marks at the row's end, which a click turns; a hidden node is dimmed
  local hidden, locked = marked.hidden[node.path] == true, marked.locked[node.path] == true
  local marks = {
    { id = "hidden", text = "Hide", on = hidden, tooltip = hidden and "Hidden in the node view: a click shows it again" or "A click hides it in the node view", keys = "H" },
    { id = "locked", text = "Lock", on = locked, tooltip = locked and "Locked in the node view: a click lets it be chosen there again" or "A click keeps it from being chosen in the node view", keys = "L" },
  }
  local children
  if #node.children > 0 then
    children = {}
    if search or open[node.path] then
      for _, child in ipairs(node.children) do
        children[#children + 1] = treeNodes(child, open, search, opened, marked)
      end
      if search and #children == 0 then
        children = nil
      end
    end
  end
  if search then
    if not children and not matches(node, search) then
      return nil
    end
    opened[node.path] = true
  end
  local color = #node.errors > 0 and "#e06c75" or (not node.active or hidden) and "textDim" or not node.own and "accent" or nil
  return { id = node.path, label = label, color = color, children = children, marks = marks }
end

-- The running game's nodes, as the game sent them.
local function runningNodes(list, open, seen)
  local byNumber, tops = {}, {}
  for _, n in ipairs(list or {}) do
    local name = n.name ~= nil and n.name ~= "" and n.name or (n.parent and "(no name)" or "(top)")
    byNumber[n.n] = { id = n.n, label = name .. (n.root and "  (root)" or ""), color = not n.active and "textDim" or nil }
    -- a node shows open the first time it is seen
    if not seen[n.n] then
      seen[n.n], open[n.n] = true, true
    end
  end
  for _, n in ipairs(list or {}) do
    local parent = n.parent and byNumber[n.parent]
    if parent then
      parent.children = parent.children or {}
      parent.children[#parent.children + 1] = byNumber[n.n]
    else
      tops[#tops + 1] = byNumber[n.n]
    end
  end
  return tops
end

local function chosenNodes(file)
  local chosen = project.chosen()
  local tree = project.tree(file)
  local nodes = {}
  for _, path in ipairs(chosen.file == file and chosen.paths or {}) do
    nodes[#nodes + 1] = tree.index[path]
  end
  return nodes, tree
end

-- Moves the chosen node among its parent's children, out of its parent, or into the node before it.
local function reorder(file, how)
  local nodes, tree = chosenNodes(file)
  local node = nodes[1]
  local parent = node and node.parent
  if not parent then
    return
  end
  local at
  for i, child in ipairs(parent.children) do
    if child == node then
      at = i
    end
  end
  -- The place counts the parent's own children: those of its base come first, and stay.
  local base = 0
  for _, child in ipairs(parent.children) do
    if not child.own and not (child.holder and child.path == child.holder.id) then
      base = base + 1
    end
  end
  if how == "up" and at > 1 then
    say(project.moveNodes(file, { node.path }, parent.path, at - 1 - base))
  elseif how == "down" and at < #parent.children then
    say(project.moveNodes(file, { node.path }, parent.path, at + 1 - base))
  elseif how == "out" and parent.parent then
    say(project.moveNodes(file, { node.path }, parent.parent.path))
  elseif how == "in" and at > 1 then
    say(project.moveNodes(file, { node.path }, parent.children[at - 1].path))
  end
  local _ = tree
end

-- Whether a child is written in its parent's own list of children: one of the file's own, or an instance's first node. The children of a
-- base come first, and stay where they are.
local function written(child)
  return child.own or (child.holder ~= nil and child.path == child.holder.id)
end

local IMAGES = { png = true, jpg = true, jpeg = true, bmp = true, tga = true }

-- A drop on the tree (DESIGN 13.4). Dragged nodes move before, into or after the node that they land on: the chosen nodes when the dragged
-- one is chosen, or else the dragged one. A node file or an image from the files panel becomes a child of the node, as in the node view.
local function dropped(file, id, where, dataType, value)
  local tree = project.tree(file)
  local target = id and tree.index[id] or tree.first
  if not target or type(value) ~= "table" then
    return
  end
  if dataType == "file-list" then
    local made = {}
    for _, path in ipairs(value) do
      -- a file from outside the project is copied in first, after asking (DESIGN 13.4)
      local inside = project.bringIn(path)
      local ending = inside and (inside:match("%.(%w+)$") or ""):lower()
      local madeId, message
      if inside and inside:match("^nodes/.+%.lua$") then
        madeId, message = project.addInstance(file, target.path, inside, 0, 0)
      elseif inside and IMAGES[ending] then
        local name = inside:match("([^/]*)%.%w+$")
        madeId = project.addNode(file, target.path, { name = name:sub(1, 1):upper() .. name:sub(2), components = { onlr = { sprite = { image = inside } } } })
      end
      say(nil, message)
      made[#made + 1] = madeId
    end
    if #made > 0 then
      project.choose(file, made)
    end
    return
  end
  if dataType ~= "onlr.node" or value.file ~= file then
    return
  end
  local paths = { value.path }
  for _, path in ipairs(project.chosen().file == file and project.chosen().paths or {}) do
    if path == value.path then
      paths = project.chosen().paths
    end
  end
  local moving = {}
  for _, path in ipairs(paths) do
    moving[path] = true
  end
  if moving[target.path] then
    return
  end
  if where == "into" or not id or not target.parent then
    return say(project.moveNodes(file, paths, target.path))
  end
  -- the place among the parent's own children, without the nodes that move, which leave their places first
  local index = 1
  for _, child in ipairs(target.parent.children) do
    if child == target then
      break
    end
    if written(child) and not moving[child.path] then
      index = index + 1
    end
  end
  if where == "after" then
    index = index + 1
  end
  say(project.moveNodes(file, paths, target.parent.path, index))
end

-- Asks for a node's new name in the field above the tree, which gets the keys.
function Hierarchy:rename(file, path)
  local node = project.tree(file).index[path]
  if node then
    self.renaming = { file = file, path = path, text = node.name or "" }
    ui.edit(self.panel, "rename")
    self.panel:redraw()
  end
end

-- Opens or closes a node of the file.
function Hierarchy:setOpen(path, open)
  self.open[path] = open or nil
  self.opened = self.opened + 1
end

-- A new node file's path in nodes/, from a name: the name's own, or with a number after it when that is taken.
local function freePath(name)
  local base = (name or ""):gsub("[^%w_%-]+", "_"):lower()
  base = base ~= "" and base or "node"
  local path, number = "nodes/" .. base .. ".lua", 1
  while fs.info(project.folder() .. path) do
    number = number + 1
    path = ("nodes/%s_%d.lua"):format(base, number)
  end
  return path
end

-- The menu of a right click on the tree (DESIGN 13.4): about the chosen nodes, which the click chose when it was on a node that was not
-- chosen, or, beside the nodes, about the file.
function Hierarchy:menu(file, id, x, y)
  local tree = project.tree(file)
  local first = tree.first
  local paths = id and project.chosen().paths or {}
  local node = id and tree.index[id]
  local one = #paths == 1
  local function add(parent)
    local made = project.addNode(file, parent, {})
    if made then
      self:setOpen(parent, true)
      project.choose(file, { made })
    end
  end
  if not node then
    ui.menu(self.panel, x, y, {
      { label = "Add node", onClick = function() add(first.path) end },
      { line = true },
      { label = "New variant", onClick = function()
        local path = freePath(file:match("([^/]*)%.lua$") .. "_variant")
        local ok, message = project.newNodeFile(path, file)
        say(ok, message)
        if ok then
          nodeview.openFile(path)
        end
      end },
    })
    return
  end
  local isFirst = node == first
  -- where the node is among its parent's children, for the moves, which take one node
  local siblings = node.parent and node.parent.children or {}
  local at = 0
  for i, child in ipairs(siblings) do
    if child == node then
      at = i
    end
  end
  ui.menu(self.panel, x, y, {
    { label = "Add child", enabled = one, onClick = function() add(id) end },
    { label = "Rename", keys = "F2", enabled = one, onClick = function() self:rename(file, id) end },
    { label = "Duplicate", keys = "Ctrl+D", enabled = not isFirst, onClick = function()
      local made = project.duplicate(file, paths)
      if #made > 0 then
        project.choose(file, made)
      end
    end },
    { label = "Delete", keys = "Delete", enabled = not isFirst, onClick = function()
      say(project.deleteNodes(file, paths))
    end },
    { line = true },
    { label = "Select with children", keys = "Shift+A", onClick = nodeview.selectWithChildren },
    { label = "Select all", keys = "Ctrl+A", onClick = nodeview.selectAll },
    { line = true },
    { label = "Hide in the view", keys = "H", onClick = nodeview.hideChosen },
    { label = "Lock in the view", keys = "L", onClick = nodeview.lockChosen },
    { line = true },
    { label = "Move up", enabled = one and at > 1, onClick = function() reorder(file, "up") end },
    { label = "Move down", enabled = one and at > 0 and at < #siblings, onClick = function() reorder(file, "down") end },
    { label = "Move out of its parent", enabled = one and node.parent ~= nil and node.parent.parent ~= nil, onClick = function() reorder(file, "out") end },
    { label = "Move into the node above", enabled = one and at > 1, onClick = function() reorder(file, "in") end },
    { line = true },
    { label = "Save as node file", enabled = one, onClick = function()
      say(project.saveAsNodeFile(file, id, freePath(node.name)))
    end },
    { label = "Open base", enabled = one and node.instanceOf ~= nil, onClick = function()
      nodeview.openFile(node.instanceOf)
    end },
  })
end

-- The rows of the file's tree, kept until the tree, the open nodes, the marks or the search change: the tree element's nodes, and the
-- paths of the shown ones, in order.
function Hierarchy:rowsOf(file, tree)
  local hidden, locked, rows = project.setting("hidden"), project.setting("locked"), self.rows
  if rows and rows.tree == tree and rows.hidden == hidden and rows.locked == locked and rows.search == self.search and rows.opened == self.opened then
    return rows
  end
  local search = self.search
  local open = search and {} or self.open
  local top = treeNodes(tree.first, self.open, search, open, { hidden = nodeview.marks("hidden", file), locked = nodeview.marks("locked", file) })
  local shown = {}
  local function note(node)
    shown[#shown + 1] = node.id
    for _, child in ipairs(open[node.id] and node.children or {}) do
      note(child)
    end
  end
  if top then
    note(top)
  end
  rows = { tree = tree, hidden = hidden, locked = locked, search = search, opened = self.opened, nodes = { top }, open = open, shown = shown }
  self.rows = rows
  return rows
end

-- What a press on a node does: chooses it alone, adds it or takes it out with Ctrl, or chooses the shown ones from the last with Shift;
-- or, while the inspector waits for a pick, gives it to the pick (DESIGN 13.4).
function Hierarchy:select(file, paths, id, how, between)
  if nodeview.picking() then
    nodeview.pick(file, id)
    return
  end
  if how == "toggle" then
    local kept = {}
    for _, path in ipairs(paths) do
      if path ~= id then
        kept[#kept + 1] = path
      end
    end
    if #kept == #paths then
      table.insert(kept, 1, id)
    end
    project.choose(file, kept)
  elseif how == "range" then
    project.choose(file, between)
  else
    project.choose(file, { id })
  end
end

-- A second click on a node within 0.4 seconds, a double click, opens or closes it, as the files panel's does.
function Hierarchy:activate(id)
  if self.clicked == id then
    self.clicked = nil
    if not self.search then
      self:setOpen(id, not self.open[id])
    end
    return
  end
  self.clicked = id
  ecs.timer.start(0.4, false, function()
    if self.clicked == id then
      self.clicked = nil
    end
  end)
end

-- The tree of the node file, of which only the rows in view are built.
function Hierarchy:fileTree(file, children)
  local tree = project.tree(file)
  local chosen = project.chosen()
  children[#children + 1] = ui.text(file, { style = STYLES.heading })
  if tree.error then
    children[#children + 1] = ui.text(tree.error, { color = "#e06c75", wrap = true })
    return
  end
  if self.openFile ~= file then
    self.openFile, self.open = file, { [tree.first.path] = true }
    self.opened = self.opened + 1
  end
  local paths = chosen.file == file and chosen.paths or {}
  children[#children + 1] = ui.search(self.search or "", {
    placeholder = "Search nodes", tooltip = "Shows the nodes whose name holds each word; t: and words, those with a component of such a type", keys = "Ctrl+F",
    onChange = function(text)
      self.search = text ~= "" and text or nil
    end,
  })
  local rows = self:rowsOf(file, tree)
  local renaming = self.renaming
  if renaming and renaming.file == file then
    children[#children + 1] = ui.row({ gap = 4, align = "center" }, {
      ui.field(renaming.text, { id = "rename", grow = 1, tooltip = "Return takes the name", onChange = function(text)
        renaming.text = text
      end, onSubmit = function(text)
        self.renaming = nil
        project.setField(file, { renaming.path }, "name", text)
      end }),
      ui.button("Cancel", { id = "cancel", tooltip = "Close the field", keys = "Escape", onClick = function()
        self.renaming = nil
      end }),
    })
  end
  local first, last = ui.range(self.panel, "tree", #rows.shown)
  children[#children + 1] = ui.tree(rows.nodes, {
    id = "tree", open = rows.open, selected = paths, grow = 1, first = first, last = last,
    tooltip = "A drag moves a node before, into or after another, or to a reference in the inspector; a right click opens a menu",
    onSelect = function(id, how, between)
      self:select(file, paths, id, how, between)
    end,
    -- a click on a node's Hide or Lock turns that mark alone, and chooses nothing
    onMark = function(id, mark)
      nodeview.toggleMarks(mark, file, { id })
    end,
    onToggle = function(id, open)
      if not self.search then
        self:setOpen(id, open)
      end
    end,
    onActivate = function(id)
      self:activate(id)
    end,
    onMenu = function(id, x, y)
      self:menu(file, id, x, y)
    end,
    -- a node is dragged to another place in the tree, or to a reference's row of the inspector (DESIGN 13.4)
    onDrag = function(id)
      return "onlr.node", { file = file, path = id }
    end,
    onDrop = function(id, where, dataType, value)
      dropped(file, id, where, dataType, value)
    end,
  })
end

function Hierarchy:draw(surface)
  local file = shared.file()
  local running = nodeview.running()
  local children = {}

  if running.playing then
    children[#children + 1] = ui.selector(shared.running and 2 or 1, { "Node file", "Running game" }, {
      id = "mode", tooltip = "Show the node file, or the running game's tree, whose changes are gone at Stop",
      onSelect = function(choice)
        shared.setRunning(choice == 2)
      end,
    })
  end

  if shared.running and running.playing then
    children[#children + 1] = ui.text("The running game. A change here is gone at Stop.", { style = STYLES.note, wrap = true })
    children[#children + 1] = ui.tree(runningNodes(running.tree, self.openRunning, self.seenRunning), {
      id = "running", open = self.openRunning, selected = shared.runningNode, grow = 1,
      onSelect = shared.chooseRunning,
      onToggle = function(id, open)
        self.openRunning[id] = open or nil
      end,
    })
  elseif not file then
    children[#children + 1] = ui.text(project.folder() == "" and "No project is open." or "No node file is open.", { style = STYLES.note })
  else
    self:fileTree(file, children)
  end
  ui.show(self.panel, surface, ui.column({ padding = 8, gap = 6 }, children))
end

function Hierarchy.create(panel, saved, version)
  local self = setmetatable({ panel = panel, open = {}, opened = 0, openRunning = {}, seenRunning = {} }, Hierarchy)
  if version == STATE_VERSION and type(saved) == "table" then
    self.open, self.openFile = saved.open or {}, saved.file
  end
  shared.follow(panel, EVENTS)
  panel:acceptDrops({ "onlr.node", "file-list" })
  return self
end

function Hierarchy:event(event)
  -- F2 renames the chosen node, as in Unity.
  if event.type == "keyDown" and event.key == "F2" and not shared.running then
    local chosen = project.chosen()
    if chosen.file and #chosen.paths == 1 then
      self:rename(chosen.file, chosen.paths[1])
      return
    end
  end
  -- Ctrl+A chooses every node, unless a field being edited takes it to select its text: a binding would win over the field
  if not ui.event(self.panel, event) and event.type == "keyDown" and event.key == "A" and event.ctrl and not event.shift then
    nodeview.selectAll()
  end
end

function Hierarchy:saveState()
  -- What is chosen is the project's, and is not read back; a test reads it, and the marks' rectangles of the rows built, here.
  local chosen = project.chosen()
  local marks = {}
  for _, path in ipairs(self.rows and self.rows.shown or {}) do
    for _, mark in ipairs({ "hidden", "locked" }) do
      marks[path .. ":" .. mark] = ui.rect(self.panel, "tree:" .. path .. ":" .. mark)
    end
  end
  return { open = self.open, file = self.openFile, chosen = chosen.file == self.openFile and chosen.paths or {}, marks = marks }
end

function Hierarchy:destroy()
  shared.forget(self.panel)
  ui.forget(self.panel)
end

ecs.panel.registerType({
  name = "hierarchy",
  title = "Node Hierarchy",
  stateVersion = STATE_VERSION,
  create = Hierarchy.create,
  draw = Hierarchy.draw,
  event = Hierarchy.event,
  saveState = Hierarchy.saveState,
  destroy = Hierarchy.destroy,
})
