-- A property cannot have a name that a component has.
local onlr = require("onlr")

---@class badname : onlr.Component
local Bad = {}

Bad.node = onlr.property.number(1)

return Bad
