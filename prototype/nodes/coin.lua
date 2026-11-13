-- A node file made to be held in others: a coin. It is a node file as the level is.
-- Node files hold instances of it, and scripts make instances while the game runs.
-- An instance changes values of these nodes and components, and may add children of its own.
-- It adds no component and removes nothing.
---@type onlr.NodeFile
return {
  format = 1,
  -- The file's node: the coin itself.
  id = "c0in",
  name = "Coin",
  -- Components, by their types' names. A dot in a name is a table in a table:
  -- bump.body is bump = { body = { ... } }, and a script of components/ has no dot.
  components = {
    bump = {
      body = {
        width = 16,
        height = 16,
      },
    },
    -- The script components/coin.lua, with every value at its default.
    coin = {},
    onlr = {
      sprite = {
        image = "images/coin.png",
      },
    },
  },
  children = {
    -- A node under the coin. An instance names it by this id.
    {
      id = "g1nt",
      name = "Glint",
      posX = 4,
      posY = -4,
      components = {
        onlr = {
          sprite = {
            image = "images/glint.png",
          },
        },
      },
    },
  },
}
