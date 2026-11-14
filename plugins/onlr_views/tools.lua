-- The tools panel (DESIGN 13.3): the tool that every node view follows, snapping, and the functions of the game and of the history.

local ecs = require("ecs")
local ui = require("ui")
local project = require("onlr_project")
local player = require("onlr_player")
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
      ui.selector(selected, { "Move", "Turn", "Scale" }, { id = "tool", onSelect = function(choice)
        project.setTool(TOOLS[choice])
      end }),
      ui.toggle(project.setting("snap") == true, { id = "snap", label = "Snap", onChange = function(on)
        project.setSetting("snap", on)
      end }),
      ui.text("Grid", {}),
      ui.number(project.setting("grid") or 32, { id = "grid", width = 70, min = 1, onSubmit = function(value)
        project.setSetting("grid", value)
      end }),
    }),
    ui.row({ gap = 8, align = "center" }, {
      ui.button("Play", { id = "play", onClick = player.play }),
      ui.button("Play this file", { id = "playFile", onClick = player.playFile }),
      ui.button(running.paused and "Resume" or "Pause", { id = "pause", onClick = player.pause }),
      ui.button("Step", { id = "step", onClick = player.step }),
      ui.button("Stop", { id = "stop", onClick = player.stop }),
      ui.text(running.playing and (running.paused and "Paused" or "Playing") or "", { style = STYLES.note }),
    }),
    ui.row({ gap = 8, align = "center" }, {
      ui.button("Undo", { id = "undo", onClick = project.undo }),
      ui.button("Redo", { id = "redo", onClick = project.redo }),
      ui.button("Save", { id = "save", onClick = project.save }),
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
