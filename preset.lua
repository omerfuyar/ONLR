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
  -- the search over everything, from any panel, on Unity's key for it (DESIGN 13.8), the game's functions, which the Game bar and
  -- the title bar show, and undo, redo and save, which act on the whole project (DESIGN 13.1)
  keys = {
    ["Ctrl+K"] = "onlr.search",
    ["Ctrl+Z"] = "onlr.undo", ["Ctrl+Y"] = "onlr.redo", ["Ctrl+Shift+Z"] = "onlr.redo", ["Ctrl+S"] = "onlr.save",
    F5 = "onlr.play", F6 = "onlr.playFile", F7 = "onlr.pause", F8 = "onlr.step", ["Shift+F5"] = "onlr.stop",
  },
  settings = {
    -- the title bar's menus, which are the tool's menu (DESIGN 13.2, OpenECS DESIGN 6.11): what acts on the whole project, as
    -- Unity's File, Edit and a menu of the game; the settings and the panels put themselves under Tools
    ["ecs.titleMenus"] = {
      { label = "File", "onlr.newProject", "onlr.openProject", "onlr.save", { "ecs.app.quit", label = "Quit" } },
      {
        label = "Edit",
        "onlr.undo", "onlr.redo",
        { "onlr.copyChosen", label = "Copy" }, { "onlr.pasteChosen", label = "Paste" },
        { "onlr.duplicateChosen", label = "Duplicate" }, { "onlr.deleteChosen", label = "Delete" },
        { "onlr.selectAll", label = "Select All" }, { "onlr.selectWithChildren", label = "Select Children" },
        { "onlr.search", label = "Search" },
      },
      {
        label = "Game",
        { "onlr.play", setting = "onlr.playing" }, "onlr.playFile", { "onlr.pause", label = "Pause", setting = "onlr.paused" },
        "onlr.step", "onlr.stop", { "onlr.restart", label = "Start the Preview Again" },
      },
      { label = "Window", "ecs.layout.reopen", "ecs.layout.maximize", "ecs.layout.popOut", "ecs.layout.lock", "ecs.layout.moveToNewWorkspace", "ecs.layout.reset" },
    },
    -- Play, Pause and Step on the title bar too, as Unity's above its view; the Game bar keeps its own
    ["ecs.titleButtons"] = {
      { "onlr.play", label = "▶", setting = "onlr.playing" },
      { "onlr.pause", label = "||", setting = "onlr.paused" },
      { "onlr.step", label = "▶|" },
    },
  },
  workspaces = {
    {
      name = "Edit",
      windows = {
        {
          split = "vertical",
          -- Action and Game are bars across the top, so their row has the editor's width; Transform is a bar over the node view, where its
          -- tools act (DESIGN 13.1)
          {
            size = 40,
            split = "horizontal",
            { share = 1, panels = { { type = "onlr.action" } } },
            { share = 2, panels = { { type = "onlr.game" } } },
          },
          {
            share = 1,
            split = "horizontal",
            {
              share = 1,
              split = "vertical",
              {
                share = 3,
                split = "horizontal",
                { size = 300, panels = { { type = "onlr.hierarchy" } } },
                {
                  share = 1,
                  split = "vertical",
                  { size = 40, panels = { { type = "onlr.transform" } } },
                  { share = 1, panels = { { type = "onlr.view" } } },
                },
              },
              { share = 2, panels = { { type = "console.log" }, { type = "files.tree" }, { type = "onlr.history" } } },
            },
            {
              size = 340,
              split = "vertical",
              { share = 3, panels = { { type = "onlr.inspector" }, { type = "onlr.settings" }, { type = "onlr.export" } } },
              { share = 1, panels = { { type = "viewer.file" } } },
            },
          },
        },
      },
    },
  },
}
