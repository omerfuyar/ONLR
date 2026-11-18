-- The component type suit.button: a button of SUIT's at its node, its top left corner at the node's place. A click
-- tells its node clicked().
local onlr = require("onlr")
local widget = require("suit.widget")

---@class suit.button : suit.widget
local Button = {}

Button.text = onlr.property.string("Button")
Button.font = onlr.property.font({ size = 12 })
Button.align = onlr.property.choice("center", { choices = { "left", "center", "right" } })
Button.valign = onlr.property.choice("middle", { choices = { "top", "middle", "bottom" } })
widget.declare(Button, true)

function Button:_ask(core, opt)
  return core:Button(self.text, opt, 0, 0, widget.size(self.width), widget.size(self.height))
end

function Button:_answer(result)
  if result.hit then
    self.node:send("clicked")
  end
end

function Button:_draw(...)
  widget.core.theme.Button(...)
end

return Button
