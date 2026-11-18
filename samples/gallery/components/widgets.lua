-- The interface room's script: the widgets tell it of their changes, and it shows them on a shape and a text.
local onlr = require("onlr")

---@class widgets : onlr.Component
local Widgets = {}

Widgets.shape = onlr.property.component("onlr.shape")
Widgets.text = onlr.property.component("onlr.text")

-- Not resize, which is LÖVE's event of the window. A slider's change sizes the shape; a checkbox's shows or hides it; a field's text is shown.
function Widgets:grow(value)
  if self.shape then
    self.shape.radius = value
  end
end

function Widgets:show(checked)
  if self.shape then
    self.shape:setEnabled(checked)
  end
end

function Widgets:say(text)
  if self.text then
    self.text.text = text or ""
  end
end

return Widgets
