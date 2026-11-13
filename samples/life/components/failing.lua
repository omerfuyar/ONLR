-- A type that fails when it loads: the link's test reads the error that the player sends.
---@class failing : onlr.Component
local Failing = {}

function Failing:load()
  error("this component fails in load")
end

return Failing
