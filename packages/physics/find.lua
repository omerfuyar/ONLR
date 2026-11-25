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

-- A check of what a fixture or a joint is made from, before each step: the values are compared, one after another, with those
-- of the last check, which a list keeps, so a check makes no garbage. start begins one, note gives each value, and finish
-- tells whether any differed.
local seen, at, differs = {}, 0, false

---Begins a check against the values that a list kept at the last one.
---@param list any[]
function find.start(list)
  seen, at, differs = list, 0, false
end

---Gives the check's next value.
---@param value any
function find.note(value)
  at = at + 1
  if seen[at] ~= value then
    seen[at] = value
    differs = true
  end
end

---Gives what places a node in its body's space: the place, angle and scale of each node from it up to the body's node, and the
---body's node's scale, which a body's own place and angle do not change. When it differs, the node moved under its body, and
---its fixture or joint is made again (DESIGN 11.4).
---@param node onlr.Node
---@param top onlr.Node the body's node
function find.place(node, top)
  local up = node ---@type onlr.Node?
  while up and up ~= top do
    find.note(up.posX)
    find.note(up.posY)
    find.note(up.rot)
    find.note(up.sclX)
    find.note(up.sclY)
    up = up:getParent()
  end
  find.note(top.sclX)
  find.note(top.sclY)
end

---Ends the check.
---@return boolean differs whether a value differed from the last check's, or their count did
function find.finish()
  for i = #seen, at + 1, -1 do
    seen[i] = nil
    differs = true
  end
  return differs
end

-- The names of each table of setters, in order, worked out once.
local orders = setmetatable({}, { __mode = "k" })

---Sets on a thing of love.physics each value of a component that differs from the one set last, with its setter.
---The setters are the component type's own, made once, so a step makes no functions.
---@param applied table<string, any> the values set last, which this updates
---@param component table
---@param setters table<string, fun(thing: any, value: any, component: table)> by the property's name
---@param thing any the thing of love.physics that they set
---@return boolean changed whether one was set
function find.apply(applied, component, setters, thing)
  local names = orders[setters]
  if not names then
    -- in the order of the names, so a step does the same in every run
    names = {}
    for name in pairs(setters) do
      names[#names + 1] = name
    end
    table.sort(names)
    orders[setters] = names
  end
  local changed = false
  for i = 1, #names do
    local name = names[i]
    local value = component[name]
    if applied[name] ~= value then
      applied[name] = value
      setters[name](thing, value, component)
      changed = true
    end
  end
  return changed
end

return find
