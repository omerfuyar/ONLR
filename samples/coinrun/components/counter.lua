-- A script beside the engine's text on the score's node: it shows the score in that text.
local onlr = require("onlr")
local score = require("shared.score")

---@class counter : onlr.Component
local Counter = {}

-- The text is the engine's component on the same node. needs adds it with the script.
Counter.needs = { "onlr.text" }

Counter.prefix = onlr.property.string("Coins: ")

function Counter:update()
  self.node.components.onlr.text.text = self.prefix .. score.coins
end

return Counter
