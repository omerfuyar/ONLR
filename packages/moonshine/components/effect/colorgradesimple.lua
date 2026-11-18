-- The component type moonshine.effect.colorgradesimple: moonshine's effect colorgradesimple. Multiplies red, green and blue, each by its own factor.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.effect.colorgradesimple : onlr.Component
local Effect = {}

Effect.factors = onlr.property.group({ r = onlr.property.number(1, { min = 0 }), g = onlr.property.number(1, { min = 0 }), b = onlr.property.number(1, { min = 0 }) }, { description = "1 keeps a colour, below 1 dims it and above 1 brightens it" })

effect.declare(Effect, "colorgradesimple", function(self)
  return { factors = { self.factors.r, self.factors.g, self.factors.b } }
end)

return Effect
