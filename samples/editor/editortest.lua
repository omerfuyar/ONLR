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
    local view = test.rect(panelOf(test, "onlr.view"))
    -- A node view starts with the world's point -40, -40 at its top left, at a zoom of 1.
    local function at(x, y)
      return view.x + x + 40, view.y + y + 40
    end
    local file
    local function save()
      test.key("Ctrl+S")
      test.wait(0.2)
    end
    -- the preview starts, and answers what the types declare: node A's red square shows, which takes longer
    -- on a slow computer
    for _ = 1, 40 do
      test.wait(0.5)
      if test.pixel(at(56, 56)) == "#FF0000" then
        break
      end
    end
    test.wait(0.5)
    test.match(test.panel(panelOf(test, "onlr.view")), { title = "start.lua", unsaved = false })
    -- the editor keeps its session, so it starts again with this project, its panels and their locks, and lists it among the
    -- projects opened last (DESIGN 13.2)
    test.match(test.setting("ecs.keepSession"), true, "the editor keeps its session")
    local kept = test.session().pluginState.onlr.state
    check(kept.folder and kept.folder:find("editor/$") and kept.recent[1] == kept.folder, "the session holds the project: " .. tostring(kept.folder))
    -- the title bar holds the editor's menus, then Play, Pause and Step, which are off while nothing plays (DESIGN 13.2)
    local function titleParts()
      local parts = {}
      for _, part in ipairs(test.titleBar()) do
        if part.kind == "menu" or part.kind == "button" then
          parts[#parts + 1] = { kind = part.kind, label = part.label, on = part.on }
        end
      end
      return parts
    end
    test.match(titleParts(), {
      { kind = "menu", label = "File" }, { kind = "menu", label = "Edit" }, { kind = "menu", label = "Game" },
      { kind = "menu", label = "Window" },
      { kind = "button", label = "▶", on = false }, { kind = "button", label = "||", on = false }, { kind = "button", label = "▶|" },
    })
    -- the preset puts the asset viewer under the inspector, in the same column
    local inspector, viewer = test.rect(panelOf(test, "onlr.inspector")), test.rect(panelOf(test, "viewer.file"))
    check(math.abs(viewer.x - inspector.x) < 2 and viewer.y > inspector.y + inspector.height - 2, "the asset viewer is under the inspector")
    -- the rest of the test clicks far down the inspector, which gets the whole column back when the viewer closes
    test.click(viewer.x + viewer.width / 2, viewer.y + viewer.height / 2)
    test.call("ecs.layout.close")
    test.wait(0.2)
    -- opening a project that lacks LÖVE's definitions, as the sample does, gives it them, for a code editor
    check(read(".onlr/love2d/love.lua"):find("---@class love", 1, true), "the project holds LÖVE's definitions")

    -- a drag with the move tool moves the node under the pointer, as one change
    local x, y = at(70, 70)
    test.drag(x, y, x + 64, y + 32)
    test.wait(0.3)
    test.match(test.panel(panelOf(test, "onlr.view")), { unsaved = true })
    save()
    local moved = read("nodes/start.lua")
    check(moved == start:gsub("posX = 40,\n      posY = 40,", "posX = 104,\n      posY = 72,"), "a moved node changes its two lines only:\n" .. moved)
    test.match(test.panel(panelOf(test, "onlr.view")), { unsaved = false })

    -- undoing it gives the file's first text again: the same table always gives the same text
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "undo and save give the first text again")

    -- Ctrl+Z, Ctrl+Y and Ctrl+S act in the whole editor, also while a panel that is not ONLR's has the focus, as the console
    test.key("Ctrl+Y")
    local log = test.rect(panelOf(test, "console.log"))
    test.click(log.x + log.width / 2, log.y + log.height / 2)
    test.key("Ctrl+S")
    test.wait(0.2)
    check(read("nodes/start.lua") == moved, "Ctrl+Y and Ctrl+S in the console redo and save the move")
    test.key("Ctrl+Z")
    test.key("Ctrl+S")
    test.wait(0.2)
    check(read("nodes/start.lua") == start, "Ctrl+Z and Ctrl+S in the console undo and save")

    -- with Ctrl held, a drag snaps to the grid of 32, though snapping is off
    x, y = at(70, 70)
    test.drag(x, y, x + 50, y + 20, "Ctrl")
    test.wait(0.3)
    save()
    check(read("nodes/start.lua"):find("posX = 96,\n      posY = 64,"), "Ctrl snaps the drag:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()

    -- the move tool's arrow along x moves the chosen node along x alone, though the pointer goes down too (DESIGN 13.3)
    x, y = at(80, 40)
    test.drag(x, y, x + 64, y + 32)
    test.wait(0.3)
    save()
    check(read("nodes/start.lua") == start:gsub("posX = 40,\n      posY = 40,", "posX = 104,\n      posY = 40,"), "the arrow moves A along x:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the move along x is undone")
    -- the square between the arrows moves on both axes
    x, y = at(59, 59)
    test.drag(x, y, x + 64, y + 32)
    test.wait(0.3)
    save()
    check(read("nodes/start.lua") == start:gsub("posX = 40,\n      posY = 40,", "posX = 104,\n      posY = 72,"), "the square moves A:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()

    -- one gizmo for the chosen nodes, at their pivot, turns them all (DESIGN 13.3). A and B are squares of 32 at 40, 40 and 120, 40;
    -- B, chosen last, leads. A drag from 10 right and 10 below the gizmo to 10 left of it turns them a quarter, clockwise.
    local function place(id)
      local tree = assert(load(read("nodes/start.lua")))()
      for _, node in ipairs(tree.children) do
        if node.id == id then
          return node.posX or 0, node.posY or 0, node.rot or 0
        end
      end
    end
    local function near(a, b)
      return math.abs(a - b) < 1e-6
    end
    local function turnAround(gx, gy)
      local fx, fy = at(gx + 10, gy + 10)
      local tx, ty = at(gx - 10, gy + 10)
      test.drag(fx, fy, tx, ty)
      test.wait(0.3)
      save()
    end
    x, y = at(70, 70)
    test.click(x, y)
    local bx, by = at(136, 56)
    test.click(bx, by, nil, "Shift")
    test.call("onlr.toolTurn")
    -- each around its own place: the gizmo is at B's place, and both stay where they are
    test.call("onlr.pivotOwn")
    turnAround(120, 40)
    local ax, ay, ar = place("aaaaaa")
    local px, py, pr = place("bbbbbb")
    check(near(ar, math.pi / 2) and near(pr, math.pi / 2), "both nodes turn a quarter:\n" .. read("nodes/start.lua"))
    check(near(ax, 40) and near(ay, 40) and near(px, 120) and near(py, 40), "and stay in their places")
    test.key("Ctrl+Z")
    -- each around the middle of its bounds: the gizmo is at B's middle, and each turns around its own, so its place moves
    test.call("onlr.pivotBounds")
    turnAround(136, 56)
    ax, ay = place("aaaaaa")
    px, py = place("bbbbbb")
    check(near(ax, 72) and near(ay, 40) and near(px, 152) and near(py, 40), "each turns around its middle:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    -- around the middle of the choice, 96, 56, where the one gizmo is: a press beside the nodes, on the gizmo, turns them
    test.call("onlr.pivotSelection")
    turnAround(96, 56)
    ax, ay, ar = place("aaaaaa")
    px, py = place("bbbbbb")
    check(near(ar, math.pi / 2) and near(ax, 112) and near(ay, 0) and near(px, 112) and near(py, 80), "both turn around the choice's middle:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    -- the middle of the choice stays where a turn went around, though the box around the turned bounds changes: A, turned an
    -- eighth alone first, makes the box lopsided, and two eighths around the choice's middle end where a quarter would
    local function eighth(gx, gy)
      local fx, fy = at(gx + 10, gy + 10)
      local tx, ty = at(gx, gy + math.sqrt(200))
      test.drag(fx, fy, tx, ty)
      test.wait(0.3)
    end
    local function nearly(a, b)
      return math.abs(a - b) < 0.01
    end
    x, y = at(56, 56)
    test.click(x, y)
    test.call("onlr.pivotOwn")
    eighth(40, 40)
    test.click(bx, by, nil, "Shift")
    test.call("onlr.pivotSelection")
    -- A turned around its corner, 40, 40: its bounds reach from 40 - 16√2 to 40 + 16√2 across and from 40 to 40 + 32√2 down
    local mx, my = (40 - 16 * math.sqrt(2) + 152) / 2, 40 + 16 * math.sqrt(2)
    eighth(mx, my)
    eighth(mx, my)
    save()
    ax, ay, ar = place("aaaaaa")
    px, py, pr = place("bbbbbb")
    check(nearly(ar, math.pi * 3 / 4) and nearly(pr, math.pi / 2) and nearly(ax, mx + my - 40) and nearly(ay, my - mx + 40)
      and nearly(px, mx + my - 40) and nearly(py, my + 120 - mx), "two eighths turn around one middle:\n" .. read("nodes/start.lua"))
    -- the choices are in the history too, so Ctrl+Z goes back until the file is as it was, and A and B are chosen again
    for _ = 1, 8 do
      if read("nodes/start.lua") == start then
        break
      end
      test.key("Ctrl+Z")
      save()
    end
    check(read("nodes/start.lua") == start, "the turns are undone:\n" .. read("nodes/start.lua"))
    x, y = at(56, 56)
    test.click(x, y)
    test.click(bx, by, nil, "Shift")
    test.call("onlr.pivotOwn")

    -- the scale tool's grips scale one axis alone, along the leading node's own x and y: the gizmo is at B's place, its x grip
    -- 60 to the right and its y grip 60 below. A drag along a grip from 50 to 100 from the gizmo doubles that axis of both nodes.
    local function scales(id)
      local tree = assert(load(read("nodes/start.lua")))()
      for _, node in ipairs(tree.children) do
        if node.id == id then
          return node.sclX or 1, node.sclY or 1
        end
      end
    end
    test.call("onlr.toolScale")
    local fx, fy = at(170, 40)
    local tx, ty = at(220, 46)
    test.drag(fx, fy, tx, ty)
    test.wait(0.3)
    save()
    local asx, asy = scales("aaaaaa")
    local bsx, bsy = scales("bbbbbb")
    check(near(asx, 2) and near(asy, 1) and near(bsx, 2) and near(bsy, 1), "the x grip scales x alone:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    fx, fy = at(120, 90)
    tx, ty = at(126, 140)
    test.drag(fx, fy, tx, ty)
    test.wait(0.3)
    save()
    asx, asy = scales("aaaaaa")
    bsx, bsy = scales("bbbbbb")
    check(near(asx, 1) and near(asy, 2) and near(bsx, 1) and near(bsy, 2), "the y grip scales y alone:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    test.call("onlr.toolMove")
    save()
    check(read("nodes/start.lua") == start, "the turns and scales are undone")

    -- the Shape tool's handles (DESIGN 13.3): A's square of 32 has one at each corner and at each edge's middle. A drag of its right
    -- edge from 32 to 64 widens it; a drag of its top left corner to -32, -32 moves its origin, so its right and bottom edges stay.
    local function shapeOf(id)
      local tree = assert(load(read("nodes/start.lua")))()
      for _, node in ipairs(tree.children) do
        if node.id == id then
          return node.components.onlr.shape
        end
      end
    end
    x, y = at(50, 50)
    test.click(x, y)
    test.wait(0.2)
    test.call("onlr.toolShape")
    fx, fy = at(72, 56)
    tx, ty = at(104, 56)
    test.drag(fx, fy, tx, ty)
    test.wait(0.3)
    save()
    local shape = shapeOf("aaaaaa")
    check(shape.width == 64 and shape.height == nil and shape.origin == nil, "the right edge widens A:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    fx, fy = at(40, 40)
    tx, ty = at(8, 8)
    test.drag(fx, fy, tx, ty)
    test.wait(0.3)
    save()
    shape = shapeOf("aaaaaa")
    check(shape.width == 64 and shape.height == 64 and shape.origin and shape.origin.x == 32 and shape.origin.y == 32,
      "the top left corner moves the origin:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    -- the Rectangle tool on a node whose shape is a rectangle drags the shape's edges, as the Shape tool does
    test.call("onlr.toolRect")
    fx, fy = at(72, 56)
    tx, ty = at(104, 56)
    test.drag(fx, fy, tx, ty)
    test.wait(0.3)
    save()
    shape = shapeOf("aaaaaa")
    check(shape.width == 64 and shape.origin == nil, "the Rectangle tool widens A's shape:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    test.call("onlr.toolMove")
    save()
    check(read("nodes/start.lua") == start, "the shape's changes are undone")

    -- the inspector shows the chosen node: a new name, typed in its Name field and ended with Return, is one change
    x, y = at(70, 70)
    test.click(x, y)
    test.wait(0.2)
    local inspector = test.rect(panelOf(test, "onlr.inspector"))
    test.click(inspector.x + 200, inspector.y + 76)
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
      opened = opened or (panel.type == "onlr.view" and panel.title == "outer.lua")
    end
    check(opened, "the undo opened a view of the other file")
    test.call("ecs.layout.close")
    test.wait(0.2)

    -- an image dropped into the node view makes a node with a sprite of it
    x, y = at(100, 150)
    local folder = os.getenv("PWD") .. "/"
    test.dropFiles(x, y, { folder .. "images/coin.png" })
    test.wait(0.3)
    test.match(test.panel(panelOf(test, "onlr.view")), { unsaved = true })
    save()
    local dropped = read("nodes/start.lua")
    check(dropped:find('name = "Coin",\n      posX = 100,\n      posY = %d+,'), "the dropped image is a node:\n" .. dropped)
    check(dropped:find('image = "images/coin.png"'), "with a sprite of the image")
    -- the Rectangle tool scales a node without a rectangle shape by its bounds: the coin's left edge, dragged 16 to the left,
    -- doubles its width, and its right edge stays (DESIGN 13.3)
    local coinY = tonumber(dropped:match('name = "Coin",\n      posX = 100,\n      posY = (%d+),'))
    x, y = at(108, coinY + 8)
    test.click(x, y)
    test.wait(0.2)
    test.call("onlr.toolRect")
    fx, fy = at(100, coinY + 8)
    tx, ty = at(84, coinY + 8)
    test.drag(fx, fy, tx, ty)
    test.wait(0.3)
    save()
    check(read("nodes/start.lua"):find('name = "Coin",\n      posX = 84,\n      posY = ' .. coinY .. ',\n      sclX = 2,'),
      "the left edge doubles the coin's width:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    test.call("onlr.toolMove")
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the drop is undone")

    -- an image from outside the project is copied in first, into images/, after asking (DESIGN 13.4)
    local outside = folder .. "../gem.png"
    local copy = assert(io.open(outside, "wb"))
    copy:write(read("images/coin.png"))
    copy:close()
    os.remove("images/gem.png")
    test.dropFiles(x, y, { outside })
    test.match(test.dialog(), { title = "Copy into the project" }, "a file from outside asks")
    test.key("Return")
    test.wait(0.3)
    save()
    check(read("images/gem.png") == read("images/coin.png"), "the copy is in images/")
    check(read("nodes/start.lua"):find('image = "images/gem.png"'), "and the sprite names it:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    os.remove("images/gem.png")
    os.remove(outside)
    check(read("nodes/start.lua") == start, "the drop from outside is undone")

    -- Ctrl+D duplicates the chosen node: the copy has a new id, and names what the first one names
    x, y = at(70, 70)
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

    -- choosing is a record of the history, which marks no file unsaved: after A and then B are chosen, undo chooses A again,
    -- so Delete deletes A; and the copy that Duplicate chose is one record with the copy, so one undo takes both (DESIGN 13.6)
    test.click(x, y)
    local bx, by = at(136, 56)
    test.click(bx, by)
    test.match(test.panel(panelOf(test, "onlr.view")), { unsaved = false }, "choosing marks nothing unsaved")
    test.key("Ctrl+Z")
    test.key("Delete")
    test.wait(0.2)
    save()
    local deleted = read("nodes/start.lua")
    check(not deleted:find('id = "aaaaaa"') and deleted:find('id = "bbbbbb"'), "undo chose A again, which Delete deleted:\n" .. deleted)
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the delete is undone")
    -- the undo chooses A again, as it was chosen before the delete; redo chooses nothing, and undo A again (DESIGN 13.6)
    local function chosenNow()
      return test.panel(panelOf(test, "onlr.hierarchy")).state.chosen
    end
    test.match(chosenNow(), { "aaaaaa" }, "undo chooses the deleted node again")
    test.key("Ctrl+Y")
    test.match(chosenNow(), {}, "redo of the delete chooses nothing")
    test.key("Ctrl+Z")
    test.match(chosenNow(), { "aaaaaa" }, "and undo chooses it again")
    test.click(x, y)
    test.key("Ctrl+D")
    test.key("Ctrl+Z")
    test.key("Delete")
    save()
    deleted = read("nodes/start.lua")
    check(not deleted:find('id = "aaaaaa"'), "one undo took the copy and its choice, so A was chosen, and deleted:\n" .. deleted)
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the delete is undone")

    -- in the node hierarchy, a click chooses a node alone, Ctrl adds a node or takes it out, and Shift chooses the shown nodes from
    -- the last one clicked; the rows are Start, A, B and Part (DESIGN 13.4)
    local tree = test.rect(panelOf(test, "onlr.hierarchy"))
    local function chosen()
      return test.panel(panelOf(test, "onlr.hierarchy")).state.chosen
    end
    local function row(i)
      return tree.x + 60, tree.y + 71 + 21 * (i - 1)
    end
    local rx, ry = row(2)
    test.click(rx, ry)
    test.match(chosen(), { "aaaaaa" }, "a click chooses A")
    rx, ry = row(3)
    test.click(rx, ry, nil, "Ctrl")
    test.match(chosen(), { "bbbbbb", "aaaaaa" }, "Ctrl adds B")
    rx, ry = row(2)
    test.click(rx, ry, nil, "Ctrl")
    test.match(chosen(), { "bbbbbb" }, "Ctrl takes A out")
    rx, ry = row(4)
    test.click(rx, ry, nil, "Shift")
    check(#chosen() == 2 and chosen()[1] == "bbbbbb", "Shift chooses B and Part: " .. table.concat(chosen(), ", "))
    -- Shift+A adds every node under the chosen ones, Part's Tip too, and Ctrl+A chooses every node of the file (DESIGN 13.4)
    test.key("Shift+A")
    local function has(list, path)
      for _, p in ipairs(list) do
        if p == path then
          return true
        end
      end
    end
    local with = chosen()
    check(#with == 3 and has(with, "bbbbbb") and has(with, "p4rt01") and has(with, "p4rt01/t1p000"),
      "Shift+A chooses B, Part and Tip: " .. table.concat(with, ", "))
    test.key("Ctrl+A")
    local all = chosen()
    check(has(all, "aaaaaa") and has(all, "p4rt01/t1p000") and #all > #with, "Ctrl+A chooses every node: " .. table.concat(all, ", "))
    -- Duplicate takes the topmost of the chosen nodes, with all under them, once: with every node chosen that is Start, which is the file's
    -- first node and is not duplicated, so the file stays as it was, and A, B and Part are not copied apart from it
    test.key("Ctrl+D")
    test.wait(0.2)
    save()
    check(read("nodes/start.lua") == start, "Duplicate copies a chosen node's chosen children with it, not again:\n" .. read("nodes/start.lua"))

    -- a double click on a node opens it, and another closes it: Part shows Tip under it
    rx, ry = row(4)
    test.click(rx, ry)
    test.click(rx, ry)
    test.match(test.panel(panelOf(test, "onlr.hierarchy")).state.open, { p4rt01 = true }, "a double click opens Part")
    test.wait(0.5)
    test.click(rx, ry)
    test.click(rx, ry)
    check(not test.panel(panelOf(test, "onlr.hierarchy")).state.open.p4rt01, "another double click closes it")

    -- H hides the chosen node in the node view, and L locks it there: a click in the view chooses neither. The marks are the
    -- project's settings, not the node file's, and H and L again take them off (DESIGN 13.3, 13.4)
    local function settings()
      return read(".onlr/editor.lua")
    end
    rx, ry = row(2)
    test.click(rx, ry)
    test.key("H")
    test.wait(0.2)
    check(settings():find('hidden = {%s*%["nodes/start.lua"%] = {%s*aaaaaa = true'), "H hides A:\n" .. settings())
    local vx, vy = at(70, 70)
    test.click(vx, vy)
    test.match(chosen(), {}, "a hidden node is not chosen in the view: " .. table.concat(chosen(), ","))
    test.click(rx, ry)
    test.key("H")
    test.key("L")
    test.wait(0.2)
    check(settings():find('locked = {%s*%["nodes/start.lua"%] = {%s*aaaaaa = true') and not settings():find("hidden = {%s*%["),
      "H shows A again, and L locks it:\n" .. settings())
    test.click(vx, vy)
    test.match(chosen(), {}, "a locked node is not chosen in the view")
    test.click(rx, ry)
    test.key("L")
    test.wait(0.2)
    test.click(vx, vy)
    test.match(chosen(), { "aaaaaa" }, "an unlocked node is chosen again")
    -- each row has Hide and Lock at its end, which a click turns as H and L do, and which choose nothing
    local function markAt(id)
      local r = assert(test.panel(panelOf(test, "onlr.hierarchy")).state.marks[id], "the node hierarchy shows " .. id)
      return tree.x + r.x + r.width / 2, tree.y + r.y + r.height / 2
    end
    test.click(markAt("bbbbbb:hidden"))
    test.wait(0.2)
    check(settings():find('hidden = {%s*%["nodes/start.lua"%] = {%s*bbbbbb = true'), "a click on B's Hide hides it:\n" .. settings())
    test.match(chosen(), { "aaaaaa" }, "and chooses nothing")
    test.click(markAt("bbbbbb:hidden"))
    test.wait(0.2)
    check(not settings():find("bbbbbb = true"), "another click shows it again:\n" .. settings())
    check(read("nodes/start.lua") == start, "the marks leave the node file as it was")

    -- the search shows the nodes whose name holds the text, and with t:, those with a component of a type: thing is on A, B
    -- and Part's Tip, so Start, A, B, Part and Tip show, opened
    test.click(tree.x + 150, tree.y + 42)
    test.text("t:thing")
    test.wait(0.2)
    rx, ry = row(5)
    test.click(rx, ry)
    test.match(chosen(), { "p4rt01/t1p000" }, "the search shows Tip, under Part, opened")
    test.click(tree.x + 150, tree.y + 42)
    test.key("Ctrl+A")
    test.key("Backspace")
    test.key("Return")
    test.wait(0.2)

    -- The inspector's rows are found by their ids, whose rectangles the inspector saves (DESIGN 16), as A's "aaaaaa:thing:speed".
    -- A row outside the inspector's view is brought into it with the wheel, as a user scrolls.
    local function inspected(id, across, down)
      local panel = panelOf(test, "onlr.inspector")
      local box = test.rect(panel)
      for _ = 1, 40 do
        local r = test.panel(panel).state.rects[id]
        check(r ~= nil, "the inspector shows " .. id)
        local y = box.y + r.y + r.height * (down or 0.5)
        if y >= box.y + box.height - 4 then
          test.wheel(box.x + box.width / 2, box.y + box.height / 2, -1)
        elseif y <= box.y + 4 then
          test.wheel(box.x + box.width / 2, box.y + box.height / 2, 1)
        else
          return box.x + r.x + r.width * (across or 0.5), y
        end
        test.wait(0.05)
      end
      error(id .. " is not brought into the inspector's view")
    end
    -- a click on a component's heading folds it, and another opens it, for every node with one
    local function fold(id)
      test.click(inspected(id .. ":heading", 0.2))
      test.wait(0.2)
    end

    -- a component's menu in the inspector copies its values, and pastes them onto the same type of another node, as one
    -- change: A's thing onto B's; Up goes round from the first entry to the last, Remove Component, then skips Paste while
    -- nothing is copied
    rx, ry = row(2)
    test.click(rx, ry)
    test.wait(0.2)
    local hx, hy = inspected("aaaaaa:thing:heading", 0.2)
    test.click(hx, hy, 3)
    test.key("Up")
    test.key("Up")
    test.key("Return")
    rx, ry = row(3)
    test.click(rx, ry)
    test.wait(0.2)
    hx, hy = inspected("bbbbbb:thing:heading", 0.2)
    test.click(hx, hy, 3)
    test.key("Up")
    test.key("Up")
    test.key("Return")
    test.wait(0.2)
    save()
    local _, speeds = read("nodes/start.lua"):gsub("speed = 25", "")
    check(speeds == 2, "B's thing has A's values:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the paste is one change, undone")

    -- the menu's first entry, Move up, moves A's thing above its shape: the node file keeps the order, which the inspector shows,
    -- and the move is one change (DESIGN 13.4)
    rx, ry = row(2)
    test.click(rx, ry)
    test.wait(0.2)
    hx, hy = inspected("aaaaaa:thing:heading", 0.2)
    test.click(hx, hy, 3)
    test.key("Return")
    test.wait(0.2)
    save()
    check(read("nodes/start.lua"):find('componentOrder = {%s*"onlr.paint",%s*"thing",%s*"onlr.shape",%s*}'),
      "Move up writes the order:\n" .. read("nodes/start.lua"))
    local ordered = test.panel(panelOf(test, "onlr.inspector")).state.rects
    check(ordered["aaaaaa:thing:heading"].y < ordered["aaaaaa:onlr.shape:heading"].y, "the inspector shows thing above the shape")
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the move is one change, undone")

    -- the lock keeps A in the inspector while B is chosen, until it is turned off (DESIGN 13.4)
    test.click(inspected("lock"))
    test.wait(0.2)
    rx, ry = row(3)
    test.click(rx, ry)
    test.wait(0.2)
    local locked = test.panel(panelOf(test, "onlr.inspector")).state
    check(locked.rects["aaaaaa:thing:heading"] and not locked.rects["bbbbbb:thing:heading"], "the locked inspector shows A")
    test.match(locked.lock, { file = "nodes/start.lua", paths = { "aaaaaa" } }, "the lock is kept in the panel's state")
    test.click(inspected("lock"))
    test.wait(0.2)
    check(test.panel(panelOf(test, "onlr.inspector")).state.rects["bbbbbb:thing:heading"], "unlocked, it shows B")

    -- a number with a range shows a slider under its heading, Movement: a drag to its end is one change, at the release (DESIGN 13.4)
    rx, ry = row(2)
    test.click(rx, ry)
    test.wait(0.2)
    local sx, sy = inspected("aaaaaa:thing:speed:slide", 0.05)
    local inspect = test.rect(panelOf(test, "onlr.inspector"))
    test.drag(sx, sy, inspect.x + inspect.width, sy)
    test.wait(0.2)
    save()
    check(read("nodes/start.lua"):find("speed = 100,"), "the slider sets the speed:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the slider's drag is one change, undone")

    -- A's paint and shape fold, which brings up thing's rows below them
    fold("aaaaaa:onlr.paint")
    fold("aaaaaa:onlr.shape")

    -- a list's heading has an Add button, also when no instance marks its value: Add on A's Tags adds a tag, as one change
    test.click(inspected("aaaaaa:thing:tags:add"))
    test.wait(0.2)
    save()
    check(read("nodes/start.lua"):find("tags = {"), "Add puts a tag in the list:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the added tag is one change, undone")

    -- a file's row is a path with a button for the system's dialog: a whole path in the project is kept from the project's
    -- folder, and one outside it is refused (DESIGN 13.4)
    test.click(inspected("aaaaaa:thing:picture:path", 0.3))
    test.key("Ctrl+A")
    test.text(os.getenv("PWD") .. "/images/coin.png")
    test.key("Return")
    test.wait(0.2)
    save()
    check(read("nodes/start.lua"):find('picture = "images/coin.png"'), "a whole path in the project is kept from its folder:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the path is undone")
    test.click(inspected("aaaaaa:thing:picture:path", 0.3))
    test.key("Ctrl+A")
    test.text("/outside/coin.png")
    test.key("Return")
    test.wait(0.2)
    save()
    check(read("nodes/start.lua") == start, "a path outside the project is refused")
    -- a file from outside the project dropped on a file's row is copied into the project first, after asking, as a drop on a node
    -- view is (DESIGN 13.4)
    local gem = os.getenv("PWD") .. "/../gem.png"
    local gemFile = assert(io.open(gem, "wb"))
    gemFile:write(read("images/coin.png"))
    gemFile:close()
    local gx, gy = inspected("aaaaaa:thing:picture:path", 0.3)
    test.dropFiles(gx, gy, { gem })
    test.match(test.dialog(), { title = "Copy into the project" }, "a file from outside dropped on a row asks")
    test.key("Return")
    test.wait(0.3)
    save()
    check(read("images/gem.png") == read("images/coin.png") and read("nodes/start.lua"):find('picture = "images/gem.png"'),
      "the copy is in images/, and the row names it:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    os.remove("images/gem.png")
    os.remove(gem)
    check(read("nodes/start.lua") == start, "the drop on the row is undone")

    -- a sound's row has a Stream toggle beside its file, which the node file keeps with the path (DESIGN 6.2)
    test.click(inspected("aaaaaa:thing:sound:stream", 0.5))
    test.wait(0.2)
    save()
    check(read("nodes/start.lua"):find("sound = {%s*stream = true,?%s*}"), "Stream is kept with the sound:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "Stream is undone")

    -- a node's row has Pick, which waits for a click on a node: in the node view, A picks itself for its target, and the choice stays;
    -- in the node hierarchy, B is picked back (DESIGN 13.4)
    test.click(inspected("aaaaaa:thing:target:pick", 0.5))
    local px, py = at(70, 70)
    test.click(px, py)
    test.wait(0.2)
    save()
    check(read("nodes/start.lua"):find('friend = "bbbbbb",%s*speed = 25,%s*target = "aaaaaa"'), "Pick and a click in the view set the target:\n" .. read("nodes/start.lua"))
    test.match(chosen(), { "aaaaaa" }, "and A stays chosen")
    test.click(inspected("aaaaaa:thing:target:pick", 0.5))
    rx, ry = row(3)
    test.click(rx, ry)
    test.wait(0.2)
    save()
    check(read("nodes/start.lua") == start, "Pick and a click in the node hierarchy set it back:\n" .. read("nodes/start.lua"))
    test.match(chosen(), { "aaaaaa" }, "and A is still chosen")

    -- Add component, at the inspector's end, shows the types in folders by their names' dots, a folder at a time: onlr's folder
    -- first, then marker, the project's script. Return opens onlr in place, Left goes back, and Down and Return add marker.
    fold("aaaaaa:thing")
    test.click(inspected("aaaaaa:addComponent"))
    local top = test.popup(1).height
    test.key("Return")
    local inside = test.popup(1).height
    test.key("Left")
    test.match({ inside > top, test.popup(1).height }, { true, top }, "the folders of Add component, and back")
    test.key("Down")
    test.key("Return")
    test.wait(0.2)
    save()
    check(read("nodes/start.lua"):find("marker = {"), "Add component adds marker:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the added component is undone")
    fold("aaaaaa:thing")
    fold("aaaaaa:onlr.shape")
    fold("aaaaaa:onlr.paint")

    -- a property with when shows only while the property that it names has one of its values: a rectangle shows its width,
    -- and a circle its radius in its place (DESIGN 6.2)
    local panelState = test.panel(panelOf(test, "onlr.inspector")).state
    check(panelState.rects["aaaaaa:onlr.shape:width"] and not panelState.rects["aaaaaa:onlr.shape:radius"], "a rectangle shows its width only")

    -- the Shape tool's points (DESIGN 13.3): A becomes a polygon, whose points have handles. A double click adds a point after the
    -- last, also beside the shape, and one on the line between two points adds it between them; Delete removes the point clicked last.
    local function pointsOf(id)
      local tree = assert(load(read("nodes/start.lua")))()
      for _, node in ipairs(tree.children) do
        if node.id == id then
          local list = {}
          for _, p in ipairs(node.components.onlr.shape.points or {}) do
            list[#list + 1] = ("%g,%g"):format(p.x, p.y)
          end
          return table.concat(list, " ")
        end
      end
    end
    test.click(inspected("aaaaaa:onlr.shape:kind", 0.5))
    for _, letter in ipairs({ "p", "o", "l", "y" }) do
      test.key(letter)
    end
    test.key("Return")
    test.wait(0.3)
    test.call("onlr.toolShape")
    local function doubleClick(px, py)
      local sx, sy = at(px, py)
      test.click(sx, sy)
      test.click(sx, sy)
      test.wait(0.2)
    end
    doubleClick(40, 40)
    doubleClick(40, 140)
    doubleClick(100, 140)
    doubleClick(40, 90)
    save()
    check(pointsOf("aaaaaa") == "0,0 0,50 0,100 60,100", "double clicks add points, and one on a line between two:\n" .. read("nodes/start.lua"))
    test.click(at(100, 140))
    test.key("Delete")
    test.wait(0.2)
    save()
    check(pointsOf("aaaaaa") == "0,0 0,50 0,100", "Delete removes the point clicked last:\n" .. read("nodes/start.lua"))
    for _ = 1, 6 do
      test.key("Ctrl+Z")
    end
    test.call("onlr.toolMove")
    save()
    check(read("nodes/start.lua") == start, "the points and the kind are undone:\n" .. read("nodes/start.lua"))

    -- F2 renames the chosen node in a field above the tree, and Return takes the name
    rx, ry = row(2)
    test.click(rx, ry)
    test.key("F2")
    test.wait()
    test.key("Ctrl+A")
    test.text("Lead")
    test.key("Return")
    test.wait(0.2)
    save()
    check(read("nodes/start.lua") == start:gsub('name = "A"', 'name = "Lead"'), "F2 renames the node:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()
    -- so does Rename, the second entry of the node's menu
    test.click(rx, ry, 3)
    test.key("Down")
    test.key("Return")
    test.wait()
    test.key("Ctrl+A")
    test.text("Head")
    test.key("Return")
    test.wait(0.2)
    save()
    check(read("nodes/start.lua") == start:gsub('name = "A"', 'name = "Head"'), "the menu renames the node:\n" .. read("nodes/start.lua"))
    test.key("Ctrl+Z")
    save()

    -- a node dragged in the node hierarchy moves in the tree: onto the upper quarter of a row before that node, and onto its middle into it
    -- (DESIGN 13.4); each move is one change
    local fromX, fromY = row(3)
    local toX, toY = row(2)
    test.drag(fromX, fromY, toX, toY - 8)
    test.wait(0.2)
    save()
    local moved = read("nodes/start.lua")
    check(moved:find('"bbbbbb"', 1, true) < moved:find('"aaaaaa"', 1, true), "B moves before A:\n" .. moved)
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the move is undone")
    fromX, fromY = row(2)
    toX, toY = row(3)
    test.drag(fromX, fromY, toX, toY)
    test.wait(0.2)
    save()
    moved = read("nodes/start.lua")
    check(moved:find('name = "B",.-children = {%s*{%s*id = "aaaaaa"'), "A moves into B:\n" .. moved)
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the move into B is undone")

    -- a deleted base breaks only its instance: the rest of the file still shows in the node hierarchy, and A is chosen there; the base back
    -- gives the instance back (DESIGN 9)
    local partText = read("nodes/part.lua")
    rx, ry = row(3)
    test.click(rx, ry)
    os.remove("nodes/part.lua")
    test.wait(1.5)
    rx, ry = row(2)
    test.click(rx, ry)
    test.match(chosen(), { "aaaaaa" }, "the node hierarchy works without the instance's base")
    local back = assert(io.open("nodes/part.lua", "wb"))
    back:write(partText)
    back:close()
    test.wait(0.5)

    -- Save as Node File, the last entry of a node's menu in the node hierarchy that A can use, writes the node to a new node file named after it, and
    -- puts an instance of it in its place; Up goes round from the menu's first entry to its last
    test.click(x, y)
    test.wait(0.2)
    rx, ry = row(2)
    test.click(rx, ry, 3)
    test.key("Up")
    test.key("Return")
    test.wait(0.3)
    local hero = read("nodes/a.lua")
    check(hero:find('id = "aaaaaa"') and hero:find("speed = 25"), "the new node file holds the node:\n" .. hero)
    check(not hero:find("bbbbbb"), "without the values that name a node outside it")
    test.click(x, y)
    save()
    local held = read("nodes/start.lua")
    check(held:find('base = "nodes/a.lua"'), "an instance is in the node's place:\n" .. held)
    check(held:find('%["aaaaaa"%] = {\n            components = {\n              thing = {\n                friend = "bbbbbb",\n                target = "bbbbbb",'),
      "and its change sets the values that name the node outside")
    -- the click chose the instance, a record of its own, so the second undo takes the node file back
    test.key("Ctrl+Z")
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start and read("nodes/a.lua") == hero, "undoing it puts the node back, and leaves the new file")
    os.remove("nodes/a.lua")
    test.wait(0.3)

    -- a right click in the node view's empty space opens its menu, whose first entry adds a node at the pointer (DESIGN 13.3)
    local ex, ey = at(320, 300)
    test.click(ex, ey, 3)
    test.key("Return")
    save()
    local added = read("nodes/start.lua")
    check(added:find("posX = 320,\n%s*posY = 300"), "Add Node Here puts the node at the pointer:\n" .. added)
    test.key("Ctrl+Z")
    test.key("Ctrl+Z")
    save()
    check(read("nodes/start.lua") == start, "the added node is undone")

    -- the history panel, the third tab beside the console, lists every record: a click on its first row, before every change, undoes
    -- them all, and Redo brings them back (DESIGN 13.6)
    local console = test.rect(panelOf(test, "console.log"))
    save()
    local before = read("nodes/start.lua")
    local history = panelOf(test, "onlr.history")
    local done = test.panel(history).state.position
    check(done > 0, "the history holds the test's records")
    local function shown()
      local ok, rect = pcall(test.rect, history)
      return ok and rect or nil
    end
    for _, across in ipairs({ 185, 200, 215, 230 }) do
      if not shown() then
        test.click(console.x + across, console.y - 14)
        test.wait(0.2)
      end
    end
    local list = assert(shown(), "the history's tab shows it")
    test.click(list.x + 60, list.y + 20)
    test.wait(0.3)
    check(test.panel(history).state.position == 0, "a click on the first row undoes every record: " .. test.panel(history).state.position)
    for _ = 1, done do
      test.key("Ctrl+Y")
    end
    test.wait(0.3)
    check(test.panel(history).state.position == done, "Redo brings them back")
    save()
    check(read("nodes/start.lua") == before, "as they were:\n" .. read("nodes/start.lua"))

    -- the files panel renames a file: every path that names it changes with it, and the files are saved (DESIGN 13.7)
    -- the files panel is a tab beside the console, which shows first
    test.click(console.x + 125, console.y - 14)
    test.wait(0.2)
    local files = test.rect(panelOf(test, "files.tree"))
    -- nodes/ is open when the panel followed the chosen nodes to their file; otherwise a click opens it
    if not (test.panel(panelOf(test, "files.tree")).state.open or {}).nodes then
      test.click(files.x + 21, files.y + 97)
      test.wait(0.2)
    end
    -- a click on a file shows it in the inspector, and a second click soon after opens it (DESIGN 13.7)
    test.click(files.x + 80, files.y + 139)
    test.match(test.panel(panelOf(test, "onlr.inspector")).state, { file = "nodes/part.lua" }, "the inspector shows the clicked file")
    test.click(files.x + 80, files.y + 139)
    -- Rename, the entry before the last of a file's menu, shows a field with the file's name, which the new name replaces
    test.click(files.x + 80, files.y + 139, 3)
    test.key("Up")
    test.key("Up")
    test.key("Return")
    test.wait()
    test.key("Ctrl+A")
    test.text("piece.lua")
    test.key("Return")
    test.wait(0.5)
    check(read("nodes/piece.lua") ~= "" and read("nodes/part.lua") == "", "the file has its new name")
    check(read("nodes/start.lua") == start:gsub("nodes/part.lua", "nodes/piece.lua"), "the instance names the file by its new name")
    -- the second click opened the file in a node view, which follows it to its new name
    local followed = false
    for _, panel in ipairs(test.panels()) do
      followed = followed or (panel.type == "onlr.view" and panel.title == "piece.lua")
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
    test.click(inspector.x + 200, inspector.y + 104)
    test.key("Ctrl+A")
    test.text("Mine")
    test.key("Return")
    test.wait(0.2)
    test.click(x, y)
    save()
    check(read("nodes/start.lua"):find('%["p4rt00"%] = {\n            name = "Mine",'), "the instance's change holds the name:\n" .. read("nodes/start.lua"))
    -- typing the base's name again takes the change out: a value that equals its default is left out
    test.click(inspector.x + 200, inspector.y + 104)
    test.key("Ctrl+A")
    test.text("Piece")
    test.key("Return")
    test.wait(0.2)
    test.click(x, y)
    save()
    check(read("nodes/start.lua") == start, "the base's own name leaves no change")

    -- a file with changes that are not saved asks when it is deleted on disk, and when the editor's are kept, a save writes it again
    -- (DESIGN 13.6)
    local function rename(name)
      test.click(x, y)
      test.wait(0.2)
      test.click(inspector.x + 200, inspector.y + 104)
      test.key("Ctrl+A")
      test.text(name)
      test.key("Return")
      test.wait(0.2)
    end
    local function answer(title)
      local asked
      for _ = 1, 20 do
        test.wait(0.2)
        asked = test.dialog()
        if asked then
          break
        end
      end
      test.match(asked and asked.title, title, "the editor asks")
      test.key("Return")
      test.wait(0.3)
    end
    rename("Kept")
    os.remove("nodes/start.lua")
    answer("nodes/start.lua was deleted")
    save()
    check(read("nodes/start.lua"):find('name = "Kept"'), "the editor's changes are written again:\n" .. read("nodes/start.lua"))
    -- a person's comment that came while the editor held changes is the person's: the save asks before it writes over it (DESIGN 4.2)
    rename("Twice")
    local noted = read("nodes/start.lua") .. "-- a person's note\n"
    file = assert(io.open("nodes/start.lua", "wb"))
    file:write(noted)
    file:close()
    answer("nodes/start.lua changed on disk")
    test.key("Ctrl+S")
    answer("Save nodes/start.lua")
    check(read("nodes/start.lua"):find('name = "Twice"') and not read("nodes/start.lua"):find("a person's note"), "Replace writes the editor's")
    file = assert(io.open("nodes/start.lua", "wb"))
    file:write(start)
    file:close()
    test.wait(1)

    -- a node file that does not load, such as one with git's conflict marks, shows in its view with its error; a right click on it,
    -- Select All and Paste do nothing, and raise no error (DESIGN 4.2)
    test.click(at(56, 56))
    test.key("Ctrl+C")
    file = assert(io.open("nodes/start.lua", "wb"))
    file:write("<<<<<<< HEAD\n" .. start .. "=======\n" .. start .. ">>>>>>> other\n")
    file:close()
    test.wait(1)
    local before = #test.errors()
    local ex, ey = at(300, 300)
    test.click(ex, ey, 3)
    test.wait(0.2)
    test.key("Escape")
    test.click(ex, ey)
    test.key("Ctrl+A")
    test.key("Ctrl+V")
    test.wait(0.2)
    test.match(test.errors()[before + 1], nil, "a node file that does not load raises nothing")
    file = assert(io.open("nodes/start.lua", "wb"))
    file:write(start)
    file:close()
    test.wait(1)
    check(read("nodes/start.lua") == start, "the file is left as it was")

    -- F fits the view to the chosen node: node A's red square fills its middle, at a greater zoom
    test.click(at(56, 56))
    test.key("F")
    test.wait(0.5)
    local fitted = test.panel(panelOf(test, "onlr.view")).state
    check(fitted.zoom > 2, "F zooms in on the chosen node: " .. tostring(fitted.zoom))
    check(test.pixel(view.x + view.width / 2, view.y + view.height / 2) == "#FF0000", "and centres it")

    -- Open Base, the last entry of an instance's menu in the node hierarchy, opens its base in a node view
    rx, ry = row(4)
    test.click(rx, ry, 3)
    test.key("Up")
    test.key("Return")
    test.wait(0.3)
    local opened = false
    for _, panel in ipairs(test.panels()) do
      opened = opened or (panel.type == "onlr.view" and test.panel(panel.id).title == "part.lua")
    end
    check(opened, "Open Base opens part.lua")

    -- Ctrl+K opens the search over everything (DESIGN 13.8): "tip" finds part.lua's node Tip first, and Return opens its file and
    -- chooses it; "marker:load" finds the function that the marker script defines, at its line
    test.key("Ctrl+K")
    test.wait(0.2)
    test.text("tip")
    test.wait(0.2)
    local found = test.panel(panelOf(test, "onlr.search")).state.shown
    check(found[1] == "Node Tip nodes/part.lua", "the search finds Tip: " .. tostring(found[1]))
    test.key("Return")
    test.wait(0.3)
    test.match(chosen(), { "t1p000" }, "Return chooses Tip")
    -- the files panel follows: it chooses the node file of what is chosen (DESIGN 13.7)
    test.match(test.panel(panelOf(test, "files.tree")).state, { selected = "nodes/part.lua", open = { nodes = true } }, "the files panel shows part.lua")
    test.key("Ctrl+K")
    test.wait(0.2)
    test.key("Ctrl+A")
    test.text("marker:load")
    test.wait(0.2)
    found = test.panel(panelOf(test, "onlr.search")).state.shown
    check(found[1] == "Function Marker:load components/marker.lua:6", "the search finds the function: " .. tostring(found[1]))
    test.call("ecs.layout.close")
    test.wait(0.2)
    test.click(view.x + 5, view.y + view.height - 5)
    test.wait(0.2)


    -- the Game bar's Window chooses the game's size for Play, such as a phone's; the manifest keeps its own
    local game = test.rect(panelOf(test, "onlr.game"))
    local dropdown = test.panel(panelOf(test, "onlr.game")).state.playSize
    test.click(game.x + dropdown.x + dropdown.width / 2, game.y + dropdown.y + dropdown.height / 2)
    test.wait(0.2)
    local list = test.popup(1)
    test.click(list.x + 40, list.y + 3.5 * list.height / 7)
    test.wait(0.2)
    test.click(view.x + 5, view.y + view.height - 5)
    test.wait(0.2)

    -- Play saves the project and runs the game, whose marker writes a file. While it plays, the panels' frames take onlr.playTint
    os.remove("played.txt")
    os.remove("window.txt")
    test.key("F5")
    for _ = 1, 50 do
      test.wait(0.1)
      if read("played.txt") ~= "" then
        break
      end
    end
    check(read("played.txt") == "Start", "the game played")
    check(read("window.txt") == "360x800", "in the window's size that Play chose: " .. read("window.txt"))
    check(read(".onlr/editor.lua"):find('playSize = "360x800"', 1, true) ~= nil, "which the project's editor settings keep")
    -- the title bar's Play button is on while the game plays
    test.match(titleParts()[5], { label = "▶", on = true }, "Play is on while the game plays")
    -- the panels, the tabs and the space around them take some of the tint while the game plays, and lose it at Stop
    local tinted = {}
    for _, name in ipairs({ "ecs.colorPanel", "ecs.colorTabRow", "ecs.colorBackground" }) do
      tinted[name] = test.setting(name)
    end
    test.key("Shift+F5")
    test.wait(0.5)
    for name, color in pairs(tinted) do
      test.match(test.setting(name) ~= color, true, name .. " takes the tint while the game plays, and loses it at Stop")
    end

    -- Export: the folder that exports are written to is typed into the Export panel, which is a tab beside the inspector
    test.click(inspector.x + 210, inspector.y - 14)
    test.wait(0.2)
    local export = test.rect(panelOf(test, "onlr.export"))
    test.click(export.x + 100, export.y + 50)
    test.key("Ctrl+A")
    test.text("out")
    test.key("Return")
    test.wait(0.2)

    -- the .love file is a zip archive of the project, without what starts with a dot and without the export's folder
    test.call("onlr.exportLove")
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

    -- ./out names the same folder, which the next export leaves out too, so no export holds the ones before it (DESIGN 14.1)
    local function exportTo(folder)
      test.click(export.x + 100, export.y + 50)
      test.key("Ctrl+A")
      test.text(folder)
      test.key("Return")
      test.wait(0.2)
    end
    exportTo("./out")
    test.call("onlr.exportLove")
    test.wait(0.3)
    love = list("unzip -l out/Editor.love")
    check(love:find(" main.lua\n") and not love:find("%d   out/"), "./out is left out as out is:\n" .. love)
    -- the project's own folder is refused, since each export would hold the ones before it
    exportTo(".")
    test.call("onlr.exportLove")
    test.wait(0.3)
    check(read("Editor.love") == "", "no export into the project's own folder")
    exportTo("out")
    -- exclude's patterns name paths part by part: ** is any folders or none, and a folder's pattern takes all that it holds
    local manifest = read("manifest.lua")
    local file = assert(io.open("manifest.lua", "wb"))
    file:write((manifest:gsub("\n  format = 1,", '\n  exclude = { "images/", "**/outer.lua", "**/thing.lu" },\n  format = 1,', 1)))
    file:close()
    test.wait(0.5)
    test.call("onlr.exportLove")
    test.wait(0.3)
    love = list("unzip -l out/Editor.love")
    check(not love:find(" images/") and not love:find(" nodes/outer.lua\n") and love:find(" nodes/start.lua\n")
      and love:find(" components/thing.lua\n"), "exclude's patterns:\n" .. love)
    file = assert(io.open("manifest.lua", "wb"))
    file:write(manifest)
    file:close()
    test.wait(0.5)

    -- the Linux build is LÖVE's files with the .love file joined to LÖVE's executable: unpacked, its launcher runs the game
    test.call("onlr.exportLinux")
    test.wait(1)
    os.execute("mkdir -p out/linux && tar -xzf out/Editor-linux-x86_64.tar.gz -C out/linux && cd out/linux && "
      .. "SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null timeout 3 ./Editor/Editor > /dev/null 2>&1")
    check(read("out/linux/played.txt") == "Start", "the Linux build runs the game")
    check(read("out/linux/Editor/license.txt") ~= "", "and holds LÖVE's license.txt")

    -- the Windows build is made from LÖVE's runtime, which is downloaded and checked against the hash that ONLR ships
    test.call("onlr.exportWindows")
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

    -- Scale to the window, in the project settings, copies the push package into the project, makes a top node and gives it a
    -- push.screen of the window's size, 320 by 240; the node file and the manifest's change are one, which Ctrl+Z takes back
    -- (DESIGN 11.10)
    test.call("onlr.scaleToWindow")
    test.wait(0.3)
    save()
    check(read("packages/push/components/screen.lua") ~= "", "the push package is copied into the project")
    check(read("manifest.lua"):find('topNode = "nodes/top.lua"', 1, true), "the manifest names the top node:\n" .. read("manifest.lua"))
    local top = read("nodes/top.lua")
    check(top:find("push = {%s*screen = {%s*height = 240,%s*width = 320,"), "the top node has a screen of the window's size:\n" .. top)
    test.key("Ctrl+Z")
    save()
    check(not read("manifest.lua"):find("topNode"), "Ctrl+Z takes the top node out of the manifest:\n" .. read("manifest.lua"))

    -- no panel failed
    for _, panel in ipairs(test.panels()) do
      check(not test.panel(panel.id).fault, panel.type .. " failed: " .. tostring(test.panel(panel.id).fault))
    end
  end,
}
