-- A script that keeps what outlives the root in a module of shared/.
local onlr = require("onlr")
local score = require("shared.score")

---@class coin : onlr.Component
local Coin = {}

-- A declaration. When the engine loads this file it puts the default in its place:
-- Coin.worth is 1 then, and a coin whose node file sets no worth reads 1 as self.worth.
Coin.worth = onlr.property.integer(1, { min = 1 })
Coin.next = onlr.property.nodeFile({ description = "The node file to load as the root when the last coin is taken" })

function Coin:contact(other)
  if other.name ~= "Player" or self.node:isDestroyed() then
    return
  end
  score.coins = score.coins + self.worth
  -- Marks the node. It and its children are destroyed when the frame ends,
  -- and stay in the tree until then.
  self.node:destroy()
  -- A component type is a tag: every coin of the tree has this script.
  for _, coin in ipairs(onlr.node.findAllComponents("coin")) do
    if not coin.node:isDestroyed() then
      return
    end
  end
  if self.next then
    -- Ends the root and loads another, when the frame ends.
    onlr.node.loadRoot(self.next)
  end
end

return Coin
