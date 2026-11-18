-- The component type onlr.camera.shake: shakes its node's camera, as a hit or an explosion does. A script calls
-- shake(amount); the shake fades by itself. It moves only what the camera draws (DESIGN 10): the camera's own point,
-- which a follow and limits set, stays still.
local onlr = require("onlr")

---@class onlr.camera.shake : onlr.Component
---@field private trauma number? from 0 to 1: how hard it shakes now
---@field private time number?
local Shake = {}

Shake.needs = { "onlr.camera.view" }

Shake.amplitude = onlr.property.vector(8, 8, { description = "The farthest it moves, across and down, in its node's units" })
Shake.angle = onlr.property.number(0.05, { min = 0, description = "The farthest it turns, in radians" })
Shake.frequency = onlr.property.number(15, { min = 0, description = "How fast it shakes" })
Shake.decay = onlr.property.number(1.5, { min = 0, description = "How much of a shake of 1 fades in a second" })

-- Not called by the engine: scripts call it. Adds to the shake, up to 1: 0.3 is a bump, and 1 an explosion.
---@param amount? number 0.5 when left out
function Shake:shake(amount)
  self.trauma = math.min(1, (self.trauma or 0) + (amount or 0.5))
end

-- How hard it shakes now, from 0 to 1.
---@return number
function Shake:getTrauma()
  return self.trauma or 0
end

-- The shake grows as the square of the trauma, so a small one is gentle and a large one wild. Its motion is
-- LÖVE's noise, smooth from frame to frame, not a new random place each frame.
function Shake:lateUpdate(dt)
  local camera = self.node.components.onlr.camera.view --[[@as onlr.camera.view]]
  self.time = (self.time or 0) + dt
  self.trauma = math.max(0, (self.trauma or 0) - self.decay * dt)
  local p = self.trauma * self.trauma
  local t = self.time * self.frequency
  camera.shakeX = self.amplitude.x * p * (love.math.noise(1, t) * 2 - 1)
  camera.shakeY = self.amplitude.y * p * (love.math.noise(2, t) * 2 - 1)
  camera.shakeRot = self.angle * p * (love.math.noise(3, t) * 2 - 1)
end

-- Turned off, the camera stands still.
function Shake:disable()
  local camera = self.node.components.onlr.camera.view
  if camera then
    camera.shakeX, camera.shakeY, camera.shakeRot = 0, 0, 0
  end
end

return Shake
