-- Counts the times that its node is told that its sound ended, for the test.
---@class probe : onlr.Component
local Probe = {}

function Probe:load()
  self.ends = 0
end

function Probe:soundEnd()
  self.ends = self.ends + 1
end

return Probe
