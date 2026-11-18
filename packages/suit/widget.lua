-- What suit's widgets share. SUIT is immediate: a game asks for each widget every frame, and SUIT answers whether it
-- was clicked. Each widget component asks SUIT for itself in its update, with the pointer in its node's own space, and
-- draws what SUIT would have drawn in its draw, at its node, so a node's place, a camera and a push.screen hold for it.
local onlr = require("onlr")
local suit = require("suit")

local widget = {}

-- The game's one SUIT. Its theme is the library's, so suit.theme changes it.
local core = suit.new(suit.theme)
widget.core = core

-- SUIT's frame ends once a frame, after every widget asked: it reads the mouse's button and forgets the keys.
local ended = true
-- The game's push.screen, which turns the window's pointer into the game's, found when the frame ends.
local screen

---@class suit.widget : onlr.Component
---@field font love.Font?
---@field align string?
---@field valign string?
---@field width number
---@field height number
---@field drawn table? what SUIT would draw: the theme's arguments
---@field space number[]? the node's space, from the drawing's, as it was last drawn: ox, oy, xx, xy, yx, yy
---@field result table? what SUIT answered this frame
---@field _ask fun(self: suit.widget, core: suit.Core, opt: table): table asks SUIT for the widget
---@field _answer fun(self: suit.widget, result: table) acts on what SUIT answered
---@field _draw fun(self: suit.widget, ...) draws what SUIT would have drawn
local Widget = {}

-- Asks SUIT for the widget on a SUIT, with the pointer at x, y in the node's space, and keeps what it would draw.
---@param self suit.widget
local function ask(self, on, x, y, down)
  on:updateMouse(x, y, down)
  local drawn
  local opt = { id = self, font = self.font, align = self.align ~= "" and self.align or nil, valign = self.valign }
  opt.draw = function(...)
    drawn = { n = select("#", ...), ... }
  end
  local result = self:_ask(on, opt)
  -- SUIT keeps what to draw for its own draw; the widget draws itself, so it takes it from SUIT's queue.
  for i = 1, on.draw_queue.n do
    on.draw_queue[i]()
  end
  on.draw_queue.n = 0
  self.drawn = drawn
  return result
end

-- The pointer in the drawing's space that the node draws into: the window's, or the game's under a push.screen.
local function pointer(self)
  local x, y = love.mouse.getPosition()
  if screen and screen.node and not screen.node:isDestroyed() and screen:isEnabled() then
    local n = self.node
    while n do
      if n == screen.node then
        -- without push's canvas, the drawing's scale is in the node's space already
        if screen:hasCanvas() then
          return screen:toGame(x, y)
        end
        return x, y
      end
      n = n:getParent()
    end
  end
  return x, y
end

function Widget:update()
  ended = false
  local x, y = math.huge, math.huge
  local s = self.space
  local px, py = pointer(self)
  if s and px and py then
    x, y = s[1] + s[3] * px + s[5] * py, s[2] + s[4] * px + s[6] * py
  end
  self.result = ask(self, core, x, y)
  self:_answer(self.result)
end

function Widget:lateUpdate()
  if not ended then
    ended = true
    core:enterFrame()
    screen = onlr.tree.findComponent("push.screen")
  end
end

-- LÖVE's events: the keys that a text field and a slider take.
function Widget:keypressed(key)
  core:keypressed(key)
end

function Widget:textinput(text)
  core:textinput(text)
end

function Widget:textedited(text, start, length)
  core:textedited(text, start, length)
end

-- Draws what SUIT drew for the widget. A widget with a font draws at the size that the drawing shows it (onlr.font): the
-- drawing is scaled back by the font's scale, and the theme gets the sharp font and its place and size in that scale.
local function show(self, d)
  local opt = d[2]
  if type(opt) ~= "table" or not opt.font or d.n < 6 then
    return self:_draw(unpack(d, 1, d.n))
  end
  love.graphics.push()
  local sharp, scale = onlr.font.apply(opt.font)
  local args = { unpack(d, 1, d.n) }
  local o = {}
  for k, v in pairs(opt) do
    o[k] = v
  end
  o.font, o.cornerRadius = sharp, (opt.cornerRadius or suit.theme.cornerRadius) / scale
  args[2] = o
  for i = 3, 6 do
    args[i] = args[i] / scale
  end
  local ok, err = pcall(self._draw, self, unpack(args, 1, d.n))
  love.graphics.pop()
  if not ok then
    error(err, 0)
  end
end

-- Draws what SUIT would have drawn, and keeps the node's space, from which the pointer is read in the next update.
function Widget:draw()
  local ox, oy = love.graphics.inverseTransformPoint(0, 0)
  local xx, xy = love.graphics.inverseTransformPoint(1, 0)
  local yx, yy = love.graphics.inverseTransformPoint(0, 1)
  self.space = { ox, oy, xx - ox, xy - oy, yx - ox, yy - oy }
  local d = self.drawn
  if d then
    love.graphics.push("all")
    show(self, d)
    love.graphics.pop()
  end
end

-- The node view draws the widget as it is with no pointer over it, by a SUIT of its own.
local still = suit.new(suit.theme)

function Widget:drawEditor()
  ask(self, still, math.huge, math.huge, false)
  local d = self.drawn
  if d then
    show(self, d)
  end
end

-- The widget's rectangle, from what SUIT would draw: its x, y, width and height follow the theme's first argument.
function Widget:bounds()
  if not self.drawn then
    ask(self, still, math.huge, math.huge, false)
  end
  local d = self.drawn
  if d then
    return self:_rectangle(unpack(d, 1, d.n))
  end
end

function Widget:_rectangle(_, _, x, y, w, h)
  return x, y, w, h
end

-- Not called by the engine: scripts call these.

-- "normal", "hovered", "active" while the pointer holds it, or "hit" in the frame it was clicked.
---@return "normal"|"hovered"|"active"|"hit"
function Widget:getState()
  local r = self.result
  if not r then
    return "normal"
  elseif r.hit then
    return "hit"
  elseif core:isActive(self) then
    return "active"
  end
  return r.hovered and "hovered" or "normal"
end

-- Whether the pointer is over it.
---@return boolean
function Widget:isHovered()
  return self.result ~= nil and self.result.hovered
end

-- The game's SUIT, for what the widgets do not do, such as a widget of a script's own.
---@return suit.Core
function Widget:get()
  return core
end

-- Gives a type the properties that every widget has and the functions; the type's own come after them.
---@param Type table
---@param size boolean whether it takes a width and a height
function widget.declare(Type, size)
  if size then
    Type.width = onlr.property.number(0, { min = 0, description = "In pixels. 0 fits the text" })
    Type.height = onlr.property.number(0, { min = 0, description = "In pixels. 0 fits the text" })
  end
  for key, value in pairs(Widget) do
    if Type[key] == nil then
      Type[key] = value
    end
  end
end

-- A size, or nil to let SUIT fit it.
function widget.size(n)
  return n > 0 and n or nil
end

return widget
