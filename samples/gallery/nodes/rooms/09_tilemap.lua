-- STI: a map made with Tiled, drawn by two nodes, its ground and its top, with a coin between them. The ground's tiles that Tiled
-- marks collidable are fixtures of Box2D, which a ball falls onto, and the map's object Goal becomes a flag.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m09",
  name = "Tile map",
  components = {
    room = {
      about = "sti.map draws a Tiled map's layers, the coin between them. sti.physics makes its collidable tiles fixtures, sti.objects its Goal a flag.",
      title = "Tile maps from Tiled (STI)",
    },
  },
  children = {
    {
      id = "gr0nd9",
      name = "Ground",
      posX = 192,
      posY = 90,
      sclX = 4,
      sclY = 4,
      components = {
        sti = {
          map = { layers = { "ground" }, map = "maps/level.lua" },
          objects = {},
          physics = {},
        },
      },
    },
    {
      id = "c01n09",
      name = "Coin",
      posX = 300,
      posY = 170,
      sclX = 2,
      sclY = 2,
      components = {
        onlr = {
          sprite = { image = "images/coin.png", origin = { x = 8, y = 8 } },
        },
        spin = {},
      },
    },
    {
      id = "ba1109",
      name = "Ball",
      posX = 236,
      posY = -20,
      components = {
        onlr = {
          paint = {
            color = { 0.95, 0.6, 0.2, 1 },
          },
          shape = {
            kind = "circle",
            radius = 12,
          },
        },
        physics = {
          body = {},
          fixture = { restitution = 0.4 },
        },
      },
    },
    {
      id = "t0p009",
      name = "Top",
      posX = 192,
      posY = 90,
      sclX = 4,
      sclY = 4,
      components = {
        sti = {
          map = { layers = { "top" }, map = "maps/level.lua" },
        },
      },
    },
  },
}
