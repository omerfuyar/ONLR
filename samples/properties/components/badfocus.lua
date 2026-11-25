-- A type with a property named as one of LÖVE's callbacks, which the engine refuses (DESIGN 6.2).
local onlr = require("onlr")

local BadFocus = {}

BadFocus.focus = onlr.property.bool(true)

return BadFocus
