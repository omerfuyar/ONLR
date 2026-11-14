---@type onlr.NodeFile
return {
  format = 1,
  id = "0uter0",
  name = "Outer",
  components = {
    thing = {
      target = "h0ld01/bbbbbb",
    },
  },
  children = {
    {
      id = "h0ld01",
      instance = {
        base = "nodes/start.lua",
        changes = {
          ["bbbbbb"] = {
            posY = 80,
          },
          ["p4rt01/t1p000"] = {
            active = false,
          },
        },
      },
    },
  },
}
