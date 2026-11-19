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
    -- the tool's menu is short: what concerns the whole tool, and no export
    test.match(test.setting("ecs.toolMenu"), {
      "onlr.newProject", "onlr.openProject", "onlr.save", "onlr.play", "onlr.playFile", "onlr.stop", "settings.open", "panels.open",
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

    -- in the nodes panel, a click chooses a node alone, Ctrl adds a node or takes it out, and Shift chooses the shown nodes from
    -- the last one clicked; the rows are Start, A, B and Part (DESIGN 13.4)
    local tree = test.rect(panelOf(test, "onlr.nodes"))
    local function chosen()
      return test.panel(panelOf(test, "onlr.nodes")).state.chosen
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

    -- a double click on a node opens it, and another closes it: Part shows Tip under it
    rx, ry = row(4)
    test.click(rx, ry)
    test.click(rx, ry)
    test.match(test.panel(panelOf(test, "onlr.nodes")).state.open, { p4rt01 = true }, "a double click opens Part")
    test.wait(0.5)
    test.click(rx, ry)
    test.click(rx, ry)
    check(not test.panel(panelOf(test, "onlr.nodes")).state.open.p4rt01, "another double click closes it")

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
    -- The inspector does not scroll here: a row below its end is brought up by folding the sections above it.
    local function inspected(id, across, down)
      local panel = panelOf(test, "onlr.inspector")
      local box = test.rect(panel)
      local r = test.panel(panel).state.rects[id]
      check(r ~= nil, "the inspector shows " .. id)
      local y = box.y + r.y + r.height * (down or 0.5)
      check(y < box.y + box.height, id .. " is in the inspector's view")
      return box.x + r.x + r.width * (across or 0.5), y
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

    -- a node dragged in the nodes panel moves in the tree: onto the upper quarter of a row before that node, and onto its middle into it
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

    -- a deleted base breaks only its instance: the rest of the file still shows in the nodes panel, and A is chosen there; the base back
    -- gives the instance back (DESIGN 9)
    local partText = read("nodes/part.lua")
    rx, ry = row(3)
    test.click(rx, ry)
    os.remove("nodes/part.lua")
    test.wait(1.5)
    rx, ry = row(2)
    test.click(rx, ry)
    test.match(chosen(), { "aaaaaa" }, "the nodes panel works without the instance's base")
    local back = assert(io.open("nodes/part.lua", "wb"))
    back:write(partText)
    back:close()
    test.wait(0.5)

    -- Save as Node File, the last entry of a node's menu in the nodes panel that A can use, writes the node to a new node file named after it, and
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

    -- the files panel renames a file: every path that names it changes with it, and the files are saved (DESIGN 13.7)
    -- the files panel is a tab beside the console, which shows first
    local console = test.rect(panelOf(test, "console.log"))
    test.click(console.x + 125, console.y - 14)
    test.wait(0.2)
    local files = test.rect(panelOf(test, "files.tree"))
    test.click(files.x + 21, files.y + 97)
    test.wait(0.2)
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

    -- F fits the view to the chosen node: node A's red square fills its middle, at a greater zoom
    test.click(at(56, 56))
    test.key("F")
    test.wait(0.5)
    local fitted = test.panel(panelOf(test, "onlr.view")).state
    check(fitted.zoom > 2, "F zooms in on the chosen node: " .. tostring(fitted.zoom))
    check(test.pixel(view.x + view.width / 2, view.y + view.height / 2) == "#FF0000", "and centres it")

    -- Open Base, the last entry of an instance's menu in the nodes panel, opens its base in a node view
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

    -- no panel failed
    for _, panel in ipairs(test.panels()) do
      check(not test.panel(panel.id).fault, panel.type .. " failed: " .. tostring(test.panel(panel.id).fault))
    end
  end,
}
