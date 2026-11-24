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

local panels = {} ---@type table<ecs.Panel, boolean>
local listeners = {} ---@type table<string, table<ecs.Panel, boolean>> the panels that each event draws again

---Notes a panel that is drawn again at the events it shows: an event's name, such as "onlr.chosen", or a name and the first value that
---the event gives, such as "onlr.settings:grid" for a setting and "onlr.running:stats" for what the running game sent.
---@param panel ecs.Panel
---@param events string[]
function shared.follow(panel, events)
  panels[panel] = true
  for _, name in ipairs(events) do
    listeners[name] = listeners[name] or {}
    listeners[name][panel] = true
  end
end

---@param panel ecs.Panel
function shared.forget(panel)
  panels[panel] = nil
  for _, set in pairs(listeners) do
    set[panel] = nil
  end
end

---Draws every panel that follows the project again.
function shared.redraw()
  for panel in pairs(panels) do
    panel:redraw()
  end
end

-- Draws again the panels that show an event, and those that show its first value.
local function heard(name, value)
  for panel in pairs(listeners[name] or {}) do
    panel:redraw()
  end
  if type(value) == "string" then
    for panel in pairs(listeners[name .. ":" .. value] or {}) do
      panel:redraw()
    end
  end
end

---Shows the running game, or the node file again.
---@param running boolean
function shared.setRunning(running)
  shared.running = running
  nodeview.watch(running, running and shared.runningNode and { shared.runningNode } or {})
  shared.redraw()
end

---@param n integer?
function shared.chooseRunning(n)
  shared.runningNode = n
  nodeview.watch(true, n and { n } or {})
  shared.redraw()
end

---Shows a file in the inspector, by its path in the project.
---@param path string?
function shared.chooseFile(path)
  shared.chosenFile = path
  shared.redraw()
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

for _, name in ipairs({
  "onlr.opened", "onlr.closed", "onlr.changed", "onlr.chosen", "onlr.tool",
  "onlr.types", "onlr.saved", "onlr.settings", "onlr.running",
}) do
  ecs.event.subscribe(name, function(_, value)
    heard(name, value)
  end)
end

ecs.event.subscribe("onlr.state", function()
  if shared.running and not nodeview.running().playing then
    shared.running, shared.runningNode = false, nil
    shared.redraw()
  end
  heard("onlr.state")
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
