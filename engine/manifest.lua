-- The engine's manifest. Data only: the editor reads it, and the game never loads it.
-- The engine is in packages/ as a package is, so the editor finds its components in the same way.
---@type onlr.Package
return {
  format = 1,
  name = "onlr",
  description = "The engine: nodes and components",
  version = "0.1.0",
  source = "https://github.com/omerfuyar/ONLR",
  license = "zlib",
  -- Its component types are the files of components/: components/sprite.lua is onlr.sprite.
}
