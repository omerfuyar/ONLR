-- A click makes the ball jump: its animation plays jump once, and rolls again when that ends.
---@class jumper : onlr.Component
local Jumper = {}

Jumper.needs = { "anim8.animation" }

function Jumper:mousepressed()
  self.node.components.anim8.animation:play("jump")
end

function Jumper:animationEnd(name)
  if name == "jump" then
    self.node.components.anim8.animation:play("roll")
  end
end

return Jumper
