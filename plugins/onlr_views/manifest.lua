-- The panels of ONLR's own, apart from the node view (DESIGN 13.1).
---@type ecs.Manifest
return {
  name = "onlr_views",
  version = "0.1.0",
  api = 2,
  type = "lua",
  description = "The nodes panel, the inspector, the tools and the project settings",
  depends = { onlr_project = "0.1", onlr_player = "0.1", console = "0.1", files = "0.1", viewer = "0.1", ui = "0.1", fs = "0.1" },
}
