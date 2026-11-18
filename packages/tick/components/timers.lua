-- The component type tick.timers: the timers of a node. Its timers are a group of tick's own, which moves on in the
-- component's update. So they stop with their node: they wait while it is turned off or paused, and end when it is
-- destroyed, and none calls a function of a node that is gone.
local tick = require("tick")

---@class tick.timers : onlr.Component
---@field private group tick.Group
local Timers = {}

function Timers:load()
  self.group = tick.group()
end

function Timers:update(dt)
  self.group:update(dt)
end

-- Not called by the engine: scripts call these.

-- Calls fn once, after this many seconds. :after(fn, seconds) chains another.
---@param fn function
---@param seconds number
---@return tick.Event
function Timers:delay(fn, seconds)
  return self.group:delay(fn, seconds)
end

-- Calls fn every this many seconds, until :stop() on what it returns.
---@param fn function
---@param seconds number
---@return tick.Event
function Timers:recur(fn, seconds)
  return self.group:recur(fn, seconds)
end

-- Stops every timer of the node. It is safe in a timer's own function: the timers are not taken out of the group that
-- may be updating, which tick's own stop does by moving another into their place, but left there with nothing to do.
local function nothing() end
function Timers:stop()
  for i = 1, #self.group do
    local e = self.group[i]
    e.fn, e.recur, e.timer = nothing, false, math.huge
  end
  self.group = tick.group()
end

-- The timers that wait.
---@return integer
function Timers:count()
  return #self.group
end

return Timers
