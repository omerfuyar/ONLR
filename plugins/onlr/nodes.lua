-- The nodes panel (DESIGN 13.4): the tree of the node file whose view has the focus, from its first node.
-- An instance's nodes show from its base, marked as an instance's (DESIGN 13.5).

local ecs = require("ecs")
local ui = require("ui")
local project = require("project")
local player = require("nodeview")
local console = require("console")
local fs = require("fs")
local shared = require("shared")

local STYLES = ui.styles()
local STATE_VERSION = 1
local menu

local function say(_, message)
  if message then
    console.add(message, "warn")
  end
end

-- The nodes of the tree element, from a node of the file.
local function treeNodes(node, open)
  local label = node.name or "(no name)"
  if node.instanceOf then
    label = label .. "  (" .. node.instanceOf:match("[^/]*$") .. ")"
  end
  local children
  if #node.children > 0 then
    children = {}
    for i, child in ipairs(node.children) do
      children[i] = treeNodes(child, open)
    end
  end
  local color = #node.errors > 0 and "#e06c75" or not node.active and "textDim" or not node.own and "accent" or nil
  return { id = node.path, label = label, color = color, children = children }
end

-- The running game's nodes, as the play player sent them.
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
menu = function(state, file, id, x, y)
  local tree = project.tree(file)
  local first = tree.first
  local paths = id and project.chosen().paths or {}
  local node = id and tree.index[id]
  local one = #paths == 1
  local function add(parent)
    local made = project.addNode(file, parent, {})
    if made then
      state.open[parent] = true
      project.choose(file, { made })
    end
  end
  if not node then
    ui.menu(state.panel, x, y, {
      { label = "Add node", onClick = function() add(first.path) end },
      { line = true },
      { label = "New variant", onClick = function()
        local path = freePath(file:match("([^/]*)%.lua$") .. "_variant")
        local ok, message = project.newNodeFile(path, file)
        say(ok, message)
        if ok then
          player.openFile(path)
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
  ui.menu(state.panel, x, y, {
    { label = "Add child", enabled = one, onClick = function() add(id) end },
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
    { label = "Move up", enabled = one and at > 1, onClick = function() reorder(file, "up") end },
    { label = "Move down", enabled = one and at > 0 and at < #siblings, onClick = function() reorder(file, "down") end },
    { label = "Move out of its parent", enabled = one and node.parent ~= nil and node.parent.parent ~= nil, onClick = function() reorder(file, "out") end },
    { label = "Move into the node above", enabled = one and at > 1, onClick = function() reorder(file, "in") end },
    { line = true },
    { label = "Save as node file", enabled = one, onClick = function()
      say(project.saveAsNodeFile(file, id, freePath(node.name)))
    end },
  })
end

local function draw(state, surface)
  local file = shared.file()
  local running = player.running()
  local children = {}

  if running.playing then
    children[#children + 1] = ui.selector(shared.running and 2 or 1, { "Node file", "Running game" }, {
      id = "mode",
      onSelect = function(choice)
        shared.setRunning(choice == 2)
      end,
    })
  end

  if shared.running and running.playing then
    children[#children + 1] = ui.text("The running game. A change here is gone at Stop.", { style = STYLES.note, wrap = true })
    children[#children + 1] = ui.tree(runningNodes(running.tree, state.openRunning, state.seenRunning), {
      id = "running", open = state.openRunning, selected = shared.runningNode, grow = 1,
      onSelect = shared.chooseRunning,
      onToggle = function(id, open)
        state.openRunning[id] = open or nil
      end,
    })
  elseif not file then
    children[#children + 1] = ui.text(project.folder() == "" and "No project is open." or "No node file is open.", { style = STYLES.note })
  else
    local tree = project.tree(file)
    local chosen = project.chosen()
    children[#children + 1] = ui.text(file, { style = STYLES.heading })
    if tree.error then
      children[#children + 1] = ui.text(tree.error, { color = "#e06c75", wrap = true })
    else
      local first = tree.first
      if state.openFile ~= file then
        state.openFile, state.open = file, { [first.path] = true }
      end
      local paths = chosen.file == file and chosen.paths or {}
      children[#children + 1] = ui.tree({ treeNodes(first, state.open) }, {
        id = "tree", open = state.open, selected = paths, grow = 1, tooltip = "A right click opens a menu of the nodes",
        onSelect = function(id, how, between)
          state.pressed = id
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
        end,
        onToggle = function(id, open)
          state.open[id] = open or nil
        end,
        onMenu = function(id, x, y)
          menu(state, file, id, x, y)
        end,
      })
    end
  end
  ui.show(state.panel, surface, ui.column({ padding = 8, gap = 6 }, children))
end

ecs.panel.registerType({
  name = "nodes",
  title = "Nodes",
  stateVersion = STATE_VERSION,
  create = function(panel, saved, version)
    local state = { panel = panel, open = {}, openRunning = {}, seenRunning = {} }
    if version == STATE_VERSION and type(saved) == "table" then
      state.open, state.openFile = saved.open or {}, saved.file
    end
    shared.follow(panel)
    return state
  end,
  draw = draw,
  event = function(state, event)
    -- A node is dragged out of the tree to a reference's row of the inspector (DESIGN 13.4).
    if event.type == "pointerDown" then
      state.pressed, state.pressX, state.pressY = nil, event.x, event.y
    elseif event.type == "pointerMove" and state.pressed and not shared.running then
      if math.abs(event.x - state.pressX) + math.abs(event.y - state.pressY) > 8 then
        state.panel:startDrag("onlr.node", { file = shared.file(), path = state.pressed })
        state.pressed = nil
      end
    elseif event.type == "pointerUp" then
      state.pressed = nil
    end
    ui.event(state.panel, event)
  end,
  saveState = function(state)
    -- What is chosen is the project's, and is not read back; a test reads it here.
    local chosen = project.chosen()
    return { open = state.open, file = state.openFile, chosen = chosen.file == state.openFile and chosen.paths or {} }
  end,
  destroy = function(state)
    shared.forget(state.panel)
    ui.forget(state.panel)
  end,
})
