-- A node file that the test spawns and destroys in every frame.
---@type onlr.NodeFile
return {
  format = 1,
  id = "d0t000",
  name = "Dot",
  components = {
    mover = {},
    onlr = {
      sprite = {
        image = "images/dot.png",
      },
    },
  },
}
