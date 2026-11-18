-- Adds up the time that the loop gives it.
---@class clock : onlr.Component
local Clock = {}

function Clock:load()
  self.time = 0
  self.frames = 0
  self.drawn = 0
end

function Clock:update(dt)
  self.time = self.time + dt
  self.frames = self.frames + 1
end

function Clock:draw()
  self.drawn = self.drawn + 1
end

return Clock
