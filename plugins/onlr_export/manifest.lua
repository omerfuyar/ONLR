-- The plugin that exports the game (DESIGN 13.1).
---@type ecs.Manifest
return {
  name = "onlr_export",
  version = "0.1.0",
  api = 2,
  type = "lua",
  description = "Export: the .love file, the builds, and LÖVE's runtimes",
  depends = { onlr_project = "0.1", console = "0.1", ui = "0.1", fs = "0.1", compress = "0.1", hash = "0.1", web = "0.1", process = "0.1" },
}
