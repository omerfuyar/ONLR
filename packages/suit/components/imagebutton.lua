-- The component type suit.imagebutton: a button that is an image, with other images while the pointer is over it and
-- while it holds it. A click tells its node clicked().
local onlr = require("onlr")
local widget = require("suit.widget")

---@class suit.imagebutton : suit.widget
local ImageButton = {}

ImageButton.image = onlr.property.image({ description = "The image. The button is its size" })
ImageButton.hovered = onlr.property.image({ description = "The image while the pointer is over it. The image when left out" })
ImageButton.active = onlr.property.image({ description = "The image while the pointer holds it. The hovered one when left out" })
ImageButton.color = onlr.property.color({ 1, 1, 1, 1 }, { description = "What the image is multiplied by" })
widget.declare(ImageButton, false)

function ImageButton:_ask(core, opt)
  if not self.image then
    return {}
  end
  opt.hovered, opt.active = self.hovered, self.active
  return core:ImageButton(self.image, opt, 0, 0)
end

function ImageButton:_answer(result)
  if result.hit then
    self.node:send("clicked")
  end
end

-- SUIT gives the image, its place, and the colour that was set.
function ImageButton:_draw(image, x, y)
  love.graphics.setColor(self.color)
  love.graphics.draw(image, x, y)
end

function ImageButton:_rectangle(image, x, y)
  return x, y, image:getWidth(), image:getHeight()
end

return ImageButton
