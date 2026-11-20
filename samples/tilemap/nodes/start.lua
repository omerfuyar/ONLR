-- The sti package's sample: a map of Tiled on a node that is not at the world's corner, whose ground collides with a box of
-- bump and a ball of Box2D, and whose object Goal becomes a flag; and the same map drawn by two nodes, one its ground and one
-- its top, as a game puts its player between them.
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
          bump = {},
          map = {
            map = "maps/level.lua",
          },
          objects = {},
          physics = {},
        },
      },
    },
    {
      id = "b0x000",
      name = "Box",
      posX = 66,
      posY = -20,
      components = {
        bump = {
          body = {},
        },
        onlr = {
          shape = {
            height = 8,
            width = 8,
          },
        },
      },
    },
    {
      id = "ba11ab",
      name = "Ball",
      posX = 56,
      posY = -40,
      components = {
        onlr = {
          shape = {
            kind = "circle",
            radius = 4,
          },
        },
        physics = {
          body = {},
          fixture = {},
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
