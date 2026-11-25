-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "bump",
  description = "Collision of boxes",
  -- The package's own version, which grows when ONLR changes the package, and the licence of ONLR's files in it.
  version = "0.1.0",
  license = "0BSD",
  -- The library that it wraps, as its author ships it in library/: its version, where it comes from, and its licence.
  library = {
    version = "3.1.7",
    source = "https://github.com/kikito/bump.lua",
    license = "MIT",
  },
  -- Its component types are the files of components/: components/world.lua is bump.world.
}
