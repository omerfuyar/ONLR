-- Walks by the pair move, and jumps with jump: it asks for controls, never for keys, so a gamepad works as the
-- keyboard does.
---@class walker : onlr.Component
local Walker = {}

Walker.needs = { "baton.input", "flux.tweens" }

function Walker:update(dt)
  local input = self.node.components.baton.input
  local x, y = input:get("move")
  self.node.posX = self.node.posX + x * 150 * dt
  self.node.posY = self.node.posY + y * 150 * dt
  if input:pressed("jump") then
    self.node.sclX, self.node.sclY = 1.5, 1.5
    self.node.components.flux.tweens:to(self.node, 0.3, { sclX = 1, sclY = 1 }):ease("backout")
  end
end

return Walker
