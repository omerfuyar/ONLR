-- On a button of the bar: its click loads the room a step away.
local onlr = require("onlr")

---@class step : onlr.Component
local Step = {}

Step.by = onlr.property.integer(1, { description = "1 is the next room, -1 the one before" })

function Step:clicked()
  onlr.tree.findComponent("gallery"):go(self.by)
end

return Step
