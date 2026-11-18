-- The component type audio.listener: where the game hears from. A sound with a place (audio.source's positional) is
-- louder near it, and from its left or its right. On a camera's node it hears from the camera's point, and elsewhere
-- from its node's place, such as the player's.
local onlr = require("onlr")

---@class audio.listener : onlr.Component
local Listener = {}

Listener.volume = onlr.property.number(1, { min = 0, max = 1, description = "The volume of every sound, as love.audio.setVolume" })
Listener.distanceModel = onlr.property.choice("inverseclamped", {
  choices = { "none", "inverse", "inverseclamped", "linear", "linearclamped", "exponent", "exponentclamped" },
  description = "How sounds fade with distance, as love.audio.setDistanceModel. linearclamped is at its volume to reference, and silent at max",
})

-- LÖVE has one listener, so one component is it at a time.
---@type audio.listener?
local running

-- The place that it hears from: the camera's point on a camera's node, or the node's place.
local function placeOf(self)
  local view = self.node.components.onlr.camera.view
  if view then
    return self.node:toWorld(view.posX, view.posY)
  end
  return self.node:toWorld(0, 0)
end

local function apply(self)
  love.audio.setVolume(self.volume)
  love.audio.setDistanceModel(self.distanceModel --[[@as love.DistanceModel]])
  local x, y = placeOf(self)
  love.audio.setPosition(x, y, 0)
end

function Listener:enable()
  if running and running ~= self and not running.node:isDestroyed() and running:isEnabled() then
    error("audio.listener: a game has one listener, and " .. running.node.name .. " has it", 0)
  end
  running = self
  apply(self)
end

function Listener:disable()
  if running == self then
    running = nil
  end
end

-- After the scripts, the physics and the camera's follow moved what it hears from.
function Listener:lateUpdate()
  apply(self)
end

function Listener:drawEditor(chosen)
  love.graphics.setColor(1, 0.85, 0.4, chosen and 1 or 0.7)
  love.graphics.setLineWidth(2)
  local x, y = 0, 0
  local view = self.node.components.onlr.camera.view
  if view then
    x, y = view.posX, view.posY
  end
  love.graphics.circle("line", x, y, 6)
  love.graphics.line(x - 10, y, x - 6, y)
  love.graphics.line(x + 6, y, x + 10, y)
end

function Listener:bounds()
  return -10, -8, 20, 16
end

return Listener
