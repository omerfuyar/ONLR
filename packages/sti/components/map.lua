-- The component type sti.map: a map made with Tiled, at its node.
-- The map's top left corner is at the node's place, and the node's turn and scale turn and scale it. Its layers draw
-- where the node draws, so a camera above it moves it, as it moves every node (DESIGN 10).
local onlr = require("onlr")
local sti = require("sti")

---@class sti.map : onlr.Component
---@field private loaded sti.Map?
---@field private shown sti.Map? the node view's map
local TileMap = {}

TileMap.map = onlr.property.file({ extensions = { "lua" }, description = "A map that Tiled exported as Lua, with its tilesets embedded" })
TileMap.layers = onlr.property.list(onlr.property.string(""), {
  description = "The layers that it draws, by their names in Tiled, in this order. Empty draws every visible layer. So a sprite goes between layers: a node draws the ground, and a node after the player the treetops",
})

-- Loads the map: STI reads the file, and the tilesets' images beside it.
local function load(path)
  if not path then
    return nil
  end
  local ok, map = pcall(sti --[[@as fun(path: string): sti.Map]], path)
  if not ok then
    error(("sti.map %s: %s"):format(path, tostring(map)), 0)
  end
  return map
end

-- Draws each visible layer where the drawing is now. STI's own map:draw is not used: it draws through a canvas of
-- the window's size from the screen's corner, so a node's place, a camera and a group's effect would not reach it.
local function drawLayers(map, names)
  if #names == 0 then
    for _, layer in ipairs(map.layers) do
      if layer.visible and layer.opacity > 0 then
        map:drawLayer(layer)
      end
    end
    return
  end
  for _, name in ipairs(names) do
    local layer = map.layers[name]
    if not layer then
      error(("sti.map: the map has no layer %s"):format(name), 0)
    end
    if layer.opacity > 0 then
      map:drawLayer(layer)
    end
  end
end

-- The map's rectangle, for an orthogonal map.
local function size(map)
  return map.width * map.tilewidth, map.height * map.tileheight
end

function TileMap:load()
  self.loaded = load(self.map)
end

-- Moves animated tiles on, and updates the layers that a script added.
function TileMap:update(dt)
  if self.loaded then
    self.loaded:update(dt)
  end
end

function TileMap:draw()
  if self.loaded then
    drawLayers(self.loaded, self.layers)
  end
end

-- The node view draws the map as the game does, at its first frame, loaded once and kept until a value changes (DESIGN 6.5).
function TileMap:drawEditor(chosen)
  if self.map and not self.shown then
    self.shown = load(self.map)
  end
  local map = self.shown
  if not map then
    return
  end
  drawLayers(map, self.layers)
  if chosen then
    local w, h = size(map)
    love.graphics.setColor(0.6, 0.9, 1, 1)
    love.graphics.rectangle("line", 0, 0, w, h)
  end
end

function TileMap:bounds()
  local map = self.loaded or self.shown
  if not map then
    return
  end
  local w, h = size(map)
  return 0, 0, w, h
end

-- Not called by the engine: scripts call these.

-- STI's map, for all of STI's own functions on it, such as getTileProperties and setLayerTile.
---@return sti.Map?
function TileMap:get()
  return self.loaded
end

-- The column and the row, from 1, of the tile at a place in the world, as getTileProperties takes them.
---@param x number
---@param y number
---@return integer column, integer row
function TileMap:toTile(x, y)
  local map = assert(self.loaded, "sti.map: no map is loaded")
  local lx, ly = self.node:toLocal(x, y)
  local column, row = map:convertPixelToTile(lx, ly)
  return math.floor(column) + 1, math.floor(row) + 1
end

-- The place in the world of a tile's top left corner, by its column and row from 1.
---@param column integer
---@param row integer
---@return number x, number y
function TileMap:toWorld(column, row)
  local map = assert(self.loaded, "sti.map: no map is loaded")
  return self.node:toWorld(map:convertTileToPixel(column - 1, row - 1))
end

return TileMap
