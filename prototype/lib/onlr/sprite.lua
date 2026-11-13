-- The component type onlr.sprite: an image, or a part of one. Written as a script is.
-- In this prototype, only its properties: its functions are named, without code.
local onlr = require("onlr")

---@class onlr.sprite : onlr.Component
local Sprite = {}

Sprite.image = onlr.property.image()
-- A LÖVE quad: the part of the image to draw. A width or a height of 0 draws the whole image.
Sprite.quad = onlr.property.group({
  x = onlr.property.number(0),
  y = onlr.property.number(0),
  width = onlr.property.number(0, { min = 0 }),
  height = onlr.property.number(0, { min = 0 }),
})
Sprite.origin = onlr.property.vector(0, 0, { description = "The point of the image that is at the node's place" })
Sprite.color = onlr.property.color({ 1, 1, 1, 1 })

-- Draws the image at the node, as love.graphics.draw, and sets the colour back.
function Sprite:draw() end

-- It looks the same in the node view as in the game.
Sprite.drawEditor = Sprite.draw

-- The image's rectangle, or the quad's, from the origin.
function Sprite:bounds() end

return Sprite
