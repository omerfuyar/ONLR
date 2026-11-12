-- A board of short notes: a list to choose from, a field to write a new one, and buttons. It shows the parts most plugins use:
-- a panel type, a standard plugin (ui), a setting, a function bound to a key, and state saved in the session.

local ecs = require("ecs") -- the plugin interface; each plugin gets its own
local ui = require("ui")   -- the functions of the ui plugin, which the manifest depends on

-- ui's own styles, which its standard views use too
local STYLES = ui.styles()

-- version of the state a board saves; a board restores only a state of this version
local STATE_VERSION = 1

local boards = {} -- every open board, by its panel handle

-- a setting: the settings window (Alt+W, then ",") lists it, and the user's settings file can change it
-- the name is local: OpenECS declares it as "notes.newestFirst"
ecs.setting.declare({
  name = "newestFirst",
  type = "bool",
  description = "Show the newest note at the top of the board",
  default = true,
  changed = function()
    for panel in pairs(boards) do
      panel:redraw()
    end
  end,
})

-- the notes in the order the setting asks for, each with its place in board.notes
local function shown(board)
  local list = {}

  for i, note in ipairs(board.notes) do
    list[#list + 1] = { index = i, text = note }
  end

  if ecs.setting.get("notes.newestFirst") then
    table.sort(list, function(a, b)
      return a.index > b.index
    end)
  end

  return list
end

local function add(board, text)
  if text ~= "" then
    board.notes[#board.notes + 1] = text
    board.draft = ""
    board.panel.title = ("Notes (%d)"):format(#board.notes)
  end
end

local function remove(board)
  local note = shown(board)[board.selected]

  if note then
    table.remove(board.notes, note.index)
    board.selected = math.min(board.selected, #board.notes)
    board.panel.title = ("Notes (%d)"):format(#board.notes)
    board.panel:redraw()
  end
end

ecs.panel.registerType({
  name = "board", -- the local name; presets name the type "notes.board"
  title = "Notes",
  stateVersion = STATE_VERSION,

  -- runs when a board opens; saved is what saveState gave when the session was saved, or nil for a new board
  create = function(panel, saved, version)
    local board = { panel = panel, notes = {}, draft = "", selected = 1 }

    if version == STATE_VERSION and saved then
      board.notes = saved.notes or {}
    end

    panel.title = ("Notes (%d)"):format(#board.notes)
    boards[panel] = board
    return board
  end,

  -- runs when the board needs drawing: ui lays out and draws the elements described here, each time
  draw = function(board, surface)
    local items = {}

    for _, note in ipairs(shown(board)) do
      items[#items + 1] = ui.row({ padding = 4 }, { ui.text(note.text) })
    end

    if #items == 0 then
      items[1] = ui.text("No notes yet.", { style = STYLES.note, selectable = false })
    end

    ui.show(board.panel, surface, ui.column({ padding = 16, gap = 8 }, {
      ui.row({ gap = 8 }, {
        ui.field(board.draft, {
          id = "draft",
          grow = 1,
          onChange = function(text) board.draft = text end,
          onSubmit = function(text) add(board, text) end,
        }),
        ui.button("Add", { onClick = function() add(board, board.draft) end }),
        ui.button("Remove", { onClick = function() remove(board) end }),
      }),
      ui.list({
        id = "notes",
        selected = board.selected,
        onSelect = function(index) board.selected = index end,
      }, items),
    }))
  end,

  -- the panel's events go to ui, which calls the callbacks of the elements they reach
  event = function(board, event)
    ui.event(board.panel, event)
  end,

  -- what the session keeps of the board
  saveState = function(board)
    return { notes = board.notes }
  end,

  destroy = function(board)
    ui.forget(board.panel)
    boards[board.panel] = nil
  end,
})

-- a function that keys and other plugins can run; its full name is "notes.remove"
ecs.service.register({
  remove = {
    sig = "void(handle<ecs.panel> panel)",
    doc = "Remove the chosen note",
    fn = function(panel)
      local board = boards[panel]

      -- a key in the board's field types text, so Delete removes a note only while no field has the keys
      if board and not ui.focus(panel) then
        remove(board)
      end
    end,
  },
})

-- Delete runs it while a board has the focus; presets and the user's settings can change the key
ecs.key.bind("notes.board", "Delete", "notes.remove")
ecs.panel.addMenuEntry("notes.board", "notes.remove")
