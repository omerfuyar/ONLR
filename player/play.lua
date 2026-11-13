-- The play player (DESIGN 12.1 and 12.6): the game, as an exported game runs it, with the link beside it.
-- The editor stops, pauses and steps it, watches its running tree, and changes a running value.

local part = ...
local link = part("link")

local data = require("onlr.data")
local life = require("onlr.life")
local component = require("onlr.component")
local nodes = require("onlr.node")

local play = {}

local onlr
-- What the engine's loop reads (onlr.loop._player).
local state = { paused = false, step = false }

-- A running node has no id of a file, so each gets a number for the link.
local numbers = setmetatable({}, { __mode = "k" })
local byNumber = setmetatable({}, { __mode = "v" })
local count = 0

local function numberOf(node)
  local n = numbers[node]
  if not n then
    count = count + 1
    n = count
    numbers[node] = n
    byNumber[n] = node
  end
  return n
end

local watchTree = false
---@type integer[]
local watched = {}
local lastTree, treeTime, valuesTime = nil, 0, 0

-- The running tree: each node's number, name, parent and components' types.
local function tree()
  local list = {}
  local function walk(node, parent)
    local types = {}
    for i, r in ipairs(node._records) do
      types[i] = r.type.name
    end
    local n = numberOf(node)
    list[#list + 1] = { n = n, name = node.name, parent = parent, components = types, active = node._active, root = node == onlr.tree.root or nil }
    for _, child in ipairs(node._children) do
      walk(child, n)
    end
  end
  if onlr.tree.top then
    walk(onlr.tree.top, nil)
  end
  return list
end

-- A property's value as the link carries it: a reference as what it names (DESIGN 12.6).
local function carried(decl, value)
  local kind = decl.kind
  if value == nil then
    return nil
  elseif kind == "list" then
    local list = {}
    for i, item in ipairs(value) do
      list[i] = carried(decl.item, item)
    end
    return list
  elseif kind == "group" then
    local group = {}
    for field, fieldDecl in pairs(decl.fields) do
      group[field] = carried(fieldDecl, value[field])
    end
    return group
  elseif kind == "image" or kind == "sound" or kind == "font" then
    return data.paths[value]
  elseif kind == "node" then
    return nodes.isNode(value) and numberOf(value) or nil
  elseif kind == "component" then
    return type(value) == "table" and nodes.isNode(value.node) and numberOf(value.node) or nil
  end
  return value
end

-- The watched nodes' places and their components' values.
local function values()
  local list = {}
  for _, n in ipairs(watched) do
    local node = byNumber[n]
    if node and not node._gone then
      local components = {}
      for _, r in ipairs(node._records) do
        local held = { enabled = r.enabled }
        for _, p in ipairs(r.type.properties) do
          held[p.name] = carried(p.decl, r.component[p.name])
        end
        components[r.type.name] = held
      end
      list[#list + 1] = {
        n = n, name = node.name, posX = node.posX, posY = node.posY, rot = node.rot, sclX = node.sclX, sclY = node.sclY,
        z = node._z, active = node._active, components = components,
      }
    end
  end
  return list
end

local handlers = {}

function handlers.stop()
  love.event.quit(0)
end

function handlers.pause()
  state.paused = true
end

function handlers.resume()
  state.paused = false
end

function handlers.step()
  state.paused = true
  state.step = true
end

-- Which running nodes to send, or none.
function handlers.watch(message)
  watchTree = message.tree and true or false
  watched = message.nodes or {}
  lastTree = nil
  treeTime, valuesTime = 0, 0
end

local PLACE = { name = true, posX = true, posY = true, rot = true, sclX = true, sclY = true }

-- A new value for a running node, set between two frames, as a script sets a field.
-- A node's active and z and a component's enabled are set through their functions.
function handlers.set(message)
  local node = byNumber[message.node]
  if not node or node._gone then
    return
  end
  if message.component then
    local c = node._byType[message.component]
    if not c then
      return
    end
    if message.property == "enabled" then
      c:setEnabled(message.value)
    else
      for _, p in ipairs(component.type(message.component).properties) do
        if p.name == message.property and not onlr.property.REFERENCES[p.decl.kind] then
          c[p.name] = message.value
        end
      end
    end
  elseif PLACE[message.field] then
    node[message.field] = message.value
  elseif message.field == "z" then
    node:setZ(message.value)
  elseif message.field == "active" then
    node:setActive(message.value)
  end
end

-- Called once in each turn of the engine's loop: reads the link, and sends what the editor watches.
local function frame()
  for _, item in ipairs(link.poll()) do
    local handler = handlers[item[1].type]
    if handler then
      handler(item[1], item[2])
    end
  end
  if link.closed and play.linked then
    -- The editor is gone, so the game ends too.
    love.event.quit(0)
    play.linked = false
  end
  local now = love.timer.getTime()
  if watchTree and now - treeTime >= 0.25 then
    treeTime = now
    local list = tree()
    local text = link.write(list)
    if text ~= lastTree then
      lastTree = text
      link.send({ type = "tree", nodes = list })
    end
  end
  if #watched > 0 and now - valuesTime >= 0.1 then
    valuesTime = now
    link.send({ type = "values", nodes = values() })
  end
end

---Starts the game with the link beside it: called from onlr.start, in main.lua.
---@param engine onlr
---@param options table<string, string> the editor's arguments
function play.start(engine, options)
  onlr = engine
  play.linked = not link.closed
  if options.start then
    onlr.tree._startNode = options.start
  end
  state.frame = frame
  onlr.loop._player = state
  -- A game with a love.run of its own does not run the engine's loop, so the link is read when its frame ends.
  local endFrame = onlr.loop.endFrame
  onlr.loop.endFrame = function()
    endFrame()
    if not onlr.loop._running then
      frame()
    end
  end
  life.mode = "game"
end

return play
