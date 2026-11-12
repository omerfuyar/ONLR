local onlr = require("onlr")
local score = require("scripts.score")

---@class scripts.coin : onlr.Component
local Coin = {}

Coin.worth = onlr.property.integer(1, { min = 1 })
Coin.next = onlr.property.scene({ description = "The scene to load when the last coin is taken" })

function Coin:load()
  score.left = score.left + 1
end

function Coin:contact(other)
  if other.name ~= "Player" then
    return
  end
  score.coins = score.coins + self.worth
  score.left = score.left - 1
  -- Destroys the object and its children when the frame ends.
  self.object:destroy()
  if score.left == 0 and self.next then
    -- Ends this scene and loads another, when the frame ends.
    onlr.scene.load(self.next)
  end
end

return Coin
