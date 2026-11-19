---@type onlr.NodeFile
return {
  format = 1,
  id = "p4rt00",
  name = "Part",
  components = {
    onlr = {
      paint = {
        color = {
          0,
          0,
          1,
          1,
        },
      },
      shape = {},
    },
  },
  children = {
    {
      id = "t1p000",
      name = "Tip",
      posY = 64,
      components = {
        onlr = {
          paint = {},
          shape = {
            height = 16,
            width = 16,
          },
        },
        thing = {
          speed = 5,
        },
      },
    },
  },
}
