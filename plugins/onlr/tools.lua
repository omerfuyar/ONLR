-- The tools' panels (DESIGN 13.1 and 13.3), each a bar of ui: Transform, the tool that every node view follows, its pivot and snapping;
-- Game, the functions of the game and how it plays; and Action, the history's functions and Save.

local ecs = require("ecs")
local ui = require("ui")
local project = require("project")
local nodeview = require("nodeview")
local runners = require("runners")

local STYLES = ui.styles()
local TOOLS = { "move", "turn", "scale", "rect", "shape" }
-- The pivots, as the project keeps them (DESIGN 13.3).
local PIVOTS = { "own", "bounds", "selection" }
local PIVOT_INDEX = { own = 1, bounds = 2, selection = 3 }
-- A bar is one row that wraps, so a narrow panel takes the rest to the next line and every control stays visible.
local BAR = { style = STYLES.bar, gap = 8, align = "center", wrap = true, grow = 1 }

---Transform: the tool, the pivot, snapping and the grid.
---@class onlr.editor.Transform
---@field panel ecs.Panel
local Transform = {}
Transform.__index = Transform

function Transform.create(panel)
  return setmetatable({ panel = panel }, Transform)
end

function Transform:view()
  local selected = 1
  for i, tool in ipairs(TOOLS) do
    if tool == project.tool() then
      selected = i
    end
  end
  return ui.row(BAR, {
    ui.selector(selected, { "Move", "Turn", "Scale", "Rect", "Shape" }, {
      id = "tool", keys = "W, E, R, T, Y",
      tooltip = "What a drag on a node does. Rect sizes a node by its corners and edges; Shape drags a shape's corners and edges and the points of a property",
      onSelect = function(choice)
        project.setTool(TOOLS[choice])
      end,
    }),
    ui.dropdown(PIVOT_INDEX[project.setting("pivot")] or 1, { "Own place", "Own middle", "Selection" }, {
      id = "pivot", width = 130, tooltip = "What the chosen nodes turn and scale around, where the gizmo is: each node's own place, the middle of each node's bounds, or the middle of all of them",
      onSelect = function(choice)
        project.setSetting("pivot", PIVOTS[choice])
      end,
    }),
    ui.toggle(project.setting("snap") == true, { id = "snap", label = "Snap", tooltip = "Whether moved nodes keep to the grid; Ctrl held in a drag flips it", onChange = function(on)
      project.setSetting("snap", on)
    end }),
    ui.text("Grid", {}),
    ui.number(project.setting("grid") or 32, { id = "grid", width = 70, min = 1, tooltip = "The grid's size", onSubmit = function(value)
      project.setSetting("grid", value)
    end }),
  })
end

-- The game's count: frames a second, and the time of update and draw, which a game with its own love.run does not send.
local function stats(s)
  local text = ("%d frames a second"):format(s.fps or 0)
  if s.update and s.draw then
    text = text .. ("   update %.2f ms   draw %.2f ms"):format(s.update, s.draw)
  end
  return text
end

local sizes = {}
for i, size in ipairs(runners.SIZES) do
  sizes[i] = size.label
end

-- the place of the project's Play size in runners.SIZES; a size that the list lacks shows as the manifest's
local function sizeIndex()
  local chosen = project.setting("playSize")
  for i, size in ipairs(runners.SIZES) do
    if size.size == chosen then
      return i
    end
  end
  return 1
end

---Game: Play, Play This File, Pause, Step and Stop, the window to play in, and while a game plays its state and its frames a second.
---@class onlr.editor.Game
---@field panel ecs.Panel
local Game = {}
Game.__index = Game

function Game.create(panel)
  return setmetatable({ panel = panel }, Game)
end

function Game:view()
  local running = nodeview.running()
  local note = running.playing and (running.halted and "Stopped at an error: its nodes show as it left them" or running.paused and "Paused" or "Playing") or ""
  return ui.row(BAR, {
    ui.button("Play", { id = "play", tooltip = "Play the game from its start node", keys = "F5", onClick = nodeview.play }),
    ui.button("Play this file", { id = "playFile", tooltip = "Play the focused node file as the start node", keys = "F6", onClick = nodeview.playFile }),
    ui.button(running.paused and "Resume" or "Pause", { id = "pause", tooltip = "Pause or resume the game", keys = "F7", onClick = nodeview.pause }),
    ui.button("Step", { id = "step", tooltip = "Run one frame of the paused game", keys = "F8", onClick = nodeview.step }),
    ui.button("Stop", { id = "stop", tooltip = "Stop the game", keys = "Shift+F5", onClick = nodeview.stop }),
    ui.text("Window", {}),
    ui.dropdown(sizeIndex(), sizes, { id = "playSize", width = 170, tooltip = "The size of the game's window when it plays, such as a phone's, for the run only: the manifest keeps its own", onSelect = function(choice)
      project.setSetting("playSize", runners.SIZES[choice].size)
    end }),
    ui.text(note, { style = STYLES.note, color = running.halted and "error" or nil }),
    running.playing and running.stats and ui.text(stats(running.stats), {
      id = "stats", style = STYLES.note, tooltip = "The game's frames a second, and the time that a frame spends in update and in draw",
    }) or false,
  })
end

function Game:saveState()
  -- not read back; a test finds the Window's dropdown here
  return { playSize = ui.rect(self.panel, "playSize") }
end

---Action: Undo, Redo and Save, with the history's count.
---@class onlr.editor.Action
---@field panel ecs.Panel
local Action = {}
Action.__index = Action

function Action.create(panel)
  return setmetatable({ panel = panel }, Action)
end

function Action:view()
  local history = project.historyState()
  return ui.row(BAR, {
    ui.button("Undo", { id = "undo", tooltip = "Take back the last change or choice", keys = "Ctrl+Z", onClick = project.undo }),
    ui.button("Redo", { id = "redo", tooltip = "Do again what Undo took back", keys = "Ctrl+Y", onClick = project.redo }),
    ui.button("Save", { id = "save", tooltip = "Save every changed file", keys = "Ctrl+S", onClick = project.save }),
    ui.text(("%d of %d changes%s"):format(history.position, history.count, project.isDirty() and ", not saved" or ""), { id = "count", style = STYLES.note }),
  })
end

-- Each bar redraws at the events that change what it shows (DESIGN 13.1).
ecs.panel.registerType(ui.panelType({
  name = "transform",
  title = "Transform",
  redrawOn = { "onlr.opened", "onlr.closed", "onlr.tool", "onlr.settings" },
  create = Transform.create, view = Transform.view,
}))
ecs.panel.registerType(ui.panelType({
  name = "game",
  title = "Game",
  redrawOn = { "onlr.opened", "onlr.closed", "onlr.state", "onlr.runningStats", "onlr.settings" },
  create = Game.create, view = Game.view, saveState = Game.saveState,
}))
ecs.panel.registerType(ui.panelType({
  name = "action",
  title = "Action",
  redrawOn = { "onlr.opened", "onlr.closed", "onlr.changed", "onlr.chosen", "onlr.saved" },
  create = Action.create, view = Action.view,
}))
