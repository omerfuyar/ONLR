---@meta onlr

-- What require("onlr") gives. This file joins the engine's other files, sets where require looks,
-- and does nothing else.
-- main.lua and conf.lua load it as lib.onlr, which LÖVE finds in the project's folder as it is.
-- When it loads, it adds lib/ to the places where require looks, and answers to the name onlr too.
-- conf.lua loads it before LÖVE's modules for drawing and input are there,
-- so no file of the engine uses them while it loads.
-- In this prototype every file of the engine is definitions only: functions without code.
-- The engine's components, sprite.lua to camera.lua, declare their properties as a script does.

---@class onlr
local onlr = {}

onlr.loop = require("onlr.loop")
onlr.node = require("onlr.tree")
onlr.property = require("onlr.property")

---Starts the engine. Called from main.lua. It sets love.run to the engine's loop, which calls
---the steps of onlr.loop; a game that sets its own love.run calls them itself.
function onlr.start() end

---Sets LÖVE's settings from the project's manifest. Called from conf.lua.
---@param t table what love.conf gets
function onlr.conf(t) end

return onlr
