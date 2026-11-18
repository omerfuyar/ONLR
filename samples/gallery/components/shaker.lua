-- Space shakes the camera of its node.
---@class shaker : onlr.Component
local Shaker = {}

Shaker.needs = { "onlr.camera.shake" }

function Shaker:keypressed(key)
  if key == "space" then
    self.node.components.onlr.camera.shake:shake(0.6)
  end
end

return Shaker
