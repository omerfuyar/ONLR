-- Keeps what its node is told by a widget, for the test.
---@class probe : onlr.Component
local Probe = {}

function Probe:load()
  self.told = {}
end

function Probe:clicked()
  self.told[#self.told + 1] = "clicked"
end

function Probe:changed(value)
  self.told[#self.told + 1] = value
end

function Probe:submitted(text)
  self.told[#self.told + 1] = "submitted " .. text
end

return Probe
