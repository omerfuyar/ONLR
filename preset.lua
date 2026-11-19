-- ONLR's editor, as an OpenECS tool: the plugins it needs, and where their panels go (DESIGN 13.1).
-- Run it with: OpenECS/OpenECS --preset preset.lua, and a project's folder after it to open the project.
---@type ecs.Preset
return {
  format = 3,
  name = "onlr",
  version = "0.1.0",
  app = { id = "io.github.omerfuyar.ONLR", name = "ONLR" },
  depends = { onlr = "0.1", console = "0.1", files = "0.1", viewer = "0.1" },
  pluginsDir = "plugins",
  -- a project's folder, or a file in it, named on the command line opens the project (DESIGN 13.2)
  open = "onlr.openPath",
  settings = {
    -- the tool's menu: a right click on the title bar opens it. It holds what concerns the whole tool; the history,
    -- pausing and export are in their panels and on keys (DESIGN 13.2)
    ["ecs.toolMenu"] = {
      "onlr.newProject", "onlr.openProject", "onlr.save", "onlr.play", "onlr.playFile", "onlr.stop", "settings.open", "panels.open",
    },
  },
  workspaces = {
    {
      name = "Edit",
      windows = {
        {
          split = "horizontal",
          {
            share = 1,
            split = "vertical",
            {
              share = 3,
              split = "horizontal",
              {
                size = 370,
                split = "vertical",
                { size = 118, panels = { { type = "onlr.tools" } } },
                { share = 1, panels = { { type = "onlr.nodes" } } },
              },
              { share = 1, panels = { { type = "onlr.view" } } },
            },
            { share = 2, panels = { { type = "console.log" }, { type = "files.tree" }, { type = "onlr.history" } } },
          },
          {
            size = 340,
            split = "vertical",
            { share = 2, panels = { { type = "onlr.inspector" }, { type = "onlr.settings" }, { type = "onlr.export" } } },
            { share = 1, panels = { { type = "viewer.file" } } },
          },
        },
      },
    },
  },
}
