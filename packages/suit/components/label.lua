-- The component type suit.label: a text of SUIT's at its node, in the theme's colour. A click tells its node clicked().
local onlr = require("onlr")
local widget = require("suit.widget")

---@class suit.label : suit.widget
local Label = {}

Label.text = onlr.property.string("Label")
Label.font = onlr.property.font({ size = 12 })
Label.align = onlr.property.choice("left", { choices = { "left", "center", "right" } })
Label.valign = onlr.property.choice("middle", { choices = { "top", "middle", "bottom" } })
widget.declare(Label, true)

function Label:_ask(core, opt)
  return core:Label(self.text, opt, 0, 0, widget.size(self.width), widget.size(self.height))
end

function Label:_answer(result)
  if result.hit then
    self.node:send("clicked")
  end
end

function Label:_draw(...)
  widget.core.theme.Label(...)
end

return Label
