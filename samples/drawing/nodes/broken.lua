-- A node whose component fails in the node view, before a node that draws.
---@type onlr.NodeFile
return {
  format = 1,
  id = "br0k3n",
  name = "Broken",
  components = {
    broken = {},
  },
  children = {
    {
      id = "br0k32",
      name = "Broken too",
      components = {
        broken = {
          late = true,
        },
      },
    },
    {
      id = "w0rks0",
      name = "Works",
      posX = 16,
      posY = 16,
      components = {
        onlr = {
          shape = {
            color = { 0, 1, 0, 1 },
            height = 8,
            width = 8,
          },
        },
      },
    },
    {
      id = "wh1t30",
      name = "White",
      components = {
        onlr = {
          sprite = {
            color = { 0, 0, 0, 0 },
            image = "images/red.png",
          },
        },
      },
    },
  },
}
