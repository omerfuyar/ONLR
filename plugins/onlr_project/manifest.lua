-- The plugin that holds the open project (DESIGN 13.1).
---@type ecs.Manifest
return {
  name = "onlr_project",
  version = "0.1.0",
  api = 2,
  type = "lua",
  description = "The open project: its files, the chosen nodes and the history",
  depends = { fs = "0.1", process = "0.1" },
}
