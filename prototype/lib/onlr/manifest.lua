-- The engine's manifest. Data only: the editor reads it, and the game never loads it.
-- The engine is in lib/ as a pack is, so the editor finds its components in the same way.
---@type onlr.Pack
return {
  format = 1,
  name = "onlr",
  description = "The engine: scenes, objects and components",
  version = "0.1.0",
  source = "https://github.com/omerfuyar/ONLR",
  license = "zlib",
  -- By their files' names: sprite is lib/onlr/sprite.lua, and a scene names it onlr.sprite.
  components = {
    "sprite",
    "text",
    "shape",
    "camera",
  },
}
