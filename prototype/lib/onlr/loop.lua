---@meta onlr.loop

-- onlr.loop: the steps that the engine adds to LÖVE's loop. The engine's love.run calls them,
-- around LÖVE's own callbacks, as DESIGN.md's loop says. A game that sets its own love.run
-- calls them from its own loop instead.

---@class onlr.loop
local loop = {}

---Loads the kept nodes and the first root. Called once, after love.load.
function loop.load() end

---Calls the components' function of an event's name, after LÖVE's handler of it.
---@param name string such as "keypressed"
---@param ... any what LÖVE gives with the event
function loop.event(name, ...) end

---Calls the components' fixedUpdate as often as the time asks, then their update, then their lateUpdate.
---Called after love.update.
---@param dt number seconds since the last frame
function loop.update(dt) end

---Calls the components' draw through the camera, in the order of drawing. Called before love.draw.
function loop.draw() end

---Takes out what was destroyed, loads a new root if a script asked for one,
---and calls start of the components that started to run. Called when the frame ends.
function loop.endFrame() end

return loop
