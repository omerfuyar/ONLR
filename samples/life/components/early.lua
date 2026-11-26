-- On the top node's Keeper: it spawns and makes a node without a parent while the top node loads, before the root has loaded,
-- and keeps the errors, so the test reads what they say.
local onlr = require("onlr")
local log = require("shared.log")

---@class early : onlr.Component
local Early = {}

function Early:load()
  local _, spawned = pcall(onlr.tree.spawn, "nodes/alive.lua")
  local _, made = pcall(onlr.tree.newNode, "Early")
  log.early = { spawn = spawned, newNode = made }
end

return Early
