-- The component type flux.tweens: the tweens of a node. Its tweens are a group of flux's own, which moves on in the
-- component's update. So they stop with their node: they wait while it is turned off or paused, and end when it is
-- destroyed, and none calls a function of a node that is gone.
local flux = require("flux")

---@class flux.tweens : onlr.Component
---@field private group flux.Group
local Tweens = {}

function Tweens:load()
  self.group = flux.group()
end

function Tweens:update(dt)
  self.group:update(dt)
end

-- Not called by the engine: scripts call these.

-- Moves the numbers of a table to the values in vars, in time seconds, as flux.to does: the node itself, such as
-- { posX = 100 }, another component, or any table. Its functions chain: :ease("linear"):oncomplete(fn).
---@param obj table
---@param time number
---@param vars table<any, number>
---@return flux.Tween
function Tweens:to(obj, time, vars)
  return self.group:to(obj, time, vars)
end

-- Stops the tweens of a table, or every tween of the node without one. They stay where they are, and call no
-- oncomplete. It is safe in a tween's own function: the stopped tweens are not taken out of the group that may be
-- updating, which flux's own stop does by moving another into their place, but left there with nothing to do, and the
-- others go on in a new group.
---@param obj? table
function Tweens:stop(obj)
  local old, group = self.group, flux.group()
  for i = 1, #old do
    local t = old[i]
    if obj == nil or t.obj == obj then
      t._delay, t._onstart, t._onupdate, t._oncomplete = math.huge, nil, nil, nil
    else
      group:add(t)
    end
  end
  self.group = group
end

-- The tweens that move, or wait for their delay.
---@return integer
function Tweens:count()
  return #self.group
end

return Tweens
