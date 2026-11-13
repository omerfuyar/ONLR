-- The pack's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Pack
return {
  format = 1,
  name = "bump",
  description = "Collision of boxes",
  -- The library's own version, where it comes from, and its licence.
  version = "3.1.7",
  source = "https://github.com/kikito/bump.lua",
  license = "MIT",
  -- The component types that the editor offers, by their files' names:
  -- world is lib/bump/world.lua, and a scene names it bump.world.
  components = {
    "world",
    "body",
  },
}
