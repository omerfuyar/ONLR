-- The component type onlr.sprite: an image, or a part of one. Written as a script is.
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
Sprite.origin = onlr.property.vector(0, 0, { description = "The point of the image, in its pixels, that is at the node's place" })
Sprite.color = onlr.property.color({ 1, 1, 1, 1 })

-- The LÖVE quad of each sprite that draws a part, kept outside the component, whose fields are its properties.
local quads = setmetatable({}, { __mode = "k" })

-- Draws the image at the node, as love.graphics.draw, and sets the colour back.
function Sprite:draw()
  local image = self.image
  if not image then
    return
  end
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(self.color)
  local q = self.quad
  if q.width > 0 and q.height > 0 then
    local quad = quads[self]
    local w, h = image:getDimensions()
    if quad then
      quad:setViewport(q.x, q.y, q.width, q.height, w, h)
    else
      quad = love.graphics.newQuad(q.x, q.y, q.width, q.height, w, h)
      quads[self] = quad
    end
    love.graphics.draw(image, quad, -self.origin.x, -self.origin.y)
  else
    love.graphics.draw(image, -self.origin.x, -self.origin.y)
  end
  love.graphics.setColor(r, g, b, a)
end

-- It looks the same in the node view as in the game.
Sprite.drawEditor = Sprite.draw

-- The image's rectangle, or the quad's, from the origin.
function Sprite:bounds()
  local image = self.image
  if not image then
    return
  end
  local w, h = image:getDimensions()
  local q = self.quad
  if q.width > 0 and q.height > 0 then
    w, h = q.width, q.height
  end
  return -self.origin.x, -self.origin.y, w, h
end

return Sprite
