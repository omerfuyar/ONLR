-- A script that keeps what outlives a scene in a module of shared/.
local onlr = require("onlr")
local score = require("shared.score")

---@class components.coin : onlr.Component
local Coin = {}

-- A declaration. When the engine loads this file it puts the default in its place:
-- Coin.worth is 1 then, and a coin whose scene sets no worth reads 1 as self.worth.
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
  -- Marks the object. It and its children are destroyed when the frame ends.
  self.object:destroy()
  if score.left == 0 and self.next then
    -- Ends this scene and loads another, when the frame ends.
    onlr.scene.load(self.next)
  end
end

return Coin
