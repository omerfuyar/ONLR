-- The component type moonshine.sketch: moonshine's effect sketch. Wobbles the screen, as a drawing by hand.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.sketch : onlr.Component
local Effect = {}

Effect.amp = onlr.property.number(0.0007, { min = 0, description = "How far it wobbles" })
Effect.center = onlr.property.vector(0, 0, { description = "Moves the wobble; a script that moves it animates it" })

effect.declare(Effect, "sketch", function(self)
  return { amp = self.amp, center = effect.pair(self.center) }
end)

return Effect
