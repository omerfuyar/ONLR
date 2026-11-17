-- The component type onlr.camera: a view (DESIGN 10).
-- It draws its node and all under it as a group, moved, turned and zoomed so that the middle of its screen,
-- the window by default, shows its point. What is outside its node, such as a score, it does not move.
local onlr = require("onlr")

---@class onlr.camera : onlr.Component
local Camera = {}

-- Its own place, not its node's: the node's place moves the world under it.
-- A script follows the player by setting these in lateUpdate.
Camera.posX = onlr.property.number(0, { description = "The point, in its node's space, that the middle of its screen shows" })
Camera.posY = onlr.property.number(0)
Camera.rot = onlr.property.number(0, { description = "Its angle, clockwise" })
Camera.zoom = onlr.property.number(1, { min = 0.01, description = "2 shows its nodes twice as large" })
-- The size of its screen. 0 is the window's; a game that a library scales names its own size, such as 320 by 180.
Camera.width = onlr.property.number(0, { min = 0 })
Camera.height = onlr.property.number(0, { min = 0 })

-- The size of the camera's screen.
local function screen(self)
  local w, h = self.width, self.height
  if w <= 0 then
    w = love.graphics.getWidth()
  end
  if h <= 0 then
    h = love.graphics.getHeight()
  end
  return w, h
end

-- Turns a point of the camera's screen into the point of the world that the camera shows there,
-- in the space of node:toWorld. So a click finds its place: camera:toWorld(love.mouse.getPosition()).
---@param x number
---@param y number
---@return number x, number y
function Camera:toWorld(x, y)
  local w, h = screen(self)
  local dx, dy = (x - w / 2) / self.zoom, (y - h / 2) / self.zoom
  local cos, sin = math.cos(self.rot), math.sin(self.rot)
  return self.node:toWorld(self.posX + cos * dx - sin * dy, self.posY + sin * dx + cos * dy)
end

-- Turns a point of the world into the point of its screen where the camera shows it.
---@param x number
---@param y number
---@return number x, number y
function Camera:toScreen(x, y)
  local w, h = screen(self)
  local lx, ly = self.node:toLocal(x, y)
  local dx, dy = lx - self.posX, ly - self.posY
  local cos, sin = math.cos(self.rot), math.sin(self.rot)
  return w / 2 + (cos * dx + sin * dy) * self.zoom, h / 2 + (-sin * dx + cos * dy) * self.zoom
end

local view

-- The engine calls it in place of drawing the group, and gives it draw, which draws the group.
-- The nodes draw at their places in the world, so the view first takes the camera's node's place off.
-- In the node view it is not called, so the camera does not move the view.
---@param draw fun()
function Camera:drawTree(draw)
  local w, h = screen(self)
  local a, b, c, d, tx, ty = self.node:_world()
  local det = a * d - b * c
  view = view or love.math.newTransform()
  view:setMatrix(d / det, -c / det, 0, (c * ty - d * tx) / det, -b / det, a / det, 0, (b * tx - a * ty) / det, 0, 0, 1, 0, 0, 0, 0, 1)
  love.graphics.push()
  love.graphics.translate(w / 2, h / 2)
  love.graphics.rotate(-self.rot)
  love.graphics.scale(self.zoom)
  love.graphics.translate(-self.posX, -self.posY)
  love.graphics.applyTransform(view)
  draw()
  love.graphics.pop()
end

-- The rectangle around what the camera shows, in its node's space.
function Camera:bounds()
  local w, h = screen(self)
  w, h = w / self.zoom, h / self.zoom
  local cos, sin = math.abs(math.cos(self.rot)), math.abs(math.sin(self.rot))
  local bw, bh = w * cos + h * sin, w * sin + h * cos
  return self.posX - bw / 2, self.posY - bh / 2, bw, bh
end

-- In the node view, the frame of what it shows.
-- It is blue and 3 pixels wide, named "Camera" inside its top left, so it is told from the window's frame, which the node view
-- draws grey and thin, and names above it; the two are often the same rectangle.
function Camera:drawEditor(chosen)
  local w, h = screen(self)
  w, h = w / self.zoom, h / self.zoom
  love.graphics.translate(self.posX, self.posY)
  love.graphics.rotate(self.rot)
  -- the line and the name keep their sizes on the screen at any zoom of the view
  local x0, y0 = love.graphics.transformPoint(0, 0)
  local x1, y1 = love.graphics.transformPoint(1, 0)
  local scale = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
  if scale <= 0 then
    return
  end
  love.graphics.setColor(0.38, 0.69, 0.94, chosen and 1 or 0.7)
  love.graphics.setLineWidth(3 / scale)
  love.graphics.rectangle("line", -w / 2, -h / 2, w, h)
  love.graphics.setLineWidth(1)
  love.graphics.print("Camera", -w / 2 + 6 / scale, -h / 2 + 4 / scale, 0, 1 / scale)
end

return Camera
