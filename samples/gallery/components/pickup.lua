-- A coin: a body that touches it takes it, and the coin goes.
---@class pickup : onlr.Component
local Pickup = {}

function Pickup:contact()
  self.node:destroy()
end

return Pickup
