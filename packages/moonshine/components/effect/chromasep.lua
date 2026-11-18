-- The component type moonshine.effect.chromasep: moonshine's effect chromasep. Pulls red and blue apart, as a cheap lens does.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.effect.chromasep : onlr.Component
local Effect = {}

Effect.angle = onlr.property.number(0, { description = "The direction, in radians" })
Effect.radius = onlr.property.number(0, { min = 0, description = "How far apart, in pixels" })

effect.declare(Effect, "chromasep", function(self)
  return { angle = self.angle, radius = self.radius }
end)

return Effect
