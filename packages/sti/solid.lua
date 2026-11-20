-- What the sti package's components share (DESIGN 11.7): the rectangles of a map that collide, as STI's own plugins for bump and
-- Box2D find them, by Tiled's property collidable: every tile of a layer that has it, every tile whose tileset gives it, the
-- collidable rectangles that a tile holds, and the rectangles of an object layer that has it, or that have it themselves.
local solid = {}

---@class sti.Solid
---@field x number the rectangle's corner, in the map's own pixels
---@field y number
---@field width number
---@field height number
---@field properties table what Tiled gives the tile, the layer or the object
---@field layer string the layer's name

-- The rectangles that a tile holds in Tiled's collision editor, which have collidable, at a tile's corner.
local function inside(out, tile, x, y, layer)
  for _, object in ipairs(tile.objectGroup and tile.objectGroup.objects or {}) do
    if object.properties.collidable == true then
      out[#out + 1] = { x = x + object.x, y = y + object.y, width = object.width, height = object.height, properties = object.properties, layer = layer }
    end
  end
end

---The rectangles of a map that collide, in the map's own pixels, from its top left corner.
---@param map sti.Map
---@return sti.Solid[]
function solid.rectangles(map)
  local out = {}
  local ox, oy = map.offsetx or 0, map.offsety or 0
  -- the tiles whose tileset makes them collide, wherever they are, unless their layer collides whole, which the loop below takes
  for _, tileset in ipairs(map.tilesets) do
    for _, tile in ipairs(tileset.tiles) do
      for _, instance in ipairs(map.tileInstances[tileset.firstgid + tile.id] or {}) do
        local whole = instance.layer.properties.collidable == true
        if not whole then
          local x, y = instance.x + ox, instance.y + oy
          inside(out, tile, x, y, instance.layer.name)
          if tile.properties and tile.properties.collidable == true then
            out[#out + 1] = { x = x, y = y, width = map.tilewidth, height = map.tileheight, properties = tile.properties, layer = instance.layer.name }
          end
        end
      end
    end
  end
  for _, layer in ipairs(map.layers) do
    if layer.type == "tilelayer" and layer.properties.collidable == true then
      for row, tiles in ipairs(layer.data) do
        for column, tile in pairs(tiles) do
          local x = (column - 1) * map.tilewidth + tile.offset.x + ox
          local y = (row - 1) * map.tileheight + tile.offset.y + oy
          inside(out, tile, x, y, layer.name)
          out[#out + 1] = { x = x, y = y, width = tile.width, height = tile.height, properties = tile.properties or {}, layer = layer.name }
        end
      end
    elseif layer.type == "objectgroup" then
      for _, object in ipairs(layer.objects) do
        if object.shape == "rectangle" and (layer.properties.collidable == true or object.properties.collidable == true) then
          local y = object.y + oy - (object.gid and object.height or 0)
          out[#out + 1] = { x = object.x + ox, y = y, width = object.width, height = object.height, properties = object.properties, layer = layer.name }
        end
      end
    end
  end
  return out
end

---The map of an sti.map, loaded: the type that needs it loads after it (DESIGN 6.6).
---@param node onlr.Node
---@param who string the type that asks, for the message
---@return sti.Map
function solid.mapOf(node, who)
  local map = (node.components.sti.map --[[@as sti.map]]):get()
  if not map then
    error(("%s on %s: its sti.map names no map"):format(who, node.name), 0)
  end
  return map
end

return solid
