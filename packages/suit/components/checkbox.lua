-- The component type suit.checkbox: a box that a click checks and unchecks, with a text beside it. A click tells
-- its node changed(checked).
local onlr = require("onlr")
local widget = require("suit.widget")

---@class suit.checkbox : suit.widget
---@field private box {checked: boolean, text: string}?
local Checkbox = {}

Checkbox.text = onlr.property.string("Checkbox")
Checkbox.checked = onlr.property.bool(false, { description = "Whether it is checked. A script may set it" })
Checkbox.font = onlr.property.font({ size = 12 })
Checkbox.align = onlr.property.choice("left", { choices = { "left", "center", "right" } })
Checkbox.valign = onlr.property.choice("middle", { choices = { "top", "middle", "bottom" } })
widget.declare(Checkbox, true)

function Checkbox:_ask(core, opt)
  self.box = self.box or {}
  self.box.checked, self.box.text = self.checked, self.text
  return core:Checkbox(self.box, opt, 0, 0, widget.size(self.width), widget.size(self.height))
end

function Checkbox:_answer(result)
  if result.hit then
    self.checked = self.box.checked
    self.node:send("changed", self.checked)
  end
end

function Checkbox:_draw(...)
  widget.core.theme.Checkbox(...)
end

return Checkbox
