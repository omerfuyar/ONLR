-- What the physics package's components share: finding the body that a fixture or a joint belongs to (DESIGN 11.4).
local find = {}

---The body nearest above a node, the node's own first.
---@param node onlr.Node?
---@return physics.body?
function find.bodyOf(node)
  while node do
    local own = node.components.physics
    if own and own.body then
      return own.body
    end
    node = node:getParent()
  end
end

---How large one unit of a node's space is in the world, for a circle's radius.
---@param node onlr.Node
---@return number
function find.scale(node)
  local x0, y0 = node:toWorld(0, 0)
  local x1, y1 = node:toWorld(1, 0)
  return math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
end

return find
