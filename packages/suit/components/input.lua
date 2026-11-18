-- The component type suit.input: a field that the keyboard types into, after a click on it. Each change tells its
-- node changed(text), and Enter submitted(text).
local onlr = require("onlr")
local widget = require("suit.widget")

---@class suit.input : suit.widget
---@field private field table? SUIT's own: the text, the cursor and how far the text is moved
local Input = {}

Input.text = onlr.property.string("", { description = "The text in it. A script may set it" })
Input.font = onlr.property.font({ size = 12 })
Input.width = onlr.property.number(100, { min = 1 })
Input.height = onlr.property.number(0, { min = 0, description = "In pixels. 0 fits the font" })
widget.declare(Input, false)

function Input:_ask(core, opt)
  local field = self.field or {}
  self.field = field
  if field.text ~= self.text then
    field.text, field.cursor = self.text, nil
  end
  return core:Input(field, opt, 0, 0, self.width, widget.size(self.height))
end

function Input:_answer(result)
  if self.field.text ~= self.text then
    self.text = self.field.text
    self.node:send("changed", self.text)
  end
  if result.submitted then
    self.node:send("submitted", self.text)
  end
end

-- The theme cuts the text to the field with a scissor, which LÖVE takes in the drawing's pixels and not in the node's
-- space. So while it draws, a scissor is turned into the rectangle that the node's space puts it in.
local setScissor = love.graphics.setScissor
local function scissor(x, y, w, h)
  if not x then
    return setScissor()
  end
  local ax, ay = love.graphics.transformPoint(x, y)
  local bx, by = love.graphics.transformPoint(x + w, y + h)
  setScissor(math.min(ax, bx), math.min(ay, by), math.abs(bx - ax), math.abs(by - ay))
end

function Input:_draw(...)
  love.graphics.setScissor = scissor
  local ok, err = pcall(widget.core.theme.Input, ...)
  love.graphics.setScissor = setScissor
  if not ok then
    error(err, 0)
  end
end

-- Gives it the keyboard, as a click on it does. It is not named focus, which is LÖVE's event of the window's focus.
function Input:grabFocus()
  self.field = self.field or { text = self.text }
  self.field.forcefocus = true
end

-- Whether the keyboard types into it.
---@return boolean
function Input:hasFocus()
  return widget.core:hasKeyboardFocus(self)
end

return Input
