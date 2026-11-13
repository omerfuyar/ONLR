-- Checks drawing (DESIGN 5 and 10): the order by z, groups, the camera, and the engine's components.
-- The test draws the tree into a canvas and reads its pixels.
local check = require("check")
local onlr = require("onlr")

local canvas

-- Draws the tree as a frame does, and gives a function that reads a pixel as a text, such as "1 0 0".
local function draw()
  canvas = canvas or love.graphics.newCanvas(320, 240)
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.origin()
  onlr.loop.draw()
  love.graphics.setCanvas()
  local pixels = canvas:newImageData()
  return function(x, y)
    local r, g, b = pixels:getPixel(x, y)
    return ("%d %d %d"):format(r + 0.5, g + 0.5, b + 0.5)
  end
end

check.run(function()
  local tree = onlr.tree
  local function find(name)
    return assert(tree.find(name))
  end
  local camera = find("World").components.onlr.camera

  -- The camera shows its point, 0, 0, in the middle of its screen, the window.
  local at = draw()
  check.equal(at(162, 122), "1 0 0", "the sprite, under the camera")
  check.equal(at(158, 122), "0 0 0", "nothing beside it")
  -- What no camera holds draws at the window's pixels.
  check.equal(at(1, 1), "1 1 1", "a shape beside the camera's node")
  -- Nodes draw by z, the lowest first: green has the higher z, though blue comes later in the tree.
  check.equal(at(182, 122), "0 1 0", "the higher z draws last")
  find("Blue"):setZ(10)
  at = draw()
  check.equal(at(182, 122), "0 0 1", "setZ: the frame's next draw uses it")

  -- The engine's components set back what they change.
  check.equal({ love.graphics.getColor() }, { 1, 1, 1, 1 }, "the colour is set back")

  -- A group draws its node and all under it through drawTree: here, moved down by 100.
  check.equal(at(301, 101), "1 1 0", "a node of a group")
  check.equal(at(301, 1), "0 0 0", "which draws nowhere else")
  -- A group's nodes draw by z among themselves only: z 100 inside does not draw over z 1 outside.
  check.equal(at(305, 101), "1 0 1", "a node outside the group, with a higher z than the group")

  -- drawTree may call draw more than once.
  find("Shifted").components.shift.copies = 2
  at = draw()
  check.equal({ at(301, 101), at(301, 201) }, { "1 1 0", "1 1 0" }, "drawn twice")
  -- A node whose drawTree does not run draws as a node without one.
  find("Shifted").components.shift:setEnabled(false)
  check.frames(1)
  at = draw()
  check.equal({ at(301, 1), at(301, 101) }, { "1 1 0", "0 0 0" }, "a group that is turned off")

  -- The camera's properties move it: its point, its zoom and its angle.
  camera.posX, camera.zoom = 10, 2
  at = draw()
  check.equal({ at(141, 121), at(155, 135), at(139, 121) }, { "1 0 0", "1 0 0", "0 0 0" }, "moved and zoomed")
  check.equal({ camera:toWorld(160, 120) }, { 10, 0 }, "camera:toWorld, the middle of the screen")
  check.equal({ camera:toScreen(0, 0) }, { 140, 120 }, "camera:toScreen")
  camera.rot = math.pi / 2
  find("World").posX = 7
  local x, y = camera:toWorld(30, 40)
  check.equal({ camera:toScreen(x, y) }, { 30, 40 }, "there and back, turned")
  at = draw()
  local sx, sy = camera:toScreen(find("Red"):toWorld(4, 4))
  check.equal(at(math.floor(sx), math.floor(sy)), "1 0 0", "a turned camera shows the node where toScreen says")
  -- A camera's screen has a size of its own when width and height name one.
  camera.rot, camera.width, camera.height = 0, 100, 50
  check.equal({ camera:toScreen(10, 0) }, { 50 + (10 - 7 - 10) * 2, 25 }, "a screen of the camera's own size")

  -- The other shapes, and the text.
  check.equal({ at(40, 200), at(255, 205) }, { "1 1 1", "1 1 1" }, "a circle and a polygon")
  local lit = false
  for px = 100, 120 do
    for py = 200, 215 do
      lit = lit or at(px, py) == "1 1 1"
    end
  end
  check.ok(lit, "the text")

  -- bounds: the rectangle that a component covers, in its node's space.
  check.equal({ find("Red").components.onlr.sprite:bounds() }, { 0, 0, 8, 8 }, "a sprite's bounds")
  find("Red").components.onlr.sprite.origin.x = 4
  find("Red").components.onlr.sprite.quad.width, find("Red").components.onlr.sprite.quad.height = 2, 3
  check.equal({ find("Red").components.onlr.sprite:bounds() }, { -4, 0, 2, 3 }, "with an origin and a quad")
  check.equal({ find("Circle").components.onlr.shape:bounds() }, { -6, -6, 12, 12 }, "a circle's bounds")
  check.equal({ find("Polygon").components.onlr.shape:bounds() }, { 0, 0, 10, 10 }, "a polygon's bounds")
  local _, _, w, h = find("Text").components.onlr.text:bounds()
  check.ok(w > 10 and h > 20, "a text's bounds, of two lines")
  check.equal({ camera:bounds() }, { 10 - 25, -12.5, 50, 25 }, "a camera's bounds: what it shows")
  at = draw()
  check.equal(at(160 - 0, 121) ~= nil, true, "a quad draws")
end)
