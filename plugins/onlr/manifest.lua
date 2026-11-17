-- ONLR's editor plugin (DESIGN 13.1).
---@type ecs.Manifest
return {
  name = "onlr",
  version = "0.1.0",
  api = 2,
  type = "lua",
  description = "ONLR's editor: the open project, the runners and the link, its panels, and export",
  depends = {
    console = "0.1", files = "0.1", viewer = "0.1", ui = "0.1", draw = "0.1", gpu = "0.1", fs = "0.1", process = "0.1", net = "0.1",
    compress = "0.1", hash = "0.1", web = "0.1",
  },
}
