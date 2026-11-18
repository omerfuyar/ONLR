-- The component type onlr.camera.follow: moves its node's camera to follow a node, as most games' cameras do.
-- It moves the camera's own point, posX and posY, in lateUpdate, after the scripts and the physics moved the target.
local onlr = require("onlr")

---@class onlr.camera.follow : onlr.Component
local Follow = {}

Follow.needs = { "onlr.camera.view" }

Follow.target = onlr.property.node({ description = "The node that the camera follows, such as the player. A script may set it" })
Follow.offset = onlr.property.vector(0, 0, { description = "Added to the target's place: the camera shows a point ahead of it or above it" })
Follow.smoothing = onlr.property.number(0.1, {
  min = 0,
  description = "About the seconds that the camera takes to catch up: 0 keeps it on the target",
})
Follow.deadzone = onlr.property.vector(0, 0, {
  description = "A rectangle around the camera's point, in its node's units, in which the target moves and the camera does not",
})

-- The point that the camera goes to: the target's place, kept inside the deadzone. Nil without a target.
---@param self onlr.camera.follow
---@param camera onlr.camera.view
local function aim(self, camera)
  local target = self.target
  if not target or target:isDestroyed() then
    return nil
  end
  local tx, ty = self.node:toLocal(target:toWorld(0, 0))
  tx, ty = tx + self.offset.x, ty + self.offset.y
  local x, y = camera.posX, camera.posY
  local hw, hh = self.deadzone.x / 2, self.deadzone.y / 2
  if tx > x + hw then
    x = tx - hw
  elseif tx < x - hw then
    x = tx + hw
  end
  if ty > y + hh then
    y = ty - hh
  elseif ty < y - hh then
    y = ty + hh
  end
  return x, y
end

-- After it moves the camera, the node's camera limits keep it in, whichever of the two updated first.
local function limit(self)
  local limits = self.node.components.onlr.camera.limits
  if limits and limits:isEnabled() then
    limits:clamp()
  end
end

-- Not called by the engine: scripts call it. Puts the camera on its target at once, as after a level starts or the
-- player is put somewhere else. It is called when the component starts to run.
function Follow:snap()
  local camera = self.node.components.onlr.camera.view --[[@as onlr.camera.view]]
  local x, y = aim(self, camera)
  if x and y then
    camera.posX, camera.posY = x, y
    limit(self)
  end
end

function Follow:enable()
  self:snap()
end

function Follow:lateUpdate(dt)
  local camera = self.node.components.onlr.camera.view --[[@as onlr.camera.view]]
  local x, y = aim(self, camera)
  if not x or not y then
    return
  end
  if self.smoothing > 0 then
    local k = 1 - math.exp(-dt / self.smoothing)
    camera.posX = camera.posX + (x - camera.posX) * k
    camera.posY = camera.posY + (y - camera.posY) * k
  else
    camera.posX, camera.posY = x, y
  end
  limit(self)
end

-- In the node view, the deadzone, around the camera's point.
function Follow:drawEditor(chosen)
  local camera = self.node.components.onlr.camera.view --[[@as onlr.camera.view]]
  local w, h = self.deadzone.x, self.deadzone.y
  if w <= 0 and h <= 0 then
    return
  end
  love.graphics.setColor(0.38, 0.69, 0.94, chosen and 0.8 or 0.4)
  love.graphics.rectangle("line", camera.posX - w / 2, camera.posY - h / 2, w, h)
end

return Follow
