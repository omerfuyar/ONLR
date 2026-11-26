-- What the panels share: which nodes they show, the project's or the running game's (DESIGN 12.6).

local ecs = require("ecs")
local project = require("project")
local nodeview = require("nodeview")

local shared = {}

---Whether the node hierarchy and the inspector show the running game in place of a node file.
shared.running = false
---The chosen running node's number.
---@type integer?
shared.runningNode = nil
---The file that a click chose in the files panel, which the inspector shows until nodes are chosen (DESIGN 13.7).
---@type string?
shared.chosenFile = nil

-- What the node hierarchy and the inspector show changed: the running game or a node file, the chosen running node, or the file chosen
-- in the files panel. Their panel types redraw on it (redrawOn).
ecs.event.declare("shown", "What the node hierarchy and the inspector show changed: the running game or the node file, or the chosen file")

shared.inspectors = {} ---@type table<ecs.Panel, true> the open inspectors, beside which shown panels open

---Gives the focus to an open panel of a set, or opens one of the type, for an entry of the title bar's menus that shows a panel
---(DESIGN 13.2).
---@param typeName string
---@param open table<ecs.Panel, any> the open panels of the type
function shared.show(typeName, open)
  local panel = next(open)
  if panel then
    ecs.layout.focus(panel)
    return
  end
  -- as a tab beside an inspector, where the project's details are; beside the focused panel when no inspector is open
  local beside = next(shared.inspectors)
  local made, message = ecs.layout.open(typeName, nil, beside, beside and "center" or nil)
  if not made then
    require("console").add(message or (typeName .. " cannot open."), "warn", nil, "onlr")
  end
end

---Shows the running game, or the node file again.
---@param running boolean
function shared.setRunning(running)
  shared.running = running
  nodeview.watch(running, running and shared.runningNode and { shared.runningNode } or {})
  ecs.event.emit("onlr.shown")
end

---@param n integer?
function shared.chooseRunning(n)
  shared.runningNode = n
  nodeview.watch(true, n and { n } or {})
  ecs.event.emit("onlr.shown")
end

---Shows a file in the inspector, by its path in the project.
---@param path string?
function shared.chooseFile(path)
  shared.chosenFile = path
  ecs.event.emit("onlr.shown")
end

---The node file that the panels show: that of the chosen nodes.
---@return string?
function shared.file()
  local file = project.chosen().file
  if file and project.file(file) then
    return file
  end
end

-- Choosing nodes, or another project, takes the file out of the inspector.
for _, name in ipairs({ "onlr.chosen", "onlr.opened", "onlr.closed" }) do
  ecs.event.subscribe(name, function()
    shared.chosenFile = nil
  end)
end

ecs.event.subscribe("onlr.state", function()
  if shared.running and not nodeview.running().playing then
    shared.running, shared.runningNode = false, nil
    ecs.event.emit("onlr.shown")
  end
end)

---A name in words, as the inspector shows a property: cellSize as "Cell size".
---@param name string
---@return string
function shared.words(name)
  local text = name:gsub("(%l)(%u)", function(a, b)
    return a .. " " .. b:lower()
  end):gsub("_", " ")
  return text:sub(1, 1):upper() .. text:sub(2)
end

return shared
