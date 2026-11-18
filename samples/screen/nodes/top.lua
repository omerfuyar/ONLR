-- The top node, which holds the whole game: its screen draws everything at 320 by 180, scaled to the window.
---@type onlr.NodeFile
return {
  format = 1,
  id = "t0p000",
  name = "Top",
  components = {
    push = {
      screen = {},
    },
  },
}
