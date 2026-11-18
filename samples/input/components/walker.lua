-- A player's script: it walks by the pair move and counts its jumps. It asks for controls, never for keys.
---@class walker : onlr.Component
local Walker = {}

Walker.needs = { "baton.input" }

function Walker:load()
  self.jumps = 0
end

function Walker:update(dt)
  local input = self.node.components.baton.input
  local x, y = input:get("move")
  self.node.posX = self.node.posX + x * 60 * dt
  self.node.posY = self.node.posY + y * 60 * dt
  if input:pressed("jump") then
    self.jumps = self.jumps + 1
  end
end

return Walker
