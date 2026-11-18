-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "push",
  description = "The game drawn at a fixed size, and scaled to the window",
  -- The library's own version, where it comes from, and its licence.
  version = "0.4",
  source = "https://github.com/Ulydev/push",
  license = "MIT",
  -- Its component type is the file of components/: components/screen.lua is push.screen.
}
