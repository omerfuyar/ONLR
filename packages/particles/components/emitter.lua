-- The component type particles.emitter: one of LÖVE's particle systems, at its node.
-- Its properties are the system's settings, named as LÖVE's setters name them: emissionRate is setEmissionRate.
-- It makes the system, updates it each frame and draws it, which a game does by hand with love.graphics.newParticleSystem.
local onlr = require("onlr")

---@class particles.emitter : onlr.Component
---@field private system love.ParticleSystem?
---@field private ended boolean? its node was told particlesEnd, and is not told again until it emits again
---@field private shown love.ParticleSystem? the node view's picture
---@field private undo love.Transform? the inverse of its node's place, kept to draw a world system
local Emitter = {}

-- A range, as LÖVE's setters take two numbers: each particle gets a value between min and max.
local function range(min, max, options)
  return onlr.property.group({ min = onlr.property.number(min), max = onlr.property.number(max) }, options)
end

Emitter.image = onlr.property.image({ description = "The picture of each particle. Without one, a small white circle" })
Emitter.space = onlr.property.choice("world", {
  choices = { "world", "local" },
  description = "world: a particle stays where it was emitted, as smoke does. local: the particles move, turn and scale with the node",
})
Emitter.autoPlay = onlr.property.bool(true, { description = "It emits from its start. Without, a script calls play or emit" })
Emitter.bufferSize = onlr.property.integer(256, { min = 1, description = "The most particles that live at once" })
Emitter.insertMode = onlr.property.choice("top", { choices = { "top", "bottom", "random" }, description = "Where a new particle is drawn: over the others, under them, or among them" })

Emitter.emissionRate = onlr.property.number(20, { min = 0, description = "Particles a second", heading = "Emission" })
Emitter.emitterLifetime = onlr.property.number(-1, { description = "The seconds that it emits, after start. -1 emits until stop" })
Emitter.particleLifetime = range(1, 1, { description = "The seconds that each particle lives" })
Emitter.emissionArea = onlr.property.group({
  distribution = onlr.property.choice("none", { choices = { "none", "uniform", "normal", "ellipse", "borderellipse", "borderrectangle" } }),
  dx = onlr.property.number(0, { min = 0 }),
  dy = onlr.property.number(0, { min = 0 }),
  angle = onlr.property.number(0),
  directionRelativeToCenter = onlr.property.bool(false),
}, { description = "Where particles start around the node: none is at its place; dx and dy are the area's half width and half height" })

Emitter.direction = onlr.property.number(0, { description = "In radians, clockwise from the right", heading = "Motion" })
Emitter.spread = onlr.property.number(0, { min = 0, description = "The angle around direction, in radians, that particles leave in" })
Emitter.speed = range(0, 0, { description = "Pixels a second" })
Emitter.linearAcceleration = onlr.property.group({ min = onlr.property.vector(0, 0), max = onlr.property.vector(0, 0) }, { description = "Pixels a second, each second, such as gravity" })
Emitter.radialAcceleration = range(0, 0, { description = "Away from the emitter" })
Emitter.tangentialAcceleration = range(0, 0, { description = "Around the emitter" })
Emitter.linearDamping = range(0, 0)

Emitter.sizes = onlr.property.list(onlr.property.number(1, { min = 0 }), { description = "Up to 8 sizes, which a particle goes through in its life. Empty is 1", heading = "Look" })
Emitter.sizeVariation = onlr.property.number(0, { min = 0, max = 1 })
Emitter.colors = onlr.property.list(onlr.property.color(), { description = "Up to 8 colours, which a particle goes through in its life. Empty is white" })
Emitter.rotation = range(0, 0, { description = "Each particle's angle at its start, in radians" })
Emitter.spin = range(0, 0, { description = "Radians a second" })
Emitter.spinVariation = onlr.property.number(0, { min = 0, max = 1 })
Emitter.relativeRotation = onlr.property.bool(false, { description = "A particle turns to the way it moves" })

-- The picture of a particle without an image: a white circle, made once and shared.
local dot
local function dotImage()
  if not dot then
    local data = love.image.newImageData(8, 8)
    data:mapPixel(function(x, y)
      local inside = (x + 0.5 - 4) ^ 2 + (y + 0.5 - 4) ^ 2 <= 16
      return 1, 1, 1, inside and 1 or 0
    end)
    dot = love.graphics.newImage(data)
  end
  return dot
end

-- Sets a system's settings from the properties.
---@param self particles.emitter
---@param system love.ParticleSystem
local function settle(self, system)
  system:setBufferSize(self.bufferSize)
  system:setInsertMode(self.insertMode)
  system:setEmissionRate(self.emissionRate)
  system:setEmitterLifetime(self.emitterLifetime)
  system:setParticleLifetime(self.particleLifetime.min, self.particleLifetime.max)
  local area = self.emissionArea
  system:setEmissionArea(area.distribution, area.dx, area.dy, area.angle, area.directionRelativeToCenter)
  system:setDirection(self.direction)
  system:setSpread(self.spread)
  system:setSpeed(self.speed.min, self.speed.max)
  local a = self.linearAcceleration
  system:setLinearAcceleration(a.min.x, a.min.y, a.max.x, a.max.y)
  system:setRadialAcceleration(self.radialAcceleration.min, self.radialAcceleration.max)
  system:setTangentialAcceleration(self.tangentialAcceleration.min, self.tangentialAcceleration.max)
  system:setLinearDamping(self.linearDamping.min, self.linearDamping.max)
  if #self.sizes > 8 then
    error("particles.emitter: a system takes up to 8 sizes", 0)
  end
  system:setSizes(unpack(#self.sizes > 0 and self.sizes or { 1 }))
  system:setSizeVariation(self.sizeVariation)
  if #self.colors > 8 then
    error("particles.emitter: a system takes up to 8 colours", 0)
  end
  local colors = {}
  for _, c in ipairs(#self.colors > 0 and self.colors or { { 1, 1, 1, 1 } }) do
    colors[#colors + 1] = c[1]
    colors[#colors + 1] = c[2]
    colors[#colors + 1] = c[3]
    colors[#colors + 1] = c[4] or 1
  end
  system:setColors(unpack(colors))
  system:setRotation(self.rotation.min, self.rotation.max)
  system:setSpin(self.spin.min, self.spin.max)
  system:setSpinVariation(self.spinVariation)
  system:setRelativeRotation(self.relativeRotation)
end

local function newSystem(self)
  local system = love.graphics.newParticleSystem(self.image or dotImage(), self.bufferSize)
  settle(self, system)
  return system
end

-- The node's place, its angle, and its place in the world as a LÖVE transform, from the engine's public functions.
local function placeOf(node)
  local ox, oy = node:toWorld(0, 0)
  local xx, xy = node:toWorld(1, 0)
  local yx, yy = node:toWorld(0, 1)
  return ox, oy, math.atan2(xy - oy, xx - ox), xx - ox, xy - oy, yx - ox, yy - oy
end

-- Puts a world system at its node, and turns its direction with the node. LÖVE spreads the particles that a frame
-- emits along the way from the last place to this one, so a fast node leaves a line, not dots.
function Emitter:_follow(jump)
  local x, y, angle = placeOf(self.node)
  if jump then
    self.system:setPosition(x, y)
  else
    self.system:moveTo(x, y)
  end
  self.system:setDirection(self.direction + angle)
end

function Emitter:load()
  self.system = newSystem(self)
  if self.space == "world" then
    self:_follow(true)
  end
  if self.autoPlay then
    self.system:start()
  else
    self.system:stop()
    self.ended = true
  end
end

-- Not called by the engine: scripts call these. They are LÖVE's own, on the system.

-- Sets the system's settings again from the properties, after a script changed them: emitter.emissionRate = 50.
-- The particles that live keep what they had.
function Emitter:apply()
  settle(self, assert(self.system))
  if self.space == "world" then
    self:_follow(true)
  end
end

-- Emits for emitterLifetime from now. It is not named start, which the engine calls at a component's start (6.4). Its node is told particlesEnd() when that ends and the last particle dies.
function Emitter:play()
  self.ended = false
  assert(self.system):start()
end

-- Emits no more. The particles that live go on.
function Emitter:stop()
  assert(self.system):stop()
end

-- Emits a number of particles at once, as an explosion does, also when it is stopped.
---@param count integer
function Emitter:emit(count)
  self.ended = false
  local system = assert(self.system)
  if self.space == "world" then
    self:_follow(true)
  end
  -- LÖVE's emit does nothing while the system is stopped, so a stopped one runs for the moment of the emit.
  if system:isActive() then
    system:emit(count)
  else
    system:start()
    system:emit(count)
    system:stop()
  end
end

-- Removes every particle, and starts the emitter's time again.
function Emitter:reset()
  assert(self.system):reset()
end

-- The particles that live.
---@return integer
function Emitter:getCount()
  return self.system and self.system:getCount() or 0
end

-- LÖVE's particle system, for all of LÖVE's own functions on it, such as setQuads.
---@return love.ParticleSystem?
function Emitter:get()
  return self.system
end

function Emitter:update(dt)
  local system = self.system
  if not system then
    return
  end
  if self.space == "world" then
    self:_follow(false)
  end
  system:update(dt)
  if not self.ended and not system:isActive() and system:getCount() == 0 then
    self.ended = true
    self.node:send("particlesEnd")
  end
end

-- After it or its node was turned off, the emitter goes on from its node's place, with no line from where it was.
function Emitter:enable()
  if self.system and self.space == "world" then
    self:_follow(true)
  end
end

function Emitter:draw()
  local system = self.system
  if not system then
    return
  end
  if self.space == "world" then
    -- The engine draws at the node's place; a world system's particles are at their places in the world, so the
    -- node's own transform is undone, and what is above it, such as a camera, stays.
    local ox, oy, _, ax, ay, bx, by = placeOf(self.node)
    local det = ax * by - bx * ay
    if det == 0 then
      return
    end
    local ia, ib, ic, id = by / det, -bx / det, -ay / det, ax / det
    self.undo = self.undo or love.math.newTransform()
    self.undo:setMatrix(ia, ib, 0, -(ia * ox + ib * oy), ic, id, 0, -(ic * ox + id * oy), 0, 0, 1, 0, 0, 0, 0, 1)
    love.graphics.push()
    love.graphics.applyTransform(self.undo)
    love.graphics.draw(system)
    love.graphics.pop()
  else
    love.graphics.draw(system)
  end
end

-- The node view shows a still picture: the system as it is after it has run for its particles' lifetime, made once
-- and kept, so it is made again only when a value changes (DESIGN 6.5). It is drawn at the node, also for a world system.
function Emitter:drawEditor(chosen)
  if not self.shown then
    local system = newSystem(self)
    system:start()
    local seconds = math.min(math.max(self.particleLifetime.min, self.particleLifetime.max), 5)
    if self.emitterLifetime >= 0 then
      seconds = math.min(seconds, self.emitterLifetime)
    end
    local step = 1 / 30
    for _ = 1, math.ceil(seconds / step) do
      system:update(step)
    end
    self.shown = system
  end
  love.graphics.draw(self.shown)
  love.graphics.setColor(0.6, 0.9, 1, chosen and 1 or 0.5)
  love.graphics.line(-6, 0, 6, 0)
  love.graphics.line(0, -6, 0, 6)
  local area = self.emissionArea
  if area.distribution ~= "none" then
    love.graphics.rotate(area.angle)
    if area.distribution == "ellipse" or area.distribution == "borderellipse" or area.distribution == "normal" then
      love.graphics.ellipse("line", 0, 0, area.dx, area.dy)
    else
      love.graphics.rectangle("line", -area.dx, -area.dy, area.dx * 2, area.dy * 2)
    end
  end
end

-- The emission area, or a small square at the node, for choosing it in the node view.
function Emitter:bounds()
  local area = self.emissionArea
  local w, h = math.max(area.dx, 8), math.max(area.dy, 8)
  return -w, -h, w * 2, h * 2
end

return Emitter
