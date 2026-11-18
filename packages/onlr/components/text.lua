-- The component type onlr.text: a text in a font.
local onlr = require("onlr")

---@class onlr.text : onlr.Component
local Text = {}

Text.text = onlr.property.string("")
-- Without a file, LÖVE's default font at this size.
Text.font = onlr.property.font()
Text.color = onlr.property.color({ 1, 1, 1, 1 })
-- As the limit and align of love.graphics.printf. A width of 0 wraps nothing.
Text.width = onlr.property.number(0, { min = 0, description = "Where lines wrap" })
Text.align = onlr.property.choice("left", { choices = { "left", "center", "right", "justify" } })

-- Draws the text from the node's place, and sets the colour and the font back.
function Text:draw()
  local r, g, b, a = love.graphics.getColor()
  local font = love.graphics.getFont()
  love.graphics.setColor(self.color)
  love.graphics.setFont(self.font)
  if self.width > 0 then
    love.graphics.printf(self.text, 0, 0, self.width, self.align)
  else
    love.graphics.print(self.text, 0, 0)
  end
  love.graphics.setFont(font)
  love.graphics.setColor(r, g, b, a)
end

Text.drawEditor = Text.draw

-- The rectangle of the text's lines.
function Text:bounds()
  local font = self.font
  if self.width > 0 then
    local _, lines = font:getWrap(self.text, self.width)
    return 0, 0, self.width, math.max(1, #lines) * font:getHeight() * font:getLineHeight()
  end
  local _, breaks = self.text:gsub("\n", "\n")
  return 0, 0, font:getWidth(self.text), (breaks + 1) * font:getHeight() * font:getLineHeight()
end

return Text
