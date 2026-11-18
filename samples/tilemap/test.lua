-- Checks the sti package (DESIGN 11.7): a map of Tiled loads, draws its layers where its node draws, animates its
-- tiles, keeps a layer that is not visible from drawing, draws only the layers that it names, and turns places of the
-- world into tiles and back.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

-- Draws the component into a canvas of the map's size, at the canvas's corner, and gives the colour of a pixel.
local canvas
local function pixel(component, x, y)
  canvas = canvas or love.graphics.newCanvas(64, 48)
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.origin()
  local ok, err = pcall(component.draw, component)
  love.graphics.pop()
  if not ok then
    error(err, 0)
  end
  local r, g, b, a = canvas:newImageData():getPixel(x, y)
  return ("%d %d %d %d"):format(r, g, b, a)
end

check.run(function()
  local node = assert(onlr.tree.find("Map"))
  local component = node.components.sti.map
  local map = assert(component:get(), "the map is loaded")

  check.equal(map.width, 4, "the map is 4 tiles wide")
  local x, y, w, h = component:bounds()
  check.equal(("%d %d %d %d"):format(x, y, w, h), "0 0 64 48", "its bounds are its tiles, from its corner")

  -- Tiles and places of the world: the node is at 16, 8.
  local column, row = component:toTile(16 + 20, 8 + 4)
  check.equal(column * 10 + row, 21, "a place of the world is in a tile")
  check.equal(map:getTileProperties("ground", 1, 1).solid, true, "a tile's properties from Tiled")
  local wx, wy = component:toWorld(2, 2)
  check.equal(wx * 1000 + wy, 32024, "a tile's corner in the world")

  -- Layers by name, with the objects of an object layer.
  local spawn = map.layers.spawns.objects[1]
  check.equal(spawn.name, "player", "an object layer's objects")
  check.equal(spawn.x * 100 + spawn.y, 824, "with their places in the map")

  -- Drawing: red at the top, the blue tile in the middle row, nothing where there is no tile, and the hidden object
  -- layer draws nothing.
  check.equal(pixel(component, 8, 8), "1 0 0 1", "a red tile at the map's corner")
  check.equal(pixel(component, 24, 24), "0 0 1 1", "the blue tile")
  check.equal(pixel(component, 8, 24), "0 0 0 0", "no tile, nothing drawn")

  check.equal(pixel(component, 56, 24), "1 0 0 1", "every visible layer draws: the top's tile")

  -- layers: a node draws only the layers that it names.
  local back = assert(onlr.tree.find("Back")).components.sti.map
  local front = assert(onlr.tree.find("Front")).components.sti.map
  check.equal(pixel(back, 56, 24), "0 0 0 0", "the ground's node draws no top")
  check.equal(pixel(back, 8, 8), "1 0 0 1", "and draws the ground")
  check.equal(pixel(front, 56, 24), "1 0 0 1", "the top's node draws the top")
  check.equal(pixel(front, 8, 8), "0 0 0 0", "and no ground")
  front.layers = { "sky" }
  check.fails(function()
    pixel(front, 0, 0)
  end, "no layer sky", "a layer that the map lacks is an error")
  front.layers = { "top" }

  -- The blue tile is animated: after a tenth of a second it is red.
  check.frames(7)
  check.equal(pixel(component, 24, 24), "1 0 0 1", "an animated tile changes")

  -- The node view loads its own map, once.
  love.graphics.push("all")
  component:drawEditor(true)
  love.graphics.pop()
  check.ok(component.shown ~= nil and component.shown ~= map, "the node view draws a map of its own")
end)
