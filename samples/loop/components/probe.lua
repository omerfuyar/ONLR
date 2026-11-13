-- Writes the frame's calls into shared/log.lua.
local log = require("shared.log")

---@class probe : onlr.Component
local Probe = {}

function Probe:load()
  log.add("load")
end

function Probe:start()
  log.add("start")
end

function Probe:fixedUpdate(dt)
  log.add(("fixedUpdate %.2f"):format(dt))
end

function Probe:update()
  log.add("update")
end

function Probe:lateUpdate()
  log.add("lateUpdate")
end

function Probe:draw()
  log.add("draw")
end

function Probe:keypressed(key)
  log.add("keypressed " .. key)
end

function Probe:ping(value)
  log.add("ping " .. value)
end

-- As love.quit: the game does not quit when this returns true.
function Probe:quit()
  log.add("quit")
  local stay = not self.asked
  self.asked = true
  return stay
end

return Probe
