-- A node file with a mistake, which the test loads to read the error.
---@type onlr.NodeFile
return {
  format = 1,
  id = "m1stak",
  name = "Mistake",
  components = {
    every = {
      target = "n0such",
    },
  },
}
