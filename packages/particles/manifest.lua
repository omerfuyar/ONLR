-- The package's manifest. Data only: the editor reads it, and the game never loads it.
-- It wraps LÖVE's own particle systems, so it holds no library and names no source (DESIGN 11.2).
---@type onlr.Package
return {
  format = 1,
  name = "particles",
  description = "LÖVE's particle systems, as an emitter on a node",
  version = "0.1.0",
  license = "zlib",
  -- Its component type is the file of components/: components/emitter.lua is particles.emitter.
}
