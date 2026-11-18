---@type onlr.NodeFile
return {
  format = 1,
  id = "p4rt00",
  name = "Part",
  components = {
    onlr = {
      shape = {
        color = {
          0,
          0,
          1,
          1,
        },
      },
    },
  },
  children = {
    {
      id = "t1p000",
      name = "Tip",
      posY = 64,
      components = {
        onlr = {
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
