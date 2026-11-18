-- On a widget: what the widget tells its node, it passes to a function of another node's components.
local onlr = require("onlr")

---@class relay : onlr.Component
local Relay = {}

Relay.to = onlr.property.node({ description = "The node that is told" })
Relay.call = onlr.property.string("", { description = "The function that it calls there, with the widget's value" })

function Relay:changed(value)
  if self.to and self.call ~= "" then
    self.to:send(self.call, value)
  end
end

Relay.submitted = Relay.changed

function Relay:clicked()
  if self.to and self.call ~= "" then
    self.to:send(self.call)
  end
end

return Relay
