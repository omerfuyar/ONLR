-- The component type moonshine.gaussianblur: moonshine's effect gaussianblur. Blurs the screen.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.gaussianblur : onlr.Component
local Effect = {}

Effect.sigma = onlr.property.number(1, { min = 0, description = "How much it blurs" })

effect.declare(Effect, "gaussianblur", function(self)
  return { sigma = self.sigma }
end)

return Effect
