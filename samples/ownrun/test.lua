-- Checks that a game's own love.run drives the tree through the steps of onlr.loop (DESIGN 8.1).
local check = require("check")
local onlr = require("onlr")

check.run(function()
  local clock = onlr.tree.root.components.clock
  check.frames(6)
  check.equal(clock.frames, 6, "the game's loop updates the components")
  check.equal(clock.time, 6 / 60, "with the time that it gives")
  check.equal(clock.drawn, 6, "and draws them")
end)
