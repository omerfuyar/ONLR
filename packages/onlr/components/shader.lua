-- The component type onlr.shader: draws its node and all under it through a shader (DESIGN 6.7, 10). It is a group (5).
-- With draws, each draw of its nodes goes through the shader; with picture, its nodes draw into one picture, which then draws
-- through the shader.
local onlr = require("onlr")
local shaders = require("onlr.library.shader")

---@class onlr.shader : onlr.Component
local Shader = {}

Shader.shader = onlr.property.shader({ description = "A GLSL file, in LÖVE's own form" })
Shader.covers = onlr.property.choice("draws", {
  choices = { "draws", "picture" },
  description = "draws: each draw of the nodes goes through the shader, as a hit's flash needs. picture: the nodes draw into one picture, which draws through the shader, as a blur over a level needs",
})
-- The shader's values by their names, as { amount = 0.5 }; a script sets one as shader.values.amount = 1.
Shader.values = onlr.property.values({ description = "The shader's values" })

-- The picture's canvas, kept while the size of what it draws into stays.
---@type love.Canvas?
Shader._canvas = nil

-- With draws: sets the shader, draws the nodes, and sets back the shader that was set before.
local function throughEach(s, draw)
  local before = love.graphics.getShader()
  love.graphics.setShader(s)
  draw()
  love.graphics.setShader(before)
end

-- With picture: draws the nodes into a canvas of the size of what it draws into, the window or push's canvas, at its pixel
-- density, with the drawing's place; then draws the canvas through the shader with none, as moonshine.chain does (DESIGN 11.11).
function Shader:_throughPicture(s, draw)
  local target = love.graphics.getCanvas()
  local w, h, dpi
  if target then
    w, h, dpi = target:getWidth(), target:getHeight(), target:getDPIScale()
  else
    w, h, dpi = love.graphics.getWidth(), love.graphics.getHeight(), love.graphics.getDPIScale()
  end
  local canvas = self._canvas
  if not canvas or canvas:getWidth() ~= w or canvas:getHeight() ~= h or canvas:getDPIScale() ~= dpi then
    canvas = love.graphics.newCanvas(w, h, { dpiscale = dpi })
    self._canvas = canvas
  end
  love.graphics.push("all")
  love.graphics.setCanvas({ canvas, stencil = true })
  love.graphics.clear(0, 0, 0, 0)
  draw()
  love.graphics.pop()
  love.graphics.push("all")
  love.graphics.origin()
  love.graphics.setShader(s)
  love.graphics.setColor(1, 1, 1, 1)
  -- the canvas holds colours multiplied by their alpha
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(canvas, 0, 0)
  love.graphics.pop()
end

-- The engine calls it in place of drawing the group, and gives it draw, which draws the group. Without a shader, the group
-- draws as it would without the component.
---@param draw fun()
function Shader:drawTree(draw)
  local s = self.shader
  if not s then
    draw()
    return
  end
  -- components that name one file share its shader, so each sends its values before it draws
  shaders.send(s, self.values)
  if self.covers == "picture" then
    self:_throughPicture(s, draw)
  else
    throughEach(s, draw)
  end
end

return Shader
