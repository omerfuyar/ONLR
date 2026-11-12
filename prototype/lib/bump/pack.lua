-- The pack file. Data only: the editor reads it, and the game never loads it.
---@type onlr.Pack
return {
  format = 1,
  name = "bump",
  description = "Collision of boxes",
  -- The library's own version, where it comes from, and its licence.
  version = "3.1.7",
  source = "https://github.com/kikito/bump.lua",
  license = "MIT",
  -- The component types that the editor offers when the user adds a component.
  components = { "bump.world", "bump.body" },
}
