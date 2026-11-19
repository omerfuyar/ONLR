-- A crate that falls: a body, its box, and the box drawn.
---@type onlr.NodeFile
return {
  format = 1,
  id = "cr4t00",
  name = "Crate",
  components = {
    onlr = {
      paint = {
        color = {
          0.8,
          0.55,
          0.3,
          1,
        },
      },
      shape = {
        height = 20,
        width = 20,
      },
    },
    physics = {
      body = {},
      fixture = {
        restitution = 0.3,
      },
    },
  },
}
