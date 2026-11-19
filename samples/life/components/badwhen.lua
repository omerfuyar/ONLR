-- A type whose property is shown when a property that the type does not declare has a value: the engine refuses it.
local onlr = require("onlr")

local BadWhen = {}

BadWhen.radius = onlr.property.number(16, { when = { kidn = "circle" } })

return BadWhen
