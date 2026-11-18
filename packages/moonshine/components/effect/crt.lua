-- The component type moonshine.effect.crt: moonshine's effect crt. Bends the screen as an old tube's glass.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.effect.crt : onlr.Component
local Effect = {}

Effect.distortionFactor = onlr.property.vector(1.06, 1.065, { description = "How much it bends across and down: 1 is flat" })
Effect.scaleFactor = onlr.property.vector(1, 1, { description = "How much of the screen shows: below 1 shows more" })
Effect.feather = onlr.property.number(0.02, { min = 0, description = "How soft the bent edges are" })

effect.declare(Effect, "crt", function(self)
  return { distortionFactor = effect.pair(self.distortionFactor), scaleFactor = effect.pair(self.scaleFactor), feather = self.feather }
end)

return Effect
