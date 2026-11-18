-- A node file that holds an instance, and is itself held as one: its coin is named from outside by a path.
---@type onlr.NodeFile
return {
  format = 1,
  id = "ch35t0",
  name = "Chest",
  children = {
    {
      id = "ch3st9",
      instance = {
        base = "nodes/coin.lua",
        changes = {
          ["c0in7x"] = {
            name = "Chest coin",
            posX = 10,
            components = {
              coin = {
                worth = 2,
              },
            },
          },
          ["g1nt4k"] = {
            name = "Chest glint",
            posX = 1,
          },
        },
      },
    },
  },
}
