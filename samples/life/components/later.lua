-- A type whose name comes before log's, so it loads first, unless its node's componentOrder puts log before it (DESIGN 5).
local log = require("shared.log")

---@class later : onlr.Component
local Later = {}

function Later:load()
  log.add(self.node.name .. ".later load")
end

return Later
