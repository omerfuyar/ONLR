-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "baton",
  description = "Input actions: keys, mouse buttons and gamepads bound to a game's controls",
  -- The library's own version, where it comes from, and its licence.
  version = "1.0.2",
  source = "https://github.com/tesselode/baton",
  license = "MIT",
  -- Its component type is the file of components/: components/input.lua is baton.input.
}
