-- Keeps the names of the animations that its node is told ended, for the test.
---@class probe : onlr.Component
local Probe = {}

function Probe:load()
  self.ended = {}
end

function Probe:animationEnd(name)
  self.ended[#self.ended + 1] = name
end

return Probe
