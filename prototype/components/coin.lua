-- A script that keeps what outlives the root in a module of shared/.
local onlr = require("onlr")
local score = require("shared.score")

---@class coin : onlr.Component
local Coin = {}

-- A declaration. When the engine loads this file it puts the default in its place:
-- Coin.worth is 1 then, and a coin whose node file sets no worth reads 1 as self.worth.
Coin.worth = onlr.property.integer(1, { min = 1 })
Coin.next = onlr.property.nodeFile({ description = "The node file to load as the root when the last coin is taken" })

function Coin:load()
  score.left = score.left + 1
end

function Coin:contact(other)
  if other.name ~= "Player" then
    return
  end
  score.coins = score.coins + self.worth
  score.left = score.left - 1
  -- Marks the node. It and its children are destroyed when the frame ends.
  self.node:destroy()
  if score.left == 0 and self.next then
    -- Ends the root and loads another, when the frame ends.
    onlr.node.loadRoot(self.next)
  end
end

return Coin
