-- The component type onlr.camera.limits: keeps what its node's camera shows inside a rectangle, such as a level's
-- edges, so the camera never shows what is past them. A view larger than the rectangle is centred on it.
local onlr = require("onlr")

---@class onlr.camera.limits : onlr.Component
local Limits = {}

Limits.needs = { "onlr.camera.view" }

Limits.x = onlr.property.number(0, { description = "The rectangle's left edge, in the camera's node's space" })
Limits.y = onlr.property.number(0, { description = "Its top edge" })
Limits.width = onlr.property.number(640, { min = 0 })
Limits.height = onlr.property.number(360, { min = 0 })

-- One axis: the point between lo + half and hi - half, or the middle when the view is larger.
local function keep(v, lo, size, half)
  if size < half * 2 then
    return lo + size / 2
  end
  return math.max(lo + half, math.min(lo + size - half, v))
end

-- Not called by the engine: scripts call it, and onlr.camera.follow after it moves the camera.
-- Moves the camera's point so that all that it shows, at its zoom and its angle, is inside the rectangle.
function Limits:clamp()
  local camera = self.node.components.onlr.camera.view --[[@as onlr.camera.view]]
  local w, h = camera:getSize()
  w, h = w / camera.zoom, h / camera.zoom
  local cos, sin = math.abs(math.cos(camera.rot)), math.abs(math.sin(camera.rot))
  local hw, hh = (w * cos + h * sin) / 2, (w * sin + h * cos) / 2
  camera.posX = keep(camera.posX, self.x, self.width, hw)
  camera.posY = keep(camera.posY, self.y, self.height, hh)
end

function Limits:enable()
  self:clamp()
end

-- After the scripts set the camera in their lateUpdate, as they may.
function Limits:lateUpdate()
  self:clamp()
end

-- In the node view, the rectangle, orange.
function Limits:drawEditor(chosen)
  love.graphics.setColor(1, 0.6, 0.2, chosen and 1 or 0.6)
  love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

function Limits:bounds()
  return self.x, self.y, self.width, self.height
end

return Limits
