-- A variant: a node file whose node is an instance of another node file.
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
