-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "anim8",
  description = "Animations of a sprite sheet",
  -- The library's own version, where it comes from, and its licence.
  version = "2.3.1",
  source = "https://github.com/kikito/anim8",
  license = "MIT",
  -- Its component type is the file of components/: components/animation.lua is anim8.animation.
}
