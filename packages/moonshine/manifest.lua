-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "moonshine",
  description = "Screen effects: blur, glow, vignette, CRT and more, drawn over a node and all under it",
  -- The package's own version, which grows when ONLR changes the package, and the licence of ONLR's files in it.
  version = "0.1.0",
  license = "0BSD",
  -- The library that it wraps, as its author ships it in library/: its version, where it comes from, and its licence.
  -- moonshine names no version: this is its last commit.
  library = {
    version = "d39271e",
    source = "https://github.com/vrld/moonshine",
    license = "MIT",
  },
  -- Its component types are the files of components/: components/chain.lua is moonshine.chain, and each effect is one,
  -- such as components/effect/vignette.lua, moonshine.effect.vignette.
}
