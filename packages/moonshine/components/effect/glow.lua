-- The component type moonshine.effect.glow: moonshine's effect glow. Makes what is bright shine around it.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.effect.glow : onlr.Component
local Effect = {}

Effect.strength = onlr.property.number(5, { min = 0, description = "How far the light spreads" })
Effect.min_luma = onlr.property.number(0.7, { min = 0, max = 1, label = "Min luma", description = "How bright a pixel is before it glows" })

effect.declare(Effect, "glow", function(self)
  return { strength = self.strength, min_luma = self.min_luma }
end)

return Effect
