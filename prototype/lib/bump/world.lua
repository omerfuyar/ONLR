-- The component type bump.world: bump's world, as a component.
-- bump's world is bump's own list of boxes. It is not the scene and knows nothing of objects.
-- One object of a scene has this component, so each scene has its own world,
-- and the scene's file keeps the world's settings.
local onlr = require("onlr")
local bump = require("bump")

---@class bump.world : onlr.Component
local World = {}

World.cellSize = onlr.property.number(64, { min = 1, description = "The size of the cells that bump sorts boxes into" })

-- Not called by the engine: bodies call it. It makes bump's world at the first call,
-- so it does not matter whose load runs first.
function World:get()
  self.world = self.world or bump.newWorld(self.cellSize)
  return self.world
end

return World
