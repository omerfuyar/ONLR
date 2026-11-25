-- A type with a property named as a function that the engine calls, which the engine refuses (DESIGN 6.2).
local onlr = require("onlr")

local BadUpdate = {}

BadUpdate.update = onlr.property.number(1)

return BadUpdate
