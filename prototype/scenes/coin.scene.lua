-- A scene made to be held in others: a coin. It is a scene as the level is, in the same format.
-- Scenes hold instances of it, and scripts make instances while the game runs.
-- An instance changes values of these objects and components. It adds and removes none.
---@type onlr.Scene
return {
  format = 1,
  -- The root: the coin itself.
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
    -- An object under the root. An instance names it by this id.
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
