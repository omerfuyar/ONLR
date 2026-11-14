-- What the panels of onlr_views share: which nodes they show, the project's or the running game's (DESIGN 12.6).

local ecs = require("ecs")
local project = require("onlr_project")
local player = require("onlr_player")

local shared = {}

---Whether the nodes panel and the inspector show the running game in place of a node file.
shared.running = false
---The chosen running node's number.
---@type integer?
shared.runningNode = nil

local panels = {} ---@type table<ecs.Panel, boolean>

---Notes a panel that is drawn again whenever the project or the running game changes.
---@param panel ecs.Panel
function shared.follow(panel)
  panels[panel] = true
end

---@param panel ecs.Panel
function shared.forget(panel)
  panels[panel] = nil
end

function shared.redraw()
  for panel in pairs(panels) do
    panel:redraw()
  end
end

---Shows the running game, or the node file again.
---@param running boolean
function shared.setRunning(running)
  shared.running = running
  player.watch(running, running and shared.runningNode and { shared.runningNode } or {})
  shared.redraw()
end

---@param n integer?
function shared.chooseRunning(n)
  shared.runningNode = n
  player.watch(true, n and { n } or {})
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

for _, name in ipairs({
  "onlr_project.opened", "onlr_project.closed", "onlr_project.changed", "onlr_project.chosen", "onlr_project.tool",
  "onlr_project.types", "onlr_project.saved", "onlr_project.settings", "onlr_player.running",
}) do
  ecs.event.subscribe(name, shared.redraw)
end

ecs.event.subscribe("onlr_player.state", function()
  if shared.running and not player.running().playing then
    shared.running, shared.runningNode = false, nil
  end
  shared.redraw()
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
