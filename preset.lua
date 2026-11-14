-- ONLR's editor, as an OpenECS tool: the plugins it needs, and where their panels go (DESIGN 13.1).
-- Run it with: OpenECS/OpenECS --preset preset.lua, and a project's folder after it to open the project.
---@type ecs.Preset
return {
  format = 3,
  name = "onlr",
  version = "0.1.0",
  app = { id = "io.github.omerfuyar.ONLR", name = "ONLR" },
  depends = { onlr_project = "0.1", onlr_player = "0.1", onlr_views = "0.1", onlr_export = "0.1", console = "0.1", files = "0.1", viewer = "0.1" },
  pluginsDir = "plugins",
  -- a project's folder, or a file in it, named on the command line opens the project (DESIGN 13.2)
  open = "onlr_project.openPath",
  settings = {
    -- the tool's menu: a right click on the title bar opens it
    ["ecs.toolMenu"] = {
      "onlr_project.newProject", "onlr_project.openProject", "onlr_project.save", "onlr_project.undo", "onlr_project.redo",
      "onlr_player.play", "onlr_player.playFile", "onlr_player.pause", "onlr_player.step", "onlr_player.stop",
      "onlr_player.restart", "onlr_export.love", "onlr_export.linux", "onlr_export.windows", "settings.open", "panels.open",
    },
  },
  workspaces = {
    {
      name = "Edit",
      windows = {
        {
          split = "horizontal",
          {
            size = 260,
            split = "vertical",
            { share = 1, panels = { { type = "onlr_views.nodes" } } },
            { share = 1, panels = { { type = "files.tree" } } },
          },
          {
            share = 1,
            split = "vertical",
            { size = 132, panels = { { type = "onlr_views.tools" } } },
            { share = 3, panels = { { type = "onlr_player.view" } } },
            { share = 1, panels = { { type = "console.log" } } },
          },
          { size = 340, panels = { { type = "onlr_views.inspector" }, { type = "onlr_views.settings" }, { type = "onlr_export.panel" } } },
        },
      },
    },
  },
}
