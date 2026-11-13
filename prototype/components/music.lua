-- A script on a kept node: it plays music for the whole game.
local onlr = require("onlr")

---@class music : onlr.Component
local Music = {}

-- stream: LÖVE streams the file, as music needs, and does not decode it whole.
Music.track = onlr.property.sound({ stream = true })
Music.volume = onlr.property.number(0.5, { min = 0, max = 1 })

function Music:enable()
  if self.track then
    self.track:setLooping(true)
    self.track:setVolume(self.volume)
    self.track:play()
  end
end

function Music:disable()
  if self.track then
    self.track:pause()
  end
end

return Music
