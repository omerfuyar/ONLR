-- The component type moonshine.effect.pixelate: moonshine's effect pixelate. Draws the screen in large pixels.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.effect.pixelate : onlr.Component
local Effect = {}

Effect.size = onlr.property.vector(5, 5, { description = "A large pixel's size, across and down" })
Effect.feedback = onlr.property.number(0, { min = 0, max = 1, description = "How much of the sharp screen shows through" })

effect.declare(Effect, "pixelate", function(self)
  return { size = effect.pair(self.size), feedback = self.feedback }
end)

return Effect
