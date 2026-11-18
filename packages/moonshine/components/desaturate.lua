-- The component type moonshine.desaturate: moonshine's effect desaturate. Takes the colour out, toward a tint.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.desaturate : onlr.Component
local Effect = {}

Effect.tint = onlr.property.color({ 1, 1, 1, 1 }, { description = "The colour of grey" })
Effect.strength = onlr.property.number(0.5, { min = 0, max = 1, description = "1 is grey only" })

effect.declare(Effect, "desaturate", function(self)
  return { tint = effect.color255(self.tint), strength = self.strength }
end)

return Effect
