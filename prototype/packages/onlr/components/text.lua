-- The component type onlr.text: a text in a font. In this prototype, only its properties.
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

function Text:draw() end
Text.drawEditor = Text.draw
function Text:bounds() end

return Text
