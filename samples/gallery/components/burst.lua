-- An explosion's node: it goes when its particles end.
---@class burst : onlr.Component
local Burst = {}

function Burst:particlesEnd()
  self.node:destroy()
end

return Burst
