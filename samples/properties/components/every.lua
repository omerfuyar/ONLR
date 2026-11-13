-- A type that declares a property of every kind (DESIGN 6.2).
local onlr = require("onlr")

---@class every : onlr.Component
local Every = {}

Every.flag = onlr.property.bool(true)
Every.count = onlr.property.integer(3, { min = 0, max = 10 })
Every.speed = onlr.property.number(1.5, { description = "Pixels a second", label = "Top speed" })
Every.title = onlr.property.string("hello")
Every.side = onlr.property.choice("left", { choices = { "left", "right" } })
Every.tint = onlr.property.color({ 1, 0.5, 0, 1 })
Every.offset = onlr.property.vector(2, 3)
Every.picture = onlr.property.image()
Every.beep = onlr.property.sound()
Every.font = onlr.property.font({ size = 20 })
Every.notes = onlr.property.file({ extensions = { "txt" } })
Every.next = onlr.property.nodeFile()
Every.target = onlr.property.node()
Every.other = onlr.property.component("every")
Every.box = onlr.property.group({
  width = onlr.property.number(32),
  height = onlr.property.number(16),
  picture = onlr.property.image(),
})
Every.frames = onlr.property.list(onlr.property.image())
Every.points = onlr.property.list(onlr.property.vector())
-- Kinds without a default given: each has its own.
Every.plainBool = onlr.property.bool()
Every.plainNumber = onlr.property.number()
Every.plainString = onlr.property.string()
Every.plainColor = onlr.property.color()

return Every
