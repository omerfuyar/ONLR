-- Slides its node to a place and back, forever, with an ease, and changes its colour by a timer.
local onlr = require("onlr")

---@class bouncer : onlr.Component
local Bouncer = {}

Bouncer.needs = { "flux.tweens", "tick.timers" }
Bouncer.to = onlr.property.vector(400, 0, { description = "Where it slides to, from where it starts" })
Bouncer.time = onlr.property.number(1.5, { min = 0.1 })
Bouncer.ease = onlr.property.choice("quadinout", { choices = { "linear", "quadinout", "backinout", "elasticout", "expoout", "sineinout" } })

function Bouncer:start()
  local from = { posX = self.node.posX, posY = self.node.posY }
  local to = { posX = from.posX + self.to.x, posY = from.posY + self.to.y }
  local tweens = self.node.components.flux.tweens
  local function go(target, back)
    tweens:to(self.node, self.time, target):ease(self.ease):oncomplete(function()
      go(back, target)
    end)
  end
  go(to, from)
  local paint = self.node.components.onlr.paint
  if paint then
    self.node.components.tick.timers:recur(function()
      paint.color = { love.math.random(), love.math.random(), love.math.random(), 1 }
    end, 0.75)
  end
end

return Bouncer
