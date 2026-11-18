---@meta tick

-- The library's definitions, named as the package. A code editor reads them, and the game never does.
-- They are written with the package, since tick ships none.

---A function that a timer calls.
---@class tick.Event
local Event = {}

---Calls another function this many seconds after this one. Not for an event that repeats.
---@param fn function
---@param seconds number
---@return tick.Event
function Event:after(fn, seconds) end

---Calls it no more.
function Event:stop() end

---A group of timers, which moves on when it is updated.
---@class tick.Group
local Group = {}

---Calls fn once, after this many seconds.
---@param fn function
---@param seconds number
---@return tick.Event
function Group:delay(fn, seconds) end

---Calls fn every this many seconds, until it is stopped.
---@param fn function
---@param seconds number
---@return tick.Event
function Group:recur(fn, seconds) end

---@param dt number
function Group:update(dt) end

---@class tick : tick.Group
local tick = {}

---A group of its own, which moves on only when it is updated.
---@return tick.Group
function tick.group() end

return tick
