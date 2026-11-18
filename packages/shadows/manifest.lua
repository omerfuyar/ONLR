-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "shadows",
  description = "Lights that cast shadows: a world of light over a node and all under it, lights, and shapes that block them",
  -- The library's own version, where it comes from, and its licence. Shädows names no version: this is the commit
  -- that ONLR's copy was made from, changed as library/ONLR.md says.
  version = "ccb3597",
  source = "https://github.com/matiasah/shadows",
  license = "MIT",
  -- Its component types are the files of components/: components/world.lua is shadows.world, and
  -- components/shape/box.lua is shadows.shape.box.
}
