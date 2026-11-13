-- A variant: a node file whose node is an instance of another node file, its base.
-- It is the coin, twice as large and worth 5. A change to coin.lua reaches it,
-- apart from what it changes here. A level holds it, or a script spawns it, as any node file.
---@type onlr.NodeFile
return {
  format = 1,
  id = "b1gc0n",
  instance = {
    base = "nodes/coin.lua",
    changes = {
      ["c0in7x"] = {
        name = "Big coin",
        sclX = 2,
        sclY = 2,
        components = {
          coin = {
            worth = 5,
          },
        },
      },
    },
  },
}
