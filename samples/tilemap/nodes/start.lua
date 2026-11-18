-- The sti package's sample: a map of Tiled on a node that is not at the world's corner, and the same map drawn by two
-- nodes, one its ground and one its top, as a game puts its player between them.
---@type onlr.NodeFile
return {
  format = 1,
  id = "t1le00",
  name = "Start",
  children = {
    {
      id = "m4p000",
      name = "Map",
      posX = 16,
      posY = 8,
      components = {
        sti = {
          map = {
            map = "maps/level.lua",
          },
        },
      },
    },
    {
      id = "back00",
      name = "Back",
      components = {
        sti = {
          map = {
            layers = { "ground" },
            map = "maps/level.lua",
          },
        },
      },
    },
    {
      id = "fr0nt0",
      name = "Front",
      components = {
        sti = {
          map = {
            layers = { "top" },
            map = "maps/level.lua",
          },
        },
      },
    },
  },
}
