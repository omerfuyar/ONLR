---@meta onlr

-- What require("onlr") gives. This file joins the engine's other files and does nothing else.
-- In this prototype every file of the engine is definitions only: functions without code.

---@class onlr
local onlr = {}

onlr.scene = require("onlr.scene")
onlr.property = require("onlr.property")

---Starts the engine. Called from main.lua.
function onlr.start() end

---Sets LÖVE's settings from the project file. Called from conf.lua.
---@param t table what love.conf gets
function onlr.conf(t) end

return onlr
