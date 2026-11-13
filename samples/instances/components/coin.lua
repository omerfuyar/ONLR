-- A coin: it holds a value, and names its own glint, a node of its own file.
local onlr = require("onlr")

---@class coin : onlr.Component
local Coin = {}

Coin.worth = onlr.property.integer(1)
-- An id of the coin's own file: in each instance, it gives that instance's own glint.
Coin.glint = onlr.property.node()
-- A node outside the coin's file: an instance's change sets it, with an id of the file that holds the instance.
Coin.owner = onlr.property.node()
Coin.box = onlr.property.group({
  width = onlr.property.number(8),
  height = onlr.property.number(8),
})

return Coin
