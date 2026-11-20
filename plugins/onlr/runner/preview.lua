-- The preview (DESIGN 12.3 to 12.5): it draws views of node files for the editor's node views, and answers
-- what a component type declares. It runs no game: no load, update or event reaches a component.
-- It draws a view only when the editor asked and has taken the view's last frame.
---@diagnostic disable: invisible -- the engine reads the fields of its nodes that a script does not see

local part = ...
local link = part("link")

local data = require("onlr.library.data")
local life = require("onlr.library.life")
local build = require("onlr.library.build")
local component = require("onlr.library.component")

local preview = {}

---A view: a node file as the preview draws it.
---@class onlr.View
---@field id integer the editor's number for it
---@field path string the node file
---@field x number the point of the world at the view's top left
---@field y number
---@field zoom number
---@field width integer in pixels
---@field height integer
---@field chosen table<string, boolean> the chosen nodes, by their paths of ids
---@field hidden table<string, boolean> the nodes that the user hid in the node view, which draw nothing there, nor the nodes under them
---@field root onlr.Node? its nodes, or nil when the file did not load
---@field scope onlr.Scope? its nodes by their ids
---@field dirty boolean it must be drawn again
---@field moved number? when its chosen nodes moved last, or nil when none moves (DESIGN 6.5)
---@field boundsDue boolean? its nodes changed, so their bounds are sent again
---@field waiting boolean its last frame was sent, and the editor has not taken it yet
---@field canvas love.Canvas?
---@field swapped love.Canvas?

---@type table<integer, onlr.View>
local views = {}

-- OpenECS's images hold a pixel as blue, green, red and alpha, and LÖVE as red, green, blue and alpha.
-- The view is drawn once more through this shader, so the graphics card swaps red and blue (DESIGN 12.4).
-- A canvas holds colours multiplied by their alpha, as gpu's textures do, so they stay so.
local swap

local function send(message, block)
  link.send(message, block)
end

-- The nodes of a view in the order of drawing: by z, and in the tree's order within one z (DESIGN 5).
local function ordered(root)
  local list, seq = {}, 0
  local function walk(node, z, active)
    z = z + node._z
    active = active and node._active
    seq = seq + 1
    list[#list + 1] = { node = node, z = z, seq = seq, active = active }
    for _, child in ipairs(node._children) do
      walk(child, z, active)
    end
  end
  walk(root, 0, true)
  table.sort(list, function(a, b)
    if a.z ~= b.z then
      return a.z < b.z
    end
    return a.seq < b.seq
  end)
  return list
end

-- Notes on a node what went wrong with it, once.
local function mark(node, message)
  node._errors = node._errors or {}
  for _, known in ipairs(node._errors) do
    if known == message then
      return false
    end
  end
  node._errors[#node._errors + 1] = message
  return true
end

-- Calls loadEditor on a node's components, in the order that they load, so one finds those that it needs ready (DESIGN 6.5).
-- A loadEditor that fails marks its node, as a drawEditor does, and the others go on.
local function loadEditor(node)
  for _, r in ipairs(node._records) do
    local c = r.component
    if c.loadEditor then
      local ok, err = pcall(c.loadEditor, c)
      if not ok then
        mark(node, tostring(err))
      end
    end
  end
end

-- Makes a view's nodes from its node file, as the editor holds it. A file that does not load leaves the view empty.
local function load(view)
  local ok, root, scope = pcall(build.file, view.path, true)
  if ok then
    view.root, view.scope = root, scope
    for _, entry in ipairs(ordered(root)) do
      loadEditor(entry.node)
    end
  else
    view.root, view.scope = nil, nil
    local file, line, rest = tostring(root):match("^([^:\n]+):(%d+): (.*)$")
    send({ type = "error", view = view.id, message = rest or tostring(root), file = file or view.path, line = tonumber(line) })
  end
  view.dirty = true
  view.boundsDue = true
end

local function loadAll()
  for _, view in pairs(views) do
    load(view)
  end
end

-- Sends the nodes' bounds, in each node's own space, with its place in the world (DESIGN 12.3).
-- The nodes are in the order of drawing, so the panel finds the one that draws last under the pointer.
local function sendBounds(view)
  view.boundsDue = false
  local nodes = {}
  for _, entry in ipairs(view.root and ordered(view.root) or {}) do
    local node = entry.node
    local x1, y1, x2, y2
    for _, r in ipairs(node._records) do
      local c = r.component
      if c.bounds then
        local ok, x, y, w, h = pcall(c.bounds, c)
        if ok and type(x) == "number" and type(h) == "number" then
          x1, y1 = math.min(x1 or x, x), math.min(y1 or y, y)
          x2, y2 = math.max(x2 or (x + w), x + w), math.max(y2 or (y + h), y + h)
        elseif not ok then
          mark(node, tostring(x))
        end
      end
    end
    local a, b, c, d, tx, ty = node:_world()
    nodes[#nodes + 1] = {
      path = node._path,
      name = node.name,
      parent = node._parent and node._parent._path,
      file = node._file,
      active = entry.active,
      place = { a, b, c, d, tx, ty },
      rect = x1 and { x1, y1, x2 - x1, y2 - y1 },
      errors = node._errors,
    }
  end
  send({ type = "bounds", view = view.id, nodes = nodes })
end

-- Draws a view into its canvas, and sends its pixels as a frame (DESIGN 12.4).
local function draw(view)
  view.dirty = false
  local w, h = view.width, view.height
  if w < 1 or h < 1 then
    return
  end
  if not view.canvas or view.canvas:getWidth() ~= w or view.canvas:getHeight() ~= h then
    view.canvas = love.graphics.newCanvas(w, h)
    view.swapped = love.graphics.newCanvas(w, h)
  end
  swap = swap or love.graphics.newShader([[
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
      vec4 pixel = Texel(tex, texture_coords);
      return vec4(pixel.b, pixel.g, pixel.r, pixel.a);
    }
  ]])

  love.graphics.reset()
  love.graphics.setCanvas(view.canvas)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.scale(view.zoom)
  love.graphics.translate(-view.x, -view.y)
  local failed = false
  for _, entry in ipairs(view.root and ordered(view.root) or {}) do
    local node = entry.node
    local hidden = false
    local above = node
    while above and not hidden do
      hidden = view.hidden[above._path] == true
      above = above._parent
    end
    if entry.active and not hidden then
      for _, r in ipairs(node._records) do
        local c = r.component
        if r.enabled and c.drawEditor then
          -- All of LÖVE's drawing state is saved before each drawEditor and restored after (DESIGN 6.5).
          local depth = love.graphics.getStackDepth()
          love.graphics.push("all")
          love.graphics.applyTransform(node:_drawTransform())
          local ok, err = pcall(c.drawEditor, c, view.chosen[node._path] == true)
          while love.graphics.getStackDepth() > depth do
            love.graphics.pop()
          end
          if not ok and mark(node, tostring(err)) then
            failed = true
          end
        end
      end
    end
  end

  love.graphics.reset()
  love.graphics.setCanvas(view.swapped)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setBlendMode("replace", "premultiplied")
  love.graphics.setShader(swap)
  love.graphics.draw(view.canvas)
  love.graphics.reset()
  love.graphics.setCanvas()

  if failed or view.boundsDue then
    sendBounds(view)
  end
  local pixels = view.swapped:newImageData()
  view.waiting = true
  send({ type = "frame", view = view.id, width = w, height = h, x = view.x, y = view.y, zoom = view.zoom }, pixels:getString())
  pixels:release()
end

-- A declaration as the editor gets it: its kind, default and options, and for a group its fields in their order.
local function declared(name, decl)
  local out = { name = name, kind = decl.kind, default = decl.default, options = decl.options, type = decl.type }
  if decl.item then
    out.item = declared(nil, decl.item)
  end
  if decl.fields then
    local fields = {}
    for field, fieldDecl in pairs(decl.fields) do
      fields[#fields + 1] = declared(field, fieldDecl)
      fields[#fields].order = fieldDecl.order
    end
    table.sort(fields, function(a, b)
      return a.order < b.order
    end)
    out.fields = fields
  end
  return out
end

-- Answers what a component type declares: its properties in their order, and the types that it needs (DESIGN 12.5).
local function answer(name)
  local ok, info = pcall(component.type, name)
  if not ok then
    send({ type = "answer", name = name, error = tostring(info) })
    return
  end
  local properties = {}
  for i, p in ipairs(info.properties) do
    properties[i] = declared(p.name, p.decl)
  end
  send({
    type = "answer",
    name = name,
    file = info.file,
    properties = properties,
    needs = info.needs,
    shows = info.table.drawEditor ~= nil,
  })
end

local FIELDS = { name = true, posX = true, posY = true, rot = true, sclX = true, sclY = true }

local handlers = {}

-- A node file as the editor holds it, saved or not: it is read in place of the project's file.
function handlers.file(message)
  data.texts[message.path] = message.text
  data.forget(message.path)
  loadAll()
end

-- One edit of a node's own fields, such as a moved node, or of its components' values, such as a shape's dragged point, set on the
-- view's nodes without making them anew. A value is one that a node file holds as it is, such as a number or a list of vectors.
function handlers.change(message)
  for _, view in pairs(views) do
    local node = view.path == message.path and view.scope and view.scope.nodes[message.node]
    if node then
      for field, value in pairs(message.fields or {}) do
        if FIELDS[field] then
          node[field] = value
        elseif field == "z" then
          node._z = value
        elseif field == "active" then
          node._active = value and true or false
        end
      end
      for typeName, values in pairs(message.values or {}) do
        local c = node._byType[typeName]
        if c then
          for name, value in pairs(values) do
            c[name] = value
          end
        end
      end
      if message.values then
        loadEditor(node)
      end
      view.dirty = true
      view.boundsDue = true
    end
  end
end

-- Which node file to draw, from where, and at what size. A view that is closed is forgotten.
function handlers.view(message)
  local view = views[message.id]
  if message.closed then
    views[message.id] = nil
    return
  end
  if not view then
    view = { id = message.id, path = message.path, chosen = {}, hidden = {}, waiting = false, dirty = true, x = 0, y = 0, zoom = 1, width = 0, height = 0 }
    views[message.id] = view
  end
  local path = view.root and view.path
  view.path = message.path or view.path
  view.x, view.y, view.zoom = message.x or view.x, message.y or view.y, message.zoom or view.zoom
  view.width, view.height = math.floor(message.width or view.width), math.floor(message.height or view.height)
  if message.hidden then
    view.hidden = {}
    for _, id in ipairs(message.hidden) do
      view.hidden[id] = true
    end
  end
  if message.chosen then
    view.chosen = {}
    for _, id in ipairs(message.chosen) do
      view.chosen[id] = true
    end
  end
  if view.path ~= path then
    load(view)
  end
  view.dirty = true
end

-- The editor has taken the view's last frame.
function handlers.shown(message)
  if views[message.id] then
    views[message.id].waiting = false
  end
end

function handlers.question(message)
  answer(message.name)
end

-- A file of the project that is not Lua changed, such as an image.
function handlers.reload(message)
  data.forget(message.path)
  loadAll()
end

function handlers.stop()
  love.event.quit(0)
end

-- How often the chosen nodes move in the node view, a second (DESIGN 6.5): a frame goes through the link each time, so
-- fewer than the game's.
local MOVES = 30

-- Calls updateEditor on the components of a view's chosen nodes, when the time of a step has passed, and gives whether one
-- moved, so the view is drawn again. A component that fails marks its node, and moves no more until its node is made again.
local function move(view, now)
  local dt = now - (view.moved or now)
  if view.moved and dt < 1 / MOVES then
    return false
  end
  local moved = false
  for path in pairs(view.chosen) do
    local node = view.scope and view.scope.nodes[path]
    for _, r in ipairs(node and node._active and node._records or {}) do
      local c = r.component
      if r.enabled and c.updateEditor and not c._stopped then
        local ok, err = pcall(c.updateEditor, c, math.min(dt, 0.1))
        if not ok then
          c._stopped = true
          mark(node, tostring(err))
          view.boundsDue = true
        end
        moved = true
      end
    end
  end
  view.moved = moved and now or nil
  return moved
end

-- The preview's loop, in place of the game's: it waits for the editor, and draws when asked, or when a chosen node moves.
local function run()
  return function()
    love.event.pump()
    for name, a in love.event.poll() do
      if name == "quit" then
        return a or 0
      end
    end
    local busy = false
    for _, item in ipairs(link.poll()) do
      local handler = handlers[item[1].type]
      if handler then
        handler(item[1], item[2])
      end
      busy = true
    end
    if link.closed then
      return 0
    end
    local moving = false
    for _, view in pairs(views) do
      if not view.waiting and move(view, love.timer.getTime()) then
        view.dirty = true
      end
      moving = moving or view.moved ~= nil
      if view.dirty and not view.waiting then
        draw(view)
        busy = true
      elseif view.boundsDue then
        sendBounds(view)
      end
    end
    if not busy then
      link.wait(moving and 1 / MOVES / 2 or 0.05)
    end
  end
end

-- On Windows SDL's offscreen driver cannot start LÖVE, so LÖVE opens its window and this hides it at once (DESIGN 12.1).
local function hideWindow()
  if love.system.getOS() ~= "Windows" then
    return
  end
  local ok, ffi = pcall(require, "ffi")
  if not ok then
    return
  end
  pcall(function()
    ffi.cdef([[
      typedef struct SDL_Window SDL_Window;
      SDL_Window *SDL_GL_GetCurrentWindow(void);
      void SDL_HideWindow(SDL_Window *window);
    ]])
    local sdl = ffi.load("SDL2")
    local window = sdl.SDL_GL_GetCurrentWindow()
    if window ~= nil then
      sdl.SDL_HideWindow(window)
    end
  end)
end

---Makes the game's start the preview's: called from onlr.start, in main.lua.
function preview.start()
  life.mode = "preview"
  hideWindow()
  if love.audio then
    love.audio.setVolume(0)
  end
  -- main.lua goes on after onlr.start, and may set love.run or love.load of its own: the preview keeps its loop.
  rawset(love, "run", nil)
  setmetatable(love, {
    __index = { run = run },
    __newindex = function(t, key, value)
      if key ~= "run" then
        rawset(t, key, value)
      end
    end,
  })
end

return preview
