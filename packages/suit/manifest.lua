-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "suit",
  description = "An interface inside the game: buttons, labels, checkboxes, sliders and text fields on nodes",
  -- The package's own version, which grows when ONLR changes the package, and the licence of ONLR's files in it.
  version = "0.1.0",
  license = "0BSD",
  -- The library that it wraps, as its author ships it in library/: its version, where it comes from, and its licence.
  -- SUIT names no version: this is its last commit.
  library = {
    version = "1767782",
    source = "https://github.com/vrld/suit",
    license = "MIT",
  },
  -- Its component types are the files of components/: components/button.lua is suit.button.
}
