-- The editor's test (DESIGN 16): an OpenECS test that opens this sample, acts as a user would, and checks the files
-- that the editor writes. test.sh runs it on a copy of the sample, in build/tests/work/editor/.

---A file's text, or an empty text when there is no such file.
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
    local file
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

    -- Ctrl+D duplicates the chosen node: the copy has a new id, and names what the first one names
    x, y = at(56, 56)
    test.click(x, y)
    test.key("Ctrl+D")
    test.wait(0.2)
    save()
    local doubled = read("nodes/start.lua")
    local _, count = doubled:gsub('name = "A"', "")
    check(count == 2, "the node is there twice:\n" .. doubled)
    _, count = doubled:gsub('id = "aaaaaa"', "")
    check(count == 1, "the copy has an id of its own")
    _, count = doubled:gsub('target = "bbbbbb"', "")
    check(count == 2, "the copy names the node that the first one names")
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the copy is undone")

    -- Save as Node File writes the chosen node to a new node file, and puts an instance of it in its place
    test.click(x, y)
    test.wait(0.2)
    local nodes = test.rect(panelOf(test, "onlr_views.nodes"))
    -- the new file's name goes into the field at the panel's bottom, above the button
    test.click(nodes.x + 130, nodes.y + nodes.height - 55)
    test.wait()
    test.text("hero")
    test.click(nodes.x + 68, nodes.y + nodes.height - 22)
    test.wait(0.3)
    local hero = read("nodes/hero.lua")
    check(hero:find('id = "aaaaaa"') and hero:find("speed = 25"), "the new node file holds the node:\n" .. hero)
    check(not hero:find("bbbbbb"), "without the values that name a node outside it")
    test.click(x, y)
    save()
    local held = read("nodes/start.lua")
    check(held:find('base = "nodes/hero.lua"'), "an instance is in the node's place:\n" .. held)
    check(held:find('%["aaaaaa"%] = {\n            components = {\n              thing = {\n                friend = "bbbbbb",\n                target = "bbbbbb",'),
      "and its change sets the values that name the node outside")
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start and read("nodes/hero.lua") == hero, "undoing it puts the node back, and leaves the new file")
    os.remove("nodes/hero.lua")
    test.wait(0.3)

    -- the files panel renames a file: every path that names it changes with it, and the files are saved (DESIGN 13.7)
    local files = test.rect(panelOf(test, "files.tree"))
    test.click(files.x + 21, files.y + 130)
    test.wait(0.2)
    test.click(files.x + 80, files.y + 172)
    test.click(files.x + 80, files.y + 25)
    test.wait()
    test.text("piece.lua")
    test.click(files.x + 43, files.y + 58)
    test.wait(0.5)
    check(read("nodes/piece.lua") ~= "" and read("nodes/part.lua") == "", "the file has its new name")
    check(read("nodes/start.lua") == start:gsub("nodes/part.lua", "nodes/piece.lua"), "the instance names the file by its new name")
    -- the click opened the file in a node view, which follows it to its new name
    local followed = false
    for _, panel in ipairs(test.panels()) do
      followed = followed or (panel.type == "onlr_player.view" and panel.title == "piece.lua")
    end
    check(followed, "the node view shows the file under its new name")
    test.click(at(300, 300))
    test.call("ecs.layout.close")
    os.rename("nodes/piece.lua", "nodes/part.lua")
    file = assert(io.open("nodes/start.lua", "wb"))
    file:write(start)
    file:close()
    test.wait(0.5)

    -- a file that changes on disk is read again
    local part = read("nodes/part.lua"):gsub('name = "Part"', 'name = "Piece"')
    file = assert(io.open("nodes/part.lua", "wb"))
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
      if read("played.txt") ~= "" then
        break
      end
    end
    check(read("played.txt") == "Start", "the game played")
    test.key("Shift+F5")
    test.wait(0.5)

    -- Export: the folder that exports are written to is typed into the Export panel, which is a tab beside the inspector
    test.click(inspector.x + 210, inspector.y - 14)
    test.wait(0.2)
    local export = test.rect(panelOf(test, "onlr_export.panel"))
    test.click(export.x + 100, export.y + 50)
    test.key("Ctrl+A")
    test.text("out")
    test.key("Return")
    test.wait(0.2)

    -- the .love file is a zip archive of the project, without what starts with a dot and without the export's folder
    test.call("onlr_export.love")
    test.wait(0.3)
    local function list(command)
      local pipe = assert(io.popen(command))
      local text = pipe:read("a")
      pipe:close()
      return text
    end
    local love = list("unzip -l out/Editor.love")
    check(love:find(" main.lua\n") and love:find(" nodes/start.lua\n") and love:find(" packages/onlr/init.lua\n"), "the .love file holds the project:\n" .. love)
    check(not love:find("%.onlr") and not love:find("%d   out/"), "without .onlr/ and the export's folder")

    -- the Linux build is LÖVE's files with the .love file joined to LÖVE's executable: unpacked, its launcher runs the game
    test.call("onlr_export.linux")
    test.wait(1)
    os.execute("mkdir -p out/linux && tar -xzf out/Editor-linux-x86_64.tar.gz -C out/linux && cd out/linux && "
      .. "SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null timeout 3 ./Editor/Editor > /dev/null 2>&1")
    check(read("out/linux/played.txt") == "Start", "the Linux build runs the game")
    check(read("out/linux/Editor/license.txt") ~= "", "and holds LÖVE's license.txt")

    -- the Windows build is made from LÖVE's runtime, which is downloaded and checked against the hash that ONLR ships
    test.call("onlr_export.windows")
    for _ = 1, 300 do
      test.wait(0.1)
      if read("out/Editor-windows-x86_64.zip") ~= "" then
        break
      end
    end
    local windows = list("unzip -l out/Editor-windows-x86_64.zip")
    check(windows:find(" Editor/Editor.exe\n") and windows:find(" Editor/love.dll\n") and windows:find(" Editor/license.txt\n"),
      "the Windows build holds the game's executable, LÖVE's libraries and its license.txt:\n" .. windows)
    os.execute("cd out && unzip -q -o Editor-windows-x86_64.zip")
    check(list("unzip -l out/Editor/Editor.exe 2>&1"):find(" main.lua\n"), "the .love file is joined to the executable's end")

    -- no panel failed
    for _, panel in ipairs(test.panels()) do
      check(not test.panel(panel.id).fault, panel.type .. " failed: " .. tostring(test.panel(panel.id).fault))
    end
  end,
}
