-- Names nodes inside instances, by paths of ids.
local onlr = require("onlr")

---@class watcher : onlr.Component
local Watcher = {}

Watcher.coin = onlr.property.node()
Watcher.glint = onlr.property.node()
Watcher.inner = onlr.property.component("coin")

return Watcher
