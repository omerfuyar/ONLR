-- Instances of a node file: coins of nodes/parts/coin.lua, some with changed values, and more made by a click.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m02",
  name = "Instances",
  components = {
    room = {
      about = "Each coin is an instance of nodes/parts/coin.lua; some change its values. A click spawns another.",
      title = "Instances and spawning",
    },
    spawner = {
      file = "nodes/parts/coin.lua",
    },
  },
  children = {
    {
      id = "1nst01",
      instance = {
        base = "nodes/parts/coin.lua",
        changes = {
          ["c01n00"] = { posX = 120, posY = 140 },
        },
      },
    },
    {
      id = "1nst02",
      instance = {
        base = "nodes/parts/coin.lua",
        changes = {
          ["c01n00"] = { name = "Big coin", posX = 260, posY = 140, sclX = 3, sclY = 3 },
        },
      },
    },
    {
      id = "1nst03",
      instance = {
        base = "nodes/parts/coin.lua",
        changes = {
          ["c01n00"] = {
            name = "Fast red coin",
            posX = 400,
            posY = 140,
            sclX = 2,
            sclY = 2,
            components = {
              onlr = {
                sprite = { color = { 1, 0.4, 0.4, 1 } },
              },
              spin = { speed = 10 },
            },
          },
        },
      },
    },
  },
}
