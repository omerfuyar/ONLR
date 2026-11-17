-- What every joint's component of physics shares. A joint is on its body's node or on a node under it, as a shape is, and
-- holds that body to the body that its property other names; the joint's node is where it holds them, such as a hinge's
-- pin. It is made when both bodies run, and ends when either stops, as Box2D ends it (DESIGN 11.4).
local onlr = require("onlr")
local shape = require("physics.shape")

local joint = {}

---Gives a joint's type the properties and functions that every joint has.
---@param Type table
---@param name string the type's name, such as "physics.hinge"
function joint.declare(Type, name)
  Type.other = onlr.property.component("physics.body", { description = "The body that it joins to its own" })
  Type.collide = onlr.property.bool(false, { description = "Its two bodies still collide with each other" })

  function Type:enable()
    self.owner = shape.bodyOf(self.node)
    if not self.owner then
      error(("%s on %s has no physics.body on its node or above it"):format(name, self.node.name), 0)
    end
    if not self.other or self.other == self.owner then
      error(("%s on %s names no other body to join"):format(name, self.node.name), 0)
    end
    self.owner:_hold(self)
    self.other:_hold(self)
    self:_join()
  end

  function Type:disable()
    self:_unjoin()
    if self.owner then
      self.owner:_release(self)
      self.other:_release(self)
      self.owner = nil
    end
  end

  ---The joint of love.physics, for all that LÖVE's own functions do; nil while either body does not run.
  ---@return love.Joint?
  function Type:get()
    return self.joint
  end

  -- Not called by scripts: the bodies call them when they start and stop.
  function Type:_join()
    if self.joint or not (self.owner and self.owner.b and self.other.b) then
      return
    end
    local ax, ay = self.node:toWorld(0, 0)
    self.joint = self:_make(self.owner.b, self.other.b, ax, ay)
  end

  function Type:_unjoin()
    if self.joint and not self.joint:isDestroyed() then
      self.joint:destroy()
    end
    self.joint = nil
  end

  -- In the node view: a line from the joint's place to the other body's node, and a ring at the joint's place.
  function Type:drawEditor(chosen)
    love.graphics.setColor(0.6, 0.8, 1, chosen and 1 or 0.5)
    love.graphics.circle("line", 0, 0, 4)
    local other = self.other and self.other.node
    if other then
      local x, y = self.node:toLocal(other:toWorld(self.otherAnchor and self.otherAnchor.x or 0, self.otherAnchor and self.otherAnchor.y or 0))
      love.graphics.line(0, 0, x, y)
    end
  end

  function Type:bounds()
    return -4, -4, 8, 8
  end
end

return joint
