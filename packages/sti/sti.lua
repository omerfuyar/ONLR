---@meta sti

-- The library's definitions, named as the package. A code editor reads them, and the game never does.
-- They are written with the package, since STI ships none: what a script reaches through sti.map's get().

---A layer of a Tiled map: tiles, objects, an image, a group, or a script's own.
---@class sti.Layer
---@field name string
---@field type "tilelayer"|"objectgroup"|"imagelayer"|"group"|string
---@field visible boolean
---@field opacity number
---@field properties table<string, any> the layer's custom properties from Tiled
---@field objects? table[] an object layer's objects, each with its x, y, width, height, name, type and properties
---@field draw fun(self: sti.Layer) draws the layer; a script's layer sets its own
---@field update fun(self: sti.Layer, dt: number)
local Layer = {}

---A map of Tiled, loaded.
---@class sti.Map
---@field width integer in tiles
---@field height integer in tiles
---@field tilewidth integer
---@field tileheight integer
---@field orientation "orthogonal"|"isometric"|"staggered"|"hexagonal"
---@field properties table<string, any> the map's custom properties from Tiled
---@field layers table<integer|string, sti.Layer> by their order, and by their names
---@field objects table<integer, table> every object of the map, by its id
local Map = {}

---Moves the animated tiles on, and updates each layer.
---@param dt number
function Map:update(dt) end

---Draws one layer where the drawing is now, with its opacity.
---@param layer sti.Layer
function Map:drawLayer(layer) end

---A layer's custom properties.
---@param layer integer|string
---@return table<string, any>
function Map:getLayerProperties(layer) end

---The custom properties of the tile at a column and a row of a layer, from 1.
---@param layer integer|string
---@param x integer
---@param y integer
---@return table<string, any>
function Map:getTileProperties(layer, x, y) end

---An object's custom properties, by the object's name.
---@param layer integer|string
---@param object string
---@return table<string, any>
function Map:getObjectProperties(layer, object) end

---Puts the tile of a global id at a column and a row of a layer, from 1, or removes the tile there with nil.
---@param layer integer|string
---@param x integer
---@param y integer
---@param gid integer?
function Map:setLayerTile(layer, x, y, gid) end

---The column and the row, from 0, of a place in the map's pixels.
---@param x number
---@param y number
---@return number column, number row
function Map:convertPixelToTile(x, y) end

---The place in the map's pixels of a column and a row, from 0.
---@param x number
---@param y number
---@return number x, number y
function Map:convertTileToPixel(x, y) end

---Adds a layer that a script draws: it sets the layer's draw and update.
---@param name string
---@param index? integer where it goes among the layers; the top when left out
---@return sti.Layer
function Map:addCustomLayer(name, index) end

---@param index integer|string
function Map:removeLayer(index) end

---Loads a map that Tiled exported as Lua.
---@class sti
---@overload fun(path: string, plugins?: string[], ox?: number, oy?: number): sti.Map
local sti = {}

---Forgets the images of the maps loaded so far, which STI keeps for the next map.
function sti:flush() end

return sti
