-- A prefab: one object, with its components and children, in a file of its own.
-- Scenes hold instances of it, and scripts make instances while the game runs.
-- An instance changes values of these objects and components. It adds and removes none.
---@type onlr.Prefab
return {
  format = 1,
  id = "c0in",
  name = "Coin",
  components = {
    {
      type = "onlr.sprite",
      image = "images/coin.png",
    },
    {
      type = "bump.body",
      width = 16,
      height = 16,
    },
    {
      type = "components.coin",
    },
  },
  children = {
    -- An object inside the prefab. An instance names it by this id.
    {
      id = "g1nt",
      name = "Glint",
      x = 4,
      y = -4,
      components = {
        {
          type = "onlr.sprite",
          image = "images/glint.png",
        },
      },
    },
  },
}
