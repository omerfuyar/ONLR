-- The component type moonshine.godsray: moonshine's effect godsray. Rays of light that spread from a point of the screen.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.godsray : onlr.Component
local Effect = {}

Effect.exposure = onlr.property.number(0.25, { min = 0, max = 1 })
Effect.decay = onlr.property.number(0.95, { min = 0, max = 1 })
Effect.density = onlr.property.number(0.15, { min = 0, max = 1 })
Effect.weight = onlr.property.number(0.5, { min = 0, max = 1 })
Effect.light_position = onlr.property.vector(0.5, 0.5, { label = "Light position", description = "Where the light is, from 0 to 1 across and down the screen" })
Effect.samples = onlr.property.integer(70, { min = 1, description = "More is smoother, and slower" })

effect.declare(Effect, "godsray", function(self)
  return { exposure = self.exposure, decay = self.decay, density = self.density, weight = self.weight, light_position = effect.pair(self.light_position), samples = self.samples }
end)

return Effect
