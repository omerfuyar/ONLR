-- A prefab: one object, with its components and children, in a file of its own.
-- Scenes hold instances of it, and scripts make instances while the game runs.
---@type onlr.Prefab
return {
  format = 1,
  id = "c0in",
  name = "Coin",
  components = {
    { type = "onlr.sprite", image = "images/coin.png" },
    { type = "bump.body", width = 16, height = 16 },
    { type = "scripts.coin" },
  },
}
