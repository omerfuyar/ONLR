-- The component type suit.slider: a bar that the pointer drags, from min to max, as a volume's. A change tells its
-- node changed(value). While the pointer holds it, the arrow keys move it by step.
local onlr = require("onlr")
local widget = require("suit.widget")

---@class suit.slider : suit.widget
---@field private info {value: number, min: number, max: number, step: number}?
local Slider = {}

Slider.value = onlr.property.number(0.5, { description = "Its value. A script may set it" })
Slider.min = onlr.property.number(0)
Slider.max = onlr.property.number(1)
Slider.step = onlr.property.number(0.1, { min = 0, description = "How far an arrow key moves it" })
Slider.vertical = onlr.property.bool(false, { description = "It goes up, not right" })
Slider.width = onlr.property.number(100, { min = 1 })
Slider.height = onlr.property.number(16, { min = 1 })
widget.declare(Slider, false)

function Slider:_ask(core, opt)
  if self.max <= self.min then
    error(("suit.slider on %s: max is not more than min"):format(self.node.name), 0)
  end
  self.info = self.info or {}
  local info = self.info
  info.value = math.max(self.min, math.min(self.max, self.value))
  info.min, info.max, info.step = self.min, self.max, self.step
  opt.vertical = self.vertical
  return core:Slider(info, opt, 0, 0, self.width, self.height)
end

function Slider:_answer(result)
  if result.changed then
    self.value = self.info.value
    self.node:send("changed", self.value)
  end
end

function Slider:_draw(...)
  widget.core.theme.Slider(...)
end

return Slider
