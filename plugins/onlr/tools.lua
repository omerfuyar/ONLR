-- The tools panel (DESIGN 13.3): the tool that every node view follows, snapping, and the functions of the game and of the history.

local ecs = require("ecs")
local ui = require("ui")
local project = require("project")
local player = require("nodeview")
local shared = require("shared")

local STYLES = ui.styles()
local TOOLS = { "move", "turn", "scale" }

local function draw(state, surface)
  local selected = 1
  for i, tool in ipairs(TOOLS) do
    if tool == project.tool() then
      selected = i
    end
  end
  local running = player.running()
  local history = project.historyState()
  ui.show(state.panel, surface, ui.column({ padding = 8, gap = 8 }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.selector(selected, { "Move", "Turn", "Scale" }, { id = "tool", tooltip = "What a drag on a node does: W, E and R", onSelect = function(choice)
        project.setTool(TOOLS[choice])
      end }),
      ui.selector(project.setting("pivot") == "own" and 2 or 1, { "Global", "Local" }, {
        id = "pivot", tooltip = "Many nodes turn and scale around their shared middle (Global), or each around its own place (Local)",
        onSelect = function(choice)
          project.setSetting("pivot", choice == 2 and "own" or "middle")
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
      ui.button("Play", { id = "play", tooltip = "Play the game from its start node: F5", onClick = player.play }),
      ui.button("Play this file", { id = "playFile", tooltip = "Play the focused node file as the start node: F6", onClick = player.playFile }),
      ui.button(running.paused and "Resume" or "Pause", { id = "pause", tooltip = "Pause or resume the game: F7", onClick = player.pause }),
      ui.button("Step", { id = "step", tooltip = "Run one frame of the paused game: F8", onClick = player.step }),
      ui.button("Stop", { id = "stop", tooltip = "Stop the game: Shift+F5", onClick = player.stop }),
      ui.text(running.playing and (running.paused and "Paused" or "Playing") or "", { style = STYLES.note }),
    }),
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
