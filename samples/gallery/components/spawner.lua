-- A click makes an instance of a node file where the pointer is, in the room.
local onlr = require("onlr")

---@class spawner : onlr.Component
local Spawner = {}

Spawner.file = onlr.property.nodeFile({ preload = true, description = "What a click makes" })
Spawner.button = onlr.property.integer(1, { min = 1, max = 3, description = "The mouse's button: 1 left, 2 right" })

-- The pointer in the game: the top node's screen turns the window's place into the game's.
local function pointer(x, y)
  local screen = onlr.tree.findComponent("push.screen")
  if screen then
    return screen:toGame(x, y)
  end
  return x, y
end

function Spawner:mousepressed(x, y, button)
  if button ~= self.button or not self.file then
    return
  end
  local gx, gy = pointer(x, y)
  if gx and gy and gy > 54 then
    local lx, ly = self.node:toLocal(gx, gy)
    onlr.tree.spawn(self.file, lx, ly, self.node)
  end
end

return Spawner
