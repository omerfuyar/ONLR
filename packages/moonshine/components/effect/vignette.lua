-- The component type moonshine.effect.vignette: moonshine's effect vignette. Darkens the screen's edges.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.effect.vignette : onlr.Component
local Effect = {}

Effect.radius = onlr.property.number(0.8, { min = 0, description = "Where the darkening starts, from the middle: 1 is the screen's edge" })
Effect.softness = onlr.property.number(0.5, { min = 0, description = "How far the darkening fades in" })
Effect.opacity = onlr.property.number(0.5, { min = 0, max = 1 })
Effect.color = onlr.property.color({ 0, 0, 0, 1 })

effect.declare(Effect, "vignette", function(self)
  return { radius = self.radius, softness = self.softness, opacity = self.opacity, color = effect.color255(self.color) }
end)

return Effect
