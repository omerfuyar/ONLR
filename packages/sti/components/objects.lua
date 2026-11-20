-- The component type sti.objects: Tiled's objects become nodes (DESIGN 11.7). Each object of the map whose property node
-- names a node file of the project, such as nodes/coin.lua, is an instance of that file under the map's node, at the object's
-- place, turned as the object, and named as it when it has a name. So the author places coins and enemies in Tiled, and makes
-- each in ONLR's editor.
local onlr = require("onlr")
local solid = require("sti.solid")

---@class sti.objects : onlr.Component
---@field private spawned onlr.Node[]
local Objects = {}

Objects.needs = { "sti.map" }

Objects.layers = onlr.property.list(onlr.property.string(""), {
  description = "The object layers whose objects become nodes, by their names in Tiled. Empty takes every object layer",
})

-- The object layers to take, by the property layers.
local function chosen(map, names)
  if #names == 0 then
    local all = {}
    for _, layer in ipairs(map.layers) do
      if layer.type == "objectgroup" then
        all[#all + 1] = layer
      end
    end
    return all
  end
  local list = {}
  for i, name in ipairs(names) do
    local layer = map.layers[name]
    if not layer or layer.type ~= "objectgroup" then
      error(("sti.objects: the map has no object layer %s"):format(name), 0)
    end
    list[i] = layer
  end
  return list
end

-- Once, as the map loads: the instances, in the order of the layers and of their objects.
function Objects:load()
  local map = solid.mapOf(self.node, "sti.objects")
  self.spawned = {}
  for _, layer in ipairs(chosen(map, self.layers)) do
    for _, object in ipairs(layer.objects) do
      local path = object.properties.node
      if type(path) == "string" and path ~= "" then
        -- a tile object's place is its bottom left corner in Tiled; a node's is where its file puts its origin
        local x = object.x + (map.offsetx or 0) + (layer.offsetx or 0)
        local y = object.y + (map.offsety or 0) + (layer.offsety or 0)
        local node = onlr.tree.spawn(path, x, y, self.node)
        node.rot = math.rad(object.rotation or 0)
        if object.name and object.name ~= "" then
          node.name = object.name
        end
        self.spawned[#self.spawned + 1] = node
      end
    end
  end
end

-- Not called by the engine: scripts call it. The nodes that the objects became, in the order of the layers and their objects.
---@return onlr.Node[]
function Objects:getNodes()
  return self.spawned
end

return Objects
