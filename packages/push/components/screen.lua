-- The component type push.screen: the game drawn at a fixed size, such as 320 by 180, and scaled to the window,
-- with bars where the window's shape differs. It is a group (DESIGN 5): its node and all under it draw scaled to the
-- window, or with canvas into push's canvas, at the game's size, which push then draws into the window. On the top node, it holds the whole game.
local onlr = require("onlr")
local push = require("push")

---@class push.screen : onlr.Component
---@field private applied string the settings that push was set up with
local Screen = {}

Screen.width = onlr.property.number(320, { min = 1, description = "The game's width, in its own pixels" })
Screen.height = onlr.property.number(180, { min = 1, description = "The game's height, in its own pixels" })
Screen.pixelPerfect = onlr.property.bool(false, { description = "Scales by whole numbers only, so each pixel of the game is a square of the window's; the bars are wider" })
Screen.stretched = onlr.property.bool(false, { description = "Fills the window, with no bars, and stretches the game where the window's shape differs" })
Screen.borderColor = onlr.property.color({ 0, 0, 0, 1 }, { description = "The colour of the bars" })
Screen.canvas = onlr.property.bool(false, { description = "Draws the game into a canvas of its size, then scales the canvas, as pixel art needs; without it the drawing is scaled, so text and large images stay sharp" })

-- push is one table for the whole game, so one screen runs at a time.
---@type push.screen?
local running

function Screen:enable()
  if running and running ~= self and not running.node:isDestroyed() and running:isEnabled() then
    error("push.screen: a game has one screen, and " .. running.node.name .. " has it", 0)
  end
  running = self
  self:_setup()
end

-- What push was set up with, so a property that a script changes sets it up again before the next draw.
function Screen:_settings()
  return ("%s %s %s %s %s"):format(self.width, self.height, self.pixelPerfect, self.stretched, self.canvas)
end

-- Sets push up again when a script changed the settings since.
function Screen:_fresh()
  if running == self and self.applied ~= self:_settings() then
    self:_setup()
  end
end

function Screen:_setup()
  self.applied = self:_settings()
  -- push sets the window's mode itself; it is given the window's own, so the manifest's window stays as it is.
  local w, h, flags = love.window.getMode()
  push:setupScreen(self.width, self.height, w, h, {
    fullscreen = flags.fullscreen,
    resizable = flags.resizable,
    highdpi = flags.highdpi,
    pixelperfect = self.pixelPerfect,
    stretched = self.stretched,
    canvas = self.canvas,
  })
end

function Screen:disable()
  if running == self then
    running = nil
  end
end

-- LÖVE's event: the window's new size.
function Screen:resize(w, h)
  push:resize(w, h)
end

-- The engine calls it in place of drawing the group, and gives it draw, which draws the group into push's canvas.
---@param draw fun()
function Screen:drawTree(draw)
  self:_fresh()
  push:setBorderColor(self.borderColor)
  -- Without a canvas, push's start moves the drawing outside its own push, so the screen keeps the drawing around both.
  love.graphics.push()
  push:start()
  draw()
  push:finish()
  love.graphics.pop()
end

-- In the node view, the frame of the game's screen, as a camera's (DESIGN 10): the window's frame shows the
-- manifest's window, which push scales the game into.
function Screen:drawEditor(chosen)
  love.graphics.setColor(0.4, 0.9, 0.5, chosen and 1 or 0.7)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", 0, 0, self.width, self.height)
  love.graphics.print(("Screen %d × %d"):format(self.width, self.height), 4, 4)
end

function Screen:bounds()
  return 0, 0, self.width, self.height
end

-- Not called by the engine: scripts call these.

-- Whether the game draws into push's canvas, as canvas says. Without one, the drawing's
-- transform holds push's scale, so a component that reads its place from the drawing needs no toGame.
---@return boolean
function Screen:hasCanvas()
  self:_fresh()
  ---@diagnostic disable-next-line: invisible
  return push._canvas == true
end

-- The place in the game of a place in the window, such as the mouse's, or nil on the bars:
-- camera:toWorld(screen:toGame(love.mouse.getPosition())).
---@param x number
---@param y number
---@return number? x, number? y
function Screen:toGame(x, y)
  self:_fresh()
  return push:toGame(x, y)
end

-- The place in the window of a place in the game.
---@param x number
---@param y number
---@return number x, number y
function Screen:toReal(x, y)
  self:_fresh()
  return push:toReal(x, y)
end

-- push itself, for what the component does not do, such as setShader.
---@return push
function Screen:get()
  return push
end

return Screen
