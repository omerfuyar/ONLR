-- The editor's test of this sample (DESIGN 16): the node files here hold comments that a person wrote,
-- so the editor asks before a save replaces them (DESIGN 4.2).

---@return string
local function read(path)
  local file = io.open(path, "rb")
  if not file then
    return ""
  end
  local text = file:read("a")
  file:close()
  return text
end

local function check(condition, message)
  if not condition then
    error(message, 2)
  end
end

return {
  preset = "../../../../preset.lua",
  files = { "manifest.lua" },
  run = function(test)
    local level = read("nodes/level.lua")
    check(level:find("\n%s*%-%- "), "the sample's node file holds comments")
    local view
    for _, panel in ipairs(test.panels()) do
      if panel.type == "onlr_player.view" then
        view = test.rect(panel.id)
      end
    end
    test.wait(1.5)

    -- the score's text is at the window's top left: a drag moves it
    local x, y = view.x + 40 + 30, view.y + 40 + 24
    test.drag(x, y, x + 20, y)
    test.wait(0.3)

    -- the save asks first, since it writes the values only; the last button keeps the file
    test.key("Ctrl+S")
    local dialog = test.dialog()
    check(dialog and dialog.title == "Save nodes/level.lua", "the editor asks before it replaces a file that a person wrote")
    test.key("Escape")
    test.wait(0.2)
    check(read("nodes/level.lua") == level, "keeping the file leaves it as it was")

    -- the first button replaces it: the file is then as the editor writes it, without the comments
    test.key("Ctrl+S")
    check(test.dialog(), "the editor asks again")
    test.key("Return")
    test.wait(0.2)
    local written = read("nodes/level.lua")
    check(written:sub(1, 31) == "---@type onlr.NodeFile\nreturn {", "the file starts as the editor writes it:\n" .. written:sub(1, 80))
    check(not written:find("\n%s*%-%- "), "its comments are gone")
    check(written:find("posX = 36,"), "and it holds the moved node")

    -- the next save of the file asks nothing
    test.drag(x + 20, y, x + 40, y)
    test.wait(0.3)
    test.key("Ctrl+S")
    check(not test.dialog(), "a file that the editor wrote is saved without a question")
    test.wait(0.2)
    check(read("nodes/level.lua"):find("posX = 56,"), "the second move is saved")

    for _, panel in ipairs(test.panels()) do
      check(not test.panel(panel.id).fault, panel.type .. " failed: " .. tostring(test.panel(panel.id).fault))
    end
  end,
}
