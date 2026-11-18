-- On a checkbox: it turns another node on or off, such as music, or an effect's node.
local onlr = require("onlr")

---@class switch : onlr.Component
local Switch = {}

Switch.target = onlr.property.node({ description = "The node that the checkbox turns on and off" })

function Switch:changed(checked)
  if self.target then
    self.target:setActive(checked)
  end
end

return Switch
