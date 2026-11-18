-- A component that one instance adds to its coin.
local onlr = require("onlr")

---@class spin : onlr.Component
local Spin = {}

Spin.speed = onlr.property.number(1)

return Spin
