-- The component type moonshine.effect.filmgrain: moonshine's effect filmgrain. Adds the noise of film, new each frame.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.effect.filmgrain : onlr.Component
local Effect = {}

Effect.opacity = onlr.property.number(0.3, { min = 0, max = 1 })
Effect.size = onlr.property.number(1, { min = 0, description = "The grain's size" })

effect.declare(Effect, "filmgrain", function(self)
  return { opacity = self.opacity, size = self.size }
end)

return Effect
