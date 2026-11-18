-- Writes every call of its life into shared/log.lua, so the test reads the order of the calls.
local log = require("shared.log")

---@class log : onlr.Component
local Log = {}

for _, name in ipairs({ "load", "enable", "start", "fixedUpdate", "update", "lateUpdate", "draw", "disable", "destroy", "keypressed" }) do
  Log[name] = function(self)
    log.add(self.node.name .. "." .. name)
  end
end

-- Not the engine's: node:send("ping") calls it.
function Log:ping(value)
  log.add(self.node.name .. ".ping " .. tostring(value))
end

return Log
