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

---A text of what places a node in its body's space: the place, angle and scale of each node from it up to the body's node,
---and the body's node's scale, which a body's own place and angle do not change. When it differs from the last one, the node
---moved under its body, and its fixture or joint is made again (DESIGN 11.4).
---@param node onlr.Node
---@param top onlr.Node the body's node
---@return string
function find.placeKey(node, top)
  local parts = {}
  while node and node ~= top do
    parts[#parts + 1] = ("%.17g %.17g %.17g %.17g %.17g"):format(node.posX, node.posY, node.rot, node.sclX, node.sclY)
    node = node:getParent()
  end
  parts[#parts + 1] = ("%.17g %.17g"):format(top.sclX, top.sclY)
  return table.concat(parts, "|")
end

---Sets on a thing of love.physics each value of a component that differs from the one set last, with its setter.
---@param applied table<string, any> the values set last, which this updates
---@param component table
---@param setters table<string, fun(value: any)> by the property's name
---@return boolean changed whether one was set
function find.apply(applied, component, setters)
  local changed = false
  for name, set in pairs(setters) do
    local value = component[name]
    if applied[name] ~= value then
      applied[name] = value
      set(value)
      changed = true
    end
  end
  return changed
end

return find
