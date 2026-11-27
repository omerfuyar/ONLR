-- A node whose shader does not compile, which the test spawns to read the error (DESIGN 6.7).
---@type onlr.NodeFile
return {
  format = 1,
  id = "br0k3n",
  name = "Broken",
  components = {
    onlr = {
      shader = {
        passes = { { shader = "effects/broken.glsl" } },
      },
    },
  },
}
