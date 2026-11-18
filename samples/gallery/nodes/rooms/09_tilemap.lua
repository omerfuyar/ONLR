-- STI: a map made with Tiled, drawn by two nodes, its ground and its top, with a coin between them.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m09",
  name = "Tile map",
  components = {
    room = {
      about = "sti.map draws layers of a Tiled map at its node, which scales it. The coin is between the ground and the top.",
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
