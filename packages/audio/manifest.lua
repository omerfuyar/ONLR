-- The package's manifest. Data only: the editor reads it, and the game never loads it.
-- It wraps LÖVE's own sound, love.audio, so it holds no library and names no source (DESIGN 11.2).
---@type onlr.Package
return {
  format = 1,
  name = "audio",
  description = "LÖVE's sound, as sources and a listener on nodes",
  version = "0.1.0",
  license = "zlib",
  -- Its component types are the files of components/: components/source.lua is audio.source.
}
