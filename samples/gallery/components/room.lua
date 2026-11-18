-- A room's title and what it shows, on the room's first node, which the gallery's bar shows.
local onlr = require("onlr")

---@class room : onlr.Component
local Room = {}

Room.title = onlr.property.string("Room")
Room.about = onlr.property.string("", { description = "One line: what the room shows, and the keys it takes" })

return Room
