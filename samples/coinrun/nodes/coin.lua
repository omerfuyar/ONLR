-- A node file made to be held in others: a coin. It is a node file as the level is.
-- Node files hold instances of it, and scripts make instances while the game runs.
-- An instance changes values of these nodes and components, and adds components and children
-- of its own.
---@type onlr.NodeFile
return {
  format = 1,
  -- The file's first node: the coin itself. An instance changes it under this id.
  id = "c0in7x",
  name = "Coin",
  -- Components, by their types' names. A dot in a name is a table in a table:
  -- bump.body is bump = { body = { ... } }, and a script of components/ has no dot.
  components = {
    bump = {
      body = {
        height = 16,
        solid = false,
        width = 16,
      },
    },
    -- The script components/coin.lua: when the last coin is taken, it loads this node file as the root.
    coin = {
      next = "nodes/win.lua",
    },
    onlr = {
      sprite = {
        image = "images/coin.png",
      },
    },
  },
  children = {
    -- A node under the coin. An instance changes it under this id.
    {
      id = "g1nt4k",
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
