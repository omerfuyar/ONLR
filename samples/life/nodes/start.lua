---@type onlr.NodeFile
return {
  format = 1,
  id = "r00tn0",
  name = "Root",
  components = {
    log = {},
  },
  children = {
    {
      id = "aaaaaa",
      name = "A",
      components = {
        needy = {},
      },
      children = {
        {
          id = "a1a1a1",
          name = "A1",
          components = {
            log = {},
          },
        },
      },
    },
    {
      id = "bbbbbb",
      name = "B",
      active = false,
      components = {
        log = {},
      },
    },
    {
      id = "cccccc",
      name = "C",
      components = {
        log = {
          enabled = false,
        },
      },
    },
  },
}
