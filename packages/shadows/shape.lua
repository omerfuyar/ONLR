-- What shadows.shape's types share: a body of Shädows' own that belongs to the nearest shadows.world, made in enable
-- and taken out in disable, and moved to the node when the node's place in the world changed.
require("shadows") -- the library, which makes its modules ready to require
local Body = require("shadows.Body")
local World = require("packages.shadows.components.world")

local shape = {}

-- Gives a type the functions. make(self, body) makes Shädows' shape on the body; points(self) gives the node's points
-- that the shape is made of, in its node's space; place(self, shape, points) gives the shape the points in the world.
---@param Type table
---@param name string
function shape.declare(Type, name)
  function Type:enable()
    self.world = World.find(self, name)
    self.body = Body:new(self.world:_world())
    self.shape = self:_make(self.body)
    self.placed = nil
    self.world:_add(self)
    self:_sync()
  end

  function Type:disable()
    if self.world then
      self.world:_remove(self)
    end
    if self.body then
      self.body:Remove()
    end
    self.world, self.body, self.shape = nil, nil, nil
  end

  -- The world calls it before it draws: the shape moves only when its points in the world changed, as Shädows
  -- makes its shadows again for a shape that moved.
  function Type:_sync()
    local points = {}
    for _, p in ipairs(self:_points()) do
      local x, y = self.node:toWorld(p[1], p[2])
      points[#points + 1] = x
      points[#points + 1] = y
    end
    local placed = self.placed
    if placed and #placed == #points then
      local same = true
      for i = 1, #points do
        if placed[i] ~= points[i] then
          same = false
          break
        end
      end
      if same then
        return
      end
    end
    self.placed = points
    self:_place(self.shape, points)
  end

  -- Not called by the engine: scripts call it. Shädows' shape, for what the component does not do.
  function Type:get()
    return self.shape
  end
end

return shape
