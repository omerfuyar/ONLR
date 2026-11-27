-- The component type onlr.shader: draws its node and all under it through shaders, in passes (DESIGN 6.7, 10). It is a
-- group (5). The first pass follows covers: with draws, each draw of its nodes goes through its shader; with picture, its
-- nodes draw into one picture, which its shader shades. Each later pass shades the picture that the pass before it gave.
local onlr = require("onlr")
local shaders = require("onlr.library.shader")

---A pass of onlr.shader: a shader and its values.
---@class onlr.ShaderPass
---@field shader love.Shader?
---@field values table<string, any>

---@class onlr.shader : onlr.Component
---@field passes onlr.ShaderPass[]
local Shader = {}

Shader.covers = onlr.property.choice("draws", {
  choices = { "draws", "picture" },
  description = "How the first pass shades. draws: each draw of the nodes goes through its shader, as a hit's flash needs. picture: the nodes draw into one picture, which its shader shades, as a blur over a level needs. Each later pass shades the picture",
})
-- Each pass's values by their names, as { amount = 0.5 }; a script sets one as shader.passes[1].values.amount = 1.
Shader.passes = onlr.property.list(onlr.property.group({
  shader = onlr.property.shader({ description = "A GLSL file, in LÖVE's own form" }),
  values = onlr.property.values({ description = "The shader's values" }),
}), { description = "The shaders, in the order that they shade" })

-- The pictures that the passes draw into, kept while the size of what they draw into stays.
---@type love.Canvas[]
Shader._canvases = nil

-- Draws with a shader, and sets back the shader that was set before.
local function through(s, draw)
  local before = love.graphics.getShader()
  love.graphics.setShader(s)
  draw()
  love.graphics.setShader(before)
end

-- The picture of that number, of the size of what the drawing goes into, the window or push's canvas, at its pixel density.
function Shader:_canvas(index)
  local target = love.graphics.getCanvas()
  local w, h, dpi
  if target then
    w, h, dpi = target:getWidth(), target:getHeight(), target:getDPIScale()
  else
    w, h, dpi = love.graphics.getWidth(), love.graphics.getHeight(), love.graphics.getDPIScale()
  end
  self._canvases = self._canvases or {}
  local canvas = self._canvases[index]
  if not canvas or canvas:getWidth() ~= w or canvas:getHeight() ~= h or canvas:getDPIScale() ~= dpi then
    canvas = love.graphics.newCanvas(w, h, { dpiscale = dpi })
    self._canvases[index] = canvas
  end
  return canvas
end

-- Draws into a picture, cleared to transparent, with the drawing's place and none of its canvas.
local function into(canvas, draw)
  love.graphics.push("all")
  love.graphics.setCanvas({ canvas, stencil = true })
  love.graphics.clear(0, 0, 0, 0)
  draw()
  love.graphics.pop()
end

-- Draws a picture through a shader, with no place, as moonshine.chain does (DESIGN 11.11).
local function shade(canvas, s)
  love.graphics.push("all")
  love.graphics.origin()
  love.graphics.setShader(s)
  love.graphics.setColor(1, 1, 1, 1)
  -- LÖVE's own blending, as moonshine's: a shader that gives a colour to a transparent pixel, as a tint does, leaves it
  -- transparent. The picture holds colours multiplied by their alpha, so a half-transparent edge darkens a little (DESIGN 10)
  love.graphics.setBlendMode("alpha", "alphamultiply")
  love.graphics.draw(canvas, 0, 0)
  love.graphics.pop()
end

-- The engine calls it in place of drawing the group, and gives it draw, which draws the group. The passes without a shader
-- are passed over; without any, the group draws as it would without the component.
---@param draw fun()
function Shader:drawTree(draw)
  local passes = {}
  for _, pass in ipairs(self.passes or {}) do
    if pass.shader then
      passes[#passes + 1] = pass
    end
  end
  if #passes == 0 then
    draw()
    return
  end
  local first = passes[1]
  -- components that name one file share its shader, so each pass sends its values before it draws
  shaders.send(first.shader, first.values)
  if #passes == 1 and self.covers ~= "picture" then
    through(first.shader, draw)
    return
  end
  -- the nodes go into the first picture: with draws through the first shader, which then is done
  local canvas = self:_canvas(1)
  local rest = 1
  if self.covers == "picture" then
    into(canvas, draw)
  else
    into(canvas, function()
      through(first.shader, draw)
    end)
    rest = 2
  end
  -- each pass but the last shades the picture into the other one; the last shades it into what the drawing goes into
  for i = rest, #passes do
    local pass = passes[i]
    if i > 1 then
      shaders.send(pass.shader, pass.values)
    end
    if i == #passes then
      shade(canvas, pass.shader)
    else
      local other = self:_canvas(canvas == self._canvases[1] and 2 or 1)
      into(other, function()
        shade(canvas, pass.shader)
      end)
      canvas = other
    end
  end
end

-- The node view's time of this component: 0, and moving while its node is chosen, so a shader that moves with time plays
-- there as an animation does (DESIGN 6.5, 10).
Shader._editorTime = 0

---@param dt number
function Shader:updateEditor(dt)
  self._editorTime = self._editorTime + dt
end

-- In the node view, the passes draw as in the game, with the component's own time in place of the game's.
---@param draw fun()
function Shader:drawTreeEditor(draw)
  for _, pass in ipairs(self.passes or {}) do
    if pass.shader and shaders.has(pass.shader, "time") then
      pass.shader:send("time", self._editorTime)
    end
  end
  self:drawTree(draw)
end

return Shader
