-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "flux",
  description = "Tweens: numbers that move to a value over time",
  -- The library's own version, where it comes from, and its licence.
  version = "0.1.5",
  source = "https://github.com/rxi/flux",
  license = "MIT",
  -- Its component type is the file of components/: components/tweens.lua is flux.tweens.
}
