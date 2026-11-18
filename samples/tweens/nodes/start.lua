-- The flux and tick packages' sample: two nodes that slide right in a second, and tick every quarter of a second.
---@type onlr.NodeFile
return {
  format = 1,
  id = "tw0r00",
  name = "Start",
  children = {
    {
      id = "m0ver1",
      name = "One",
      components = {
        mover = {},
      },
    },
    {
      id = "m0ver2",
      name = "Two",
      posY = 20,
      components = {
        mover = {},
      },
    },
  },
}
