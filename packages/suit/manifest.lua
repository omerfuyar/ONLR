-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "suit",
  description = "An interface inside the game: buttons, labels, checkboxes, sliders and text fields on nodes",
  -- The library's own version, where it comes from, and its licence. SUIT names no version: this is its last commit.
  version = "1767782",
  source = "https://github.com/vrld/suit",
  license = "MIT",
  -- Its component types are the files of components/: components/button.lua is suit.button.
}
