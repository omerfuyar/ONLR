-- The editor's test (DESIGN 16): an OpenECS test that opens this sample, acts as a user would, and checks the files
-- that the editor writes. test.sh runs it on a copy of the sample, in build/tests/work/editor/.

local function read(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
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

-- The id of the panel of a type.
local function panelOf(test, type)
  for _, panel in ipairs(test.panels()) do
    if panel.type == type then
      return panel.id
    end
  end
  error("no panel " .. type)
end

return {
  preset = "../../../../preset.lua",
  files = { "manifest.lua" },
  run = function(test)
    local start, outer = read("nodes/start.lua"), read("nodes/outer.lua")
    local view = test.rect(panelOf(test, "onlr_player.view"))
    -- A node view starts with the world's point -40, -40 at its top left, at a zoom of 1.
    local function at(x, y)
      return view.x + x + 40, view.y + y + 40
    end
    local function save()
      test.key("Ctrl+S")
      test.wait(0.2)
    end
    -- the edit player starts, and answers what the types declare
    test.wait(1.5)
    test.match(test.panel(panelOf(test, "onlr_player.view")), { title = "start.lua", unsaved = false })

    -- a drag with the move tool moves the node under the pointer, as one change
    local x, y = at(56, 56)
    test.drag(x, y, x + 64, y + 32)
    test.wait(0.3)
    test.match(test.panel(panelOf(test, "onlr_player.view")), { unsaved = true })
    save()
    local moved = read("nodes/start.lua")
    check(moved == start:gsub("posX = 40,\n      posY = 40,", "posX = 104,\n      posY = 72,"), "a moved node changes its two lines only:\n" .. moved)
    test.match(test.panel(panelOf(test, "onlr_player.view")), { unsaved = false })

    -- undoing it gives the file's first text again: the same table always gives the same text
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "undo and save give the first text again")

    -- the inspector shows the chosen node: a new name, typed in its first field and ended with Return, is one change
    x, y = at(56, 56)
    test.click(x, y)
    test.wait(0.2)
    local inspector = test.rect(panelOf(test, "onlr_views.inspector"))
    test.click(inspector.x + 200, inspector.y + 52)
    test.key("Ctrl+A")
    test.text("Hero")
    test.key("Return")
    test.wait(0.2)
    test.click(x, y)
    save()
    check(read("nodes/start.lua") == start:gsub('name = "A"', 'name = "Hero"'), "the inspector renames the node:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the name is undone")

    -- a node of an instance's base is changed by a change of the instance
    x, y = at(208, 112)
    test.drag(x, y, x + 10, y + 20)
    test.wait(0.3)
    save()
    local changed = read("nodes/start.lua")
    check(changed:find('%["t1p000"%] = {\n            posX = 10,\n            posY = 84,\n          },'), "the instance holds the change:\n" .. changed)
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the change of the instance is undone, and its table with it")

    -- deleting a node clears what names it, in every node file, as one change
    x, y = at(136, 56)
    test.click(x, y)
    test.key("Delete")
    test.wait(0.3)
    save()
    local deleted = read("nodes/start.lua")
    check(not deleted:find("bbbbbb"), "the node is gone, and the properties that named it:\n" .. deleted)
    check(deleted:find("speed = 25"), "the node's other values stay")
    local outerNow = read("nodes/outer.lua")
    check(not outerNow:find("bbbbbb"), "another file's change and property that named the node are gone:\n" .. outerNow)
    check(outerNow:find('%["p4rt01/t1p000"%]'), "its other change stays")
    test.key("Ctrl+Z")
    test.wait(0.3)
    save()
    check(read("nodes/start.lua") == start and read("nodes/outer.lua") == outer, "one undo puts both files back")
    -- undoing a change of a file that no node view showed opened a view of it, which has the focus
    local opened = false
    for _, panel in ipairs(test.panels()) do
      opened = opened or (panel.type == "onlr_player.view" and panel.title == "outer.lua")
    end
    check(opened, "the undo opened a view of the other file")
    test.call("ecs.layout.close")
    test.wait(0.2)

    -- an image dropped into the node view makes a node with a sprite of it
    x, y = at(100, 150)
    local folder = os.getenv("PWD") .. "/"
    test.dropFiles(x, y, { folder .. "images/coin.png" })
    test.wait(0.3)
    test.match(test.panel(panelOf(test, "onlr_player.view")), { unsaved = true })
    save()
    local dropped = read("nodes/start.lua")
    check(dropped:find('name = "Coin",\n      posX = 100,\n      posY = %d+,'), "the dropped image is a node:\n" .. dropped)
    check(dropped:find('image = "images/coin.png"'), "with a sprite of the image")
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the drop is undone")

    -- a file that changes on disk is read again
    local part = read("nodes/part.lua"):gsub('name = "Part"', 'name = "Piece"')
    local file = assert(io.open("nodes/part.lua", "wb"))
    file:write(part)
    file:close()
    test.wait(0.5)
    -- the instance's first node has the base's new name: renaming it writes a change over that name
    x, y = at(216, 56)
    test.click(x, y)
    test.wait(0.2)
    test.click(inspector.x + 200, inspector.y + 80)
    test.key("Ctrl+A")
    test.text("Mine")
    test.key("Return")
    test.wait(0.2)
    test.click(x, y)
    save()
    check(read("nodes/start.lua"):find('%["p4rt00"%] = {\n            name = "Mine",'), "the instance's change holds the name:\n" .. read("nodes/start.lua"))
    -- typing the base's name again takes the change out: a value that equals its default is left out
    test.click(inspector.x + 200, inspector.y + 80)
    test.key("Ctrl+A")
    test.text("Piece")
    test.key("Return")
    test.wait(0.2)
    test.click(x, y)
    save()
    check(read("nodes/start.lua") == start, "the base's own name leaves no change")

    -- Play saves the project and runs the game, whose marker writes a file
    os.remove("played.txt")
    test.key("F5")
    for _ = 1, 50 do
      test.wait(0.1)
      if read("played.txt") then
        break
      end
    end
    check(read("played.txt") == "Start", "the game played")
    test.key("Shift+F5")
    test.wait(0.5)

    -- no panel failed
    for _, panel in ipairs(test.panels()) do
      check(not test.panel(panel.id).fault, panel.type .. " failed: " .. tostring(test.panel(panel.id).fault))
    end
  end,
}
