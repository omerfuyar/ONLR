-- On a button: its click plays a sound of another node.
local onlr = require("onlr")

---@class player : onlr.Component
local Player = {}

Player.sound = onlr.property.component("audio.source", { description = "The sound that a click plays" })
Player.over = onlr.property.bool(true, { description = "Each click plays a new copy, over those that play" })

function Player:clicked()
  if self.sound then
    if self.over then
      self.sound:playNew()
    else
      self.sound:play()
    end
  end
end

return Player
