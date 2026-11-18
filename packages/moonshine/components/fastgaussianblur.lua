-- The component type moonshine.fastgaussianblur: moonshine's effect fastgaussianblur. Blurs the screen, faster than gaussianblur for a large blur.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.fastgaussianblur : onlr.Component
local Effect = {}

Effect.taps = onlr.property.integer(7, { min = 3, description = "Samples on each side and the middle: odd, and more is a larger, slower blur" })
Effect.offset = onlr.property.number(1, { min = 0, description = "The space between samples: above 1 blurs more with fewer taps" })
Effect.offset_type = onlr.property.choice("weighted", { choices = { "weighted", "center" }, label = "Offset type" })
Effect.sigma = onlr.property.number(-1, { description = "The gaussian's width; -1 works it out from taps" })

effect.declare(Effect, "fastgaussianblur", function(self)
  return { taps = self.taps, offset = self.offset, offset_type = self.offset_type, sigma = self.sigma }
end)

return Effect
