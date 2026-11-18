-- A coin, which rooms hold as instances: an instance may change any value of it, and the rest follow this file.
---@type onlr.NodeFile
return {
  format = 1,
  id = "c01n00",
  name = "Coin",
  components = {
    onlr = {
      sprite = {
        image = "images/coin.png",
        origin = { x = 8, y = 8 },
      },
    },
    spin = {
      speed = 2,
    },
  },
}
