-- Keeps what its node is told of its contacts, for the test.
---@class probe : onlr.Component
local Probe = {}

function Probe:load()
  self.hits, self.ends = {}, {}
end

function Probe:contact(other, nx, ny)
  self.hits[#self.hits + 1] = { other.name, nx, ny }
end

function Probe:contactEnd(other)
  self.ends[#self.ends + 1] = other.name
end

return Probe
