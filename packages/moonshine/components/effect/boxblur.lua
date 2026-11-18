-- The component type moonshine.effect.boxblur: moonshine's effect boxblur. Blurs the screen by averaging pixels: cheap, and square.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.effect.boxblur : onlr.Component
local Effect = {}

Effect.radius = onlr.property.vector(3, 3, { description = "How far it blurs across and down, in pixels" })

effect.declare(Effect, "boxblur", function(self)
  return { radius_x = self.radius.x, radius_y = self.radius.y }
end)

return Effect
