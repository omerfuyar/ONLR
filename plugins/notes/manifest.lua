-- A manifest describes a plugin. OpenECS reads it as data, before any of the plugin's code runs.
---@type ecs.Manifest
return {
  name = "notes",           -- the folder's name; OpenECS puts it before every name the plugin declares
  version = "0.1.0",        -- major.minor.patch; presets and other plugins ask for a lowest version
  api = 2,                  -- the version of OpenECS's plugin interface it was written for
  type = "lua",             -- its code starts in init.lua, in this folder
  description = "A board of short notes",
  depends = { ui = "0.1" }, -- ui loads first, and require("ui") gives its functions
}
