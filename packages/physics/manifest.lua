-- The package's manifest. Data only: the editor reads it, and the game never loads it.
-- physics wraps love.physics, LÖVE's own Box2D, so it holds no library: only components (DESIGN 11.4).
---@type onlr.Package
return {
  format = 1,
  name = "physics",
  description = "LÖVE's physics: bodies that fall, collide, bounce and turn",
  version = "0.1.0",
  license = "0BSD",
  -- Its component types are the files of components/: components/body.lua is physics.body.
}
