-- The tools panel (DESIGN 13.3): the tool that every node view follows, snapping, and the functions of the game and of the history.

local ecs = require("ecs")
local ui = require("ui")
local project = require("project")
local nodeview = require("nodeview")
local shared = require("shared")

local STYLES = ui.styles()
local TOOLS = { "move", "turn", "scale", "shape" }
-- The pivots, as the project keeps them (DESIGN 13.3).
local PIVOTS = { "own", "bounds", "selection" }
local PIVOT_INDEX = { own = 1, bounds = 2, selection = 3 }

-- The game's count: frames a second, and the time of update and draw, which a game with its own love.run does not send.
local function stats(s)
  local text = ("%d frames a second"):format(s.fps or 0)
  if s.update and s.draw then
    text = text .. ("   update %.2f ms   draw %.2f ms"):format(s.update, s.draw)
  end
  return text
end

local function draw(state, surface)
  local selected = 1
  for i, tool in ipairs(TOOLS) do
    if tool == project.tool() then
      selected = i
    end
  end
  local running = nodeview.running()
  local history = project.historyState()
  ui.show(state.panel, surface, ui.column({ padding = 8, gap = 8 }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.selector(selected, { "Move", "Turn", "Scale", "Shape" }, { id = "tool", tooltip = "What a drag on a node does: W, E, R and T. Shape drags a shape's corners and edges and the points of a property", onSelect = function(choice)
        project.setTool(TOOLS[choice])
      end }),
      ui.selector(PIVOT_INDEX[project.setting("pivot")] or 1, { "Own place", "Own middle", "Selection" }, {
        id = "pivot", tooltip = "What the chosen nodes turn and scale around, where the gizmo is: each node's own place, the middle of each node's bounds, or the middle of all of them",
        onSelect = function(choice)
          project.setSetting("pivot", PIVOTS[choice])
        end,
      }),
      ui.toggle(project.setting("snap") == true, { id = "snap", label = "Snap", tooltip = "Whether moved nodes keep to the grid", onChange = function(on)
        project.setSetting("snap", on)
      end }),
      ui.text("Grid", {}),
      ui.number(project.setting("grid") or 32, { id = "grid", width = 70, min = 1, tooltip = "The grid's size", onSubmit = function(value)
        project.setSetting("grid", value)
      end }),
    }),
    ui.row({ gap = 8, align = "center" }, {
      ui.button("Play", { id = "play", tooltip = "Play the game from its start node: F5", onClick = nodeview.play }),
      ui.button("Play this file", { id = "playFile", tooltip = "Play the focused node file as the start node: F6", onClick = nodeview.playFile }),
      ui.button(running.paused and "Resume" or "Pause", { id = "pause", tooltip = "Pause or resume the game: F7", onClick = nodeview.pause }),
      ui.button("Step", { id = "step", tooltip = "Run one frame of the paused game: F8", onClick = nodeview.step }),
      ui.button("Stop", { id = "stop", tooltip = "Stop the game: Shift+F5", onClick = nodeview.stop }),
      ui.text(running.playing and (running.halted and "Stopped at an error: its nodes show as it left them" or running.paused and "Paused" or "Playing") or "",
        { style = STYLES.note, color = running.halted and "#e06c75" or nil }),
    }),
    running.playing and running.stats and ui.text(stats(running.stats), {
      id = "stats", style = STYLES.note, tooltip = "The game's frames a second, and the time that a frame spends in update and in draw",
    }) or false,
    ui.row({ gap = 8, align = "center" }, {
      ui.button("Undo", { id = "undo", tooltip = "Take back the last change or choice: Ctrl+Z", onClick = project.undo }),
      ui.button("Redo", { id = "redo", tooltip = "Do again what Undo took back: Ctrl+Y", onClick = project.redo }),
      ui.button("Save", { id = "save", tooltip = "Save every changed file: Ctrl+S", onClick = project.save }),
      ui.text(("%d of %d changes"):format(history.position, history.count), { style = STYLES.note }),
      ui.text(project.isDirty() and "Not saved" or "", { style = STYLES.note }),
    }),
  }))
end

ecs.panel.registerType({
  name = "tools",
  title = "Tools",
  create = function(panel)
    shared.follow(panel)
    return { panel = panel }
  end,
  draw = draw,
  event = function(state, event)
    ui.event(state.panel, event)
  end,
  destroy = function(state)
    shared.forget(state.panel)
    ui.forget(state.panel)
  end,
})
