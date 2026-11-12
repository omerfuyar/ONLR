-- A test drives the tool as a user would, and checks the session. Debug builds of OpenECS run it: OpenECS --test test.lua

-- the board's saved state, in the session that quitting would save now
local function board(test)
  return test.session().workspaces[1].windows[1][1].panels[1].state
end

return {
  preset = "preset.lua",
  run = function(test)
    local panel = test.rect(1)

    -- a click in the field gives it the keys; typed text and Return add a note, and the field lets the keys go
    for _, note in ipairs({ "Buy milk", "Call home" }) do
      test.click(panel.x + 40, panel.y + 30)
      test.text(note)
      test.key("Return")
    end
    test.match(board(test), { notes = { "Buy milk", "Call home" } }, "after two notes")
    test.match(test.panel(1), { title = "Notes (2)" })

    -- no field has the keys, so Delete reaches the board's binding, which removes the chosen note, the first
    test.key("Delete")
    test.match(board(test), { notes = { "Call home" } }, "after Delete")

    -- the C plugin's panel opened beside it
    test.match(test.panel(2), { type = "pulse_c.panel" })
  end,
}
