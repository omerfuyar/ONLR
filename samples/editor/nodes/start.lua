---@type onlr.NodeFile
return {
  format = 1,
  id = "st4rt0",
  name = "Start",
  components = {
    marker = {},
  },
  children = {
    {
      id = "aaaaaa",
      name = "A",
      posX = 40,
      posY = 40,
      components = {
        onlr = {
          shape = {
            color = {
              1,
              0,
              0,
              1,
            },
          },
        },
        thing = {
          friend = "bbbbbb",
          speed = 25,
          target = "bbbbbb",
        },
      },
    },
    {
      id = "bbbbbb",
      name = "B",
      posX = 120,
      posY = 40,
      components = {
        onlr = {
          shape = {
            color = {
              0,
              1,
              0,
              1,
            },
          },
        },
        thing = {},
      },
    },
    {
      id = "p4rt01",
      instance = {
        base = "nodes/part.lua",
        changes = {
          ["p4rt00"] = {
            posX = 200,
            posY = 40,
          },
        },
      },
    },
  },
}
