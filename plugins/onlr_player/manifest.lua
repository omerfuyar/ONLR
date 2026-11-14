-- The plugin that starts the players and speaks the link (DESIGN 13.1).
---@type ecs.Manifest
return {
  name = "onlr_player",
  version = "0.1.0",
  api = 2,
  type = "lua",
  description = "The players and the link: the node view, Play, Pause, Step and Stop",
  depends = { onlr_project = "0.1", console = "0.1", net = "0.1", process = "0.1", draw = "0.1" },
}
