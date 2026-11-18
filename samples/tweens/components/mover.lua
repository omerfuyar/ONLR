-- A script that uses its node's tweens and timers: it slides its node right and fades its sprite, ticks every
-- quarter of a second, and notes what happened, for the test.
---@class mover : onlr.Component
local Mover = {}

Mover.needs = { "flux.tweens", "tick.timers" }

function Mover:load()
  self.slid, self.ticks, self.later = false, 0, false
  local tweens = self.node.components.flux.tweens
  local timers = self.node.components.tick.timers
  tweens:to(self.node, 1, { posX = 100 }):ease("linear"):oncomplete(function()
    self.slid = true
  end)
  self.ticker = timers:recur(function()
    self.ticks = self.ticks + 1
  end, 0.25)
  timers:delay(function()
    self.later = true
  end, 0.5)
end

return Mover
