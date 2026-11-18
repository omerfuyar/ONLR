-- The component type moonshine.scanlines: moonshine's effect scanlines. Draws lines across the screen, as an old tube does.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.scanlines : onlr.Component
local Effect = {}

Effect.width = onlr.property.number(2, { min = 0, description = "The space of a line, in pixels" })
Effect.phase = onlr.property.number(0, { description = "Moves the lines; a script that moves it scrolls them" })
Effect.thickness = onlr.property.number(1, { min = 0 })
Effect.opacity = onlr.property.number(1, { min = 0, max = 1 })
Effect.color = onlr.property.color({ 0, 0, 0, 1 })

effect.declare(Effect, "scanlines", function(self)
  return { width = self.width, phase = self.phase, thickness = self.thickness, opacity = self.opacity, color = effect.color255(self.color) }
end)

return Effect
