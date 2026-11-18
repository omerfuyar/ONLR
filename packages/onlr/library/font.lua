-- onlr.font: fonts as large as the drawing shows them (DESIGN 10). LÖVE makes a font's letters at the font's size, and
-- a scale stretches those pixels, so a text on a scaled node, under a zoomed camera or in a zoomed node view is blurred.
-- A component that draws text asks for the font at the size that the drawing's scale gives, and draws it at 1 / scale.
local data = require("onlr.library.data")

---@class onlr.font
local font = {}

-- The largest size of a font made for a scale, so a huge zoom makes no huge texture.
local LARGEST = 512

-- How much the drawing's transform scales, the larger of its two axes, and whether it turns or skews.
local function scaleOf()
  local ox, oy = love.graphics.transformPoint(0, 0)
  local ax, ay = love.graphics.transformPoint(1, 0)
  local bx, by = love.graphics.transformPoint(0, 1)
  ax, ay, bx, by = ax - ox, ay - oy, bx - ox, by - oy
  local sx, sy = math.sqrt(ax * ax + ay * ay), math.sqrt(bx * bx + by * by)
  local straight = math.abs(ay) < 1e-6 and math.abs(bx) < 1e-6 and ax > 0 and by > 0
  return math.max(sx, sy), straight and math.abs(sx - sy) < 1e-6, ox, oy
end

---The font as large as the drawing shows it, and the scale to draw it at, which undoes the drawing's.
---A font that the engine did not load, such as one that a script made with love.graphics.newFont, is given as it is.
---@param f love.Font
---@return love.Font font
---@return number scale what love.graphics.scale is given before the text draws: 1 / the drawing's scale
function font.sharp(f)
  local from = data.paths[f]
  local scale = scaleOf()
  if type(from) ~= "table" or scale <= 0 or math.abs(scale - 1) < 1e-3 then
    return f, 1
  end
  local size = math.max(1, math.min(LARGEST, math.floor(from.size * scale + 0.5)))
  if size == from.size then
    return f, 1
  end
  local sharp = data.load("font", from.path, size)
  return sharp, from.size / size
end

---Draws with a sharp font: sets the scale that font.sharp gave, and, when the drawing neither turns nor stretches,
---moves its origin to a whole pixel of the screen, so the letters fall on the screen's pixels. Call it inside
---love.graphics.push and pop.
---@param f love.Font
---@return love.Font font the font to draw with
---@return number scale the font's size over the drawn one: a width in the node's space is divided by it
function font.apply(f)
  local sharp, scale = font.sharp(f)
  local s, straight, ox, oy = scaleOf()
  if scale ~= 1 then
    love.graphics.scale(scale)
  end
  if straight then
    local local1 = s * scale
    love.graphics.translate((math.floor(ox + 0.5) - ox) / local1, (math.floor(oy + 0.5) - oy) / local1)
  end
  return sharp, scale
end

return font
