-- Names files: an image, and node files to spawn, one of them loaded ahead.
local onlr = require("onlr")

---@class holder : onlr.Component
local Holder = {}

Holder.picture = onlr.property.image()
-- preload: the node file and the files that it names load with this component's own node file.
Holder.ahead = onlr.property.nodeFile({ preload = true })
Holder.later = onlr.property.nodeFile()

return Holder
