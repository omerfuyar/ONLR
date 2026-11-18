-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "bump",
  description = "Collision of boxes",
  -- The library's own version, where it comes from, and its licence.
  version = "3.1.7",
  source = "https://github.com/kikito/bump.lua",
  license = "MIT",
  -- Its component types are the files of components/: components/world.lua is bump.world.
}
