-- A flag, which the tile map's object Goal names in its property node: sti.objects makes it a node under the map, at the
-- object's place (DESIGN 11.7).
---@type onlr.NodeFile
return {
  format = 1,
  id = "f1ag09",
  name = "Flag",
  components = {
    onlr = {
      paint = {
        color = { 0.85, 0.85, 0.9, 1 },
      },
      shape = {
        height = 14,
        origin = { x = 0, y = 14 },
        width = 1,
      },
    },
  },
  children = {
    {
      id = "f1agc1",
      name = "Cloth",
      posX = 1,
      posY = -14,
      components = {
        onlr = {
          paint = {
            color = { 0.3, 0.6, 1, 1 },
          },
          shape = {
            height = 5,
            width = 7,
          },
        },
      },
    },
  },
}
