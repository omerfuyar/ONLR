-- The history panel (DESIGN 13.6): every record of the history, the changes and the choices, as Unity's Undo History shows them.
-- A click on a record undoes or redoes until it is the last one done; the first row is the state before every record.

local ecs = require("ecs")
local ui = require("ui")
local project = require("project")

local STYLES = ui.styles()

local function draw(state, surface)
  local history = project.history()
  local rows = { ui.text("Before every change", { color = history.position == 0 and nil or "textDim" }) }
  for i, record in ipairs(history.records) do
    local names = {}
    for _, path in ipairs(record.files) do
      names[#names + 1] = path:match("[^/]*$")
    end
    local text = record.label .. (#names > 0 and ("   " .. table.concat(names, ", ")) or "")
    -- the records after the last one done are undone, and Redo or a click brings them back
    rows[#rows + 1] = ui.text(text, { color = i > history.position and "textDim" or nil })
  end
  local children = {}
  if project.folder() == "" then
    children[1] = ui.text("No project is open.", { style = STYLES.note })
  else
    children[1] = ui.list({
      id = "records", grow = 1, selected = history.position + 1,
      tooltip = "A click undoes or redoes until that record is the last one done",
      onSelect = function(item)
        project.goTo(item - 1)
      end,
    }, rows)
  end
  ui.show(state.panel, surface, ui.column({ padding = 8, gap = 6, grow = 1 }, children))
end

local panels = {} ---@type table<ecs.Panel, boolean>

ecs.panel.registerType({
  name = "history",
  title = "History",
  create = function(panel)
    panels[panel] = true
    return { panel = panel }
  end,
  draw = draw,
  event = function(state, event)
    ui.event(state.panel, event)
  end,
  saveState = function()
    -- not read back; a test reads the history's place here
    return { position = project.history().position }
  end,
  destroy = function(state)
    panels[state.panel] = nil
    ui.forget(state.panel)
  end,
})

-- The list follows every change and choice, every undo and redo, and the project that opens or closes.
for _, name in ipairs({ "onlr.changed", "onlr.chosen", "onlr.opened", "onlr.closed" }) do
  ecs.event.subscribe(name, function()
    for panel in pairs(panels) do
      panel:redraw()
    end
  end)
end

return {}
