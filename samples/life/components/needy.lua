-- A type that needs another: the engine adds a log to its node, and loads the log first.
local log = require("shared.log")

---@class needy : onlr.Component
local Needy = {}

Needy.needs = { "log" }

function Needy:load()
  -- The log is there without a check, and its load was called before this one.
  log.add(self.node.name .. ".needy load, log " .. tostring(self.node.components.log ~= nil))
end

function Needy:destroy()
  log.add(self.node.name .. ".needy destroy")
end

return Needy
