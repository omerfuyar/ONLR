-- The nodes panel (DESIGN 13.4): the tree of the node file whose view has the focus, from its first node.
-- An instance's nodes show from its base, marked as an instance's (DESIGN 13.5).

local ecs = require("ecs")
local ui = require("ui")
local project = require("onlr_project")
local player = require("onlr_player")
local console = require("console")
local shared = require("shared")

local STYLES = ui.styles()
local STATE_VERSION = 1

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
local function runningNodes(list)
  local byNumber, tops = {}, {}
  for _, n in ipairs(list or {}) do
    byNumber[n.n] = { id = n.n, label = (n.name or "(no name)") .. (n.root and "  (root)" or ""), color = not n.active and "textDim" or nil }
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
    children[#children + 1] = ui.text("The running game. A change here is gone at Stop.", { style = STYLES.note })
    children[#children + 1] = ui.tree(runningNodes(running.tree), {
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
      children[#children + 1] = ui.row({ gap = 4 }, {
        ui.button("Add", { id = "add", tooltip = "Add a node under the chosen one", onClick = function()
          local id = project.addNode(file, chosen.paths[1] or first.path, {})
          if id then
            state.open[chosen.paths[1] or first.path] = true
            project.choose(file, { id })
          end
        end }),
        ui.button("Delete", { id = "delete", onClick = function()
          say(project.deleteNodes(file, chosen.paths))
        end }),
        ui.button("Duplicate", { id = "duplicate", onClick = function()
          local made = project.duplicate(file, chosen.paths)
          if #made > 0 then
            project.choose(file, made)
          end
        end }),
      })
      children[#children + 1] = ui.row({ gap = 4 }, {
        ui.button("Up", { id = "up", tooltip = "Move before the node above", onClick = function()
          reorder(file, "up")
        end }),
        ui.button("Down", { id = "down", tooltip = "Move after the node below", onClick = function()
          reorder(file, "down")
        end }),
        ui.button("Out", { id = "out", tooltip = "Move out of its parent", onClick = function()
          reorder(file, "out")
        end }),
        ui.button("In", { id = "in", tooltip = "Move into the node above", onClick = function()
          reorder(file, "in")
        end }),
      })
      children[#children + 1] = ui.tree({ treeNodes(first, state.open) }, {
        id = "tree", open = state.open, selected = chosen.file == file and chosen.paths[1] or nil, grow = 1,
        onSelect = function(id)
          state.pressed = id
          project.choose(file, { id })
        end,
        onToggle = function(id, open)
          state.open[id] = open or nil
        end,
      })
      -- Save as Node File and New Variant take the new file's name (DESIGN 13.5).
      children[#children + 1] = ui.field(state.name, { id = "name", tooltip = "A new node file's name", onChange = function(text)
        state.name = text
      end })
      children[#children + 1] = ui.row({ gap = 4 }, {
        ui.button("Save as node file", { id = "saveAs", onClick = function()
          if chosen.paths[1] and state.name ~= "" then
            local ok, message = project.saveAsNodeFile(file, chosen.paths[1], "nodes/" .. state.name:gsub("%.lua$", "") .. ".lua")
            say(ok, message)
          end
        end }),
        ui.button("New variant", { id = "variant", tooltip = "A node file whose first node is an instance of this one", onClick = function()
          if state.name ~= "" then
            local path = "nodes/" .. state.name:gsub("%.lua$", "") .. ".lua"
            local ok, message = project.newNodeFile(path, file)
            say(ok, message)
            if ok then
              player.openFile(path)
            end
          end
        end }),
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
    local state = { panel = panel, open = {}, openRunning = {}, name = "" }
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
    return { open = state.open, file = state.openFile }
  end,
  destroy = function(state)
    shared.forget(state.panel)
    ui.forget(state.panel)
  end,
})
