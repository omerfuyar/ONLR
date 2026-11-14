-- A script with a property of each kind that the inspector has a control for.
local onlr = require("onlr")

---@class thing : onlr.Component
local Thing = {}

Thing.speed = onlr.property.number(10, { min = 0, max = 100 })
Thing.count = onlr.property.integer(1)
Thing.label = onlr.property.string("thing", { label = "Shown name" })
Thing.solid = onlr.property.bool(true)
Thing.mode = onlr.property.choice("walk", { choices = { "walk", "fly" } })
Thing.tint = onlr.property.color({ 1, 1, 1, 1 })
Thing.offset = onlr.property.vector(0, 0)
Thing.picture = onlr.property.image()
Thing.target = onlr.property.node()
Thing.friend = onlr.property.component("thing")
Thing.tags = onlr.property.list(onlr.property.string())
Thing.box = onlr.property.group({
  width = onlr.property.number(32),
  height = onlr.property.number(32),
})

return Thing
