-- The history panel (DESIGN 13.6): every record of the history, the changes and the choices, as Unity's Undo History shows them.
-- A click on a record undoes or redoes until it is the last one done; the first row is the state before every record. It builds only
-- the rows in view.

local ecs = require("ecs")
local ui = require("ui")
local project = require("project")

local STYLES = ui.styles()

---A panel of the history.
---@class onlr.editor.History
---@field panel ecs.Panel
local History = {}
History.__index = History

-- The text of a record's row: its label and the names of the files that it changed.
local function textOf(record)
  local names = {}
  for _, path in ipairs(record.files) do
    names[#names + 1] = path:match("[^/]*$")
  end
  return record.label .. (#names > 0 and ("   " .. table.concat(names, ", ")) or "")
end

function History:draw(surface)
  local children = {}
  if project.folder() == "" then
    children[1] = ui.text("No project is open.", { style = STYLES.note })
  else
    local history = project.history()
    -- row 1 is the state before every record, and row i + 1 the record i
    local first, last = ui.range(self.panel, "records", #history.records + 1)
    local rows = {}
    for row = first, last do
      local record = history.records[row - 1]
      -- the records after the last one done are undone, and Redo or a click brings them back
      rows[#rows + 1] = ui.text(record and textOf(record) or "Before every change", { color = row - 1 > history.position and "textDim" or nil })
    end
    children[1] = ui.list({
      id = "records", grow = 1, selected = history.position + 1, count = #history.records + 1, first = first,
      tooltip = "A click undoes or redoes until that record is the last one done",
      onSelect = function(item)
        project.goTo(item - 1)
      end,
    }, rows)
  end
  ui.show(self.panel, surface, ui.column({ padding = 8, gap = 6, grow = 1 }, children))
end

function History.create(panel)
  return setmetatable({ panel = panel }, History)
end

function History:event(event)
  ui.event(self.panel, event)
end

function History:saveState()
  -- not read back; a test reads the history's place here
  return { position = project.history().position }
end

function History:destroy()
  ui.forget(self.panel)
end

ecs.panel.registerType({
  name = "history",
  title = "History",
  -- the list follows every change and choice, every undo and redo, and the project that opens or closes
  redrawOn = { "onlr.changed", "onlr.chosen", "onlr.opened", "onlr.closed" },
  create = History.create,
  draw = History.draw,
  event = History.event,
  saveState = History.saveState,
  destroy = History.destroy,
})

return {}
