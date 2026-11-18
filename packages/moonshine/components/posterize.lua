-- The component type moonshine.posterize: moonshine's effect posterize. Draws with fewer colours.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.posterize : onlr.Component
local Effect = {}

Effect.num_bands = onlr.property.integer(3, { min = 1, label = "Num bands", description = "The steps of each of hue, saturation and value" })

effect.declare(Effect, "posterize", function(self)
  return { num_bands = self.num_bands }
end)

return Effect
