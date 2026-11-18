-- The component type moonshine.dmg: moonshine's effect dmg. Draws with the four colours of an old handheld's screen.
-- It goes beside moonshine.chain on its node, and its properties are the effect's parameters, named as moonshine
-- names them (DESIGN 11.11).
local onlr = require("onlr")
local effect = require("moonshine.effect")

---@class moonshine.dmg : onlr.Component
local Effect = {}

Effect.palette = onlr.property.choice("default", { choices = { "default", "dark_yellow", "light_yellow", "green", "greyscale", "stark_bw", "pocket" } })

effect.declare(Effect, "dmg", function(self)
  return { palette = self.palette }
end)

return Effect
