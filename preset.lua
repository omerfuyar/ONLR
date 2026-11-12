-- A preset describes a tool: its name, the plugins it needs, its settings and keys, and where their panels go.
-- Run the tool with: OpenECS/OpenECS --fresh --preset preset.lua
---@type ecs.Preset
return {
  format = 3,      -- the version of this file's format
  name = "mytool", -- the name --preset and the launcher know the preset by
  version = "0.1.0",
  -- the id names the tool's saved session and its desktop file, and the name is the window's title
  app = { id = "org.example.MyTool", name = "My tool" },
  depends = { notes = "0.1", pulse_c = "0.1" }, -- the plugins to load, with the lowest version each accepts
  pluginsDir = "plugins",                       -- plugins are looked for in this folder first

  -- settings of the tool, above OpenECS's defaults and below the user's settings file
  settings = { ["notes.newestFirst"] = false },

  -- keys of the tool: Ctrl+D removes the chosen note too, while a board has the focus
  keys = { ["notes.board"] = { ["Ctrl+D"] = "notes.remove" } },

  -- each workspace holds a layout tree for each OS window: here, the board beside the pulse, which is 300 units wide
  workspaces = {
    {
      name = "Main",
      windows = {
        {
          split = "horizontal",
          { share = 1,  panels = { { type = "notes.board" } } },
          { size = 300, panels = { { type = "pulse_c.panel" } } },
        },
      },
    },
  },
}
