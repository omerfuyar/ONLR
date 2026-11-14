-- The node view (DESIGN 13.3), and the functions Play, Play This File, Pause, Step and Stop.
-- A node view shows a view of a node file: the edit player draws the nodes into a frame, and the panel draws over it
-- the grid, the window's frame, the outlines of the chosen nodes and the handles of the tool (DESIGN 12.3).

local ecs = require("ecs")
local draw = require("draw")
local project = require("onlr_project")
local console = require("console")
local players = require("players")

local STATE_VERSION = 1
local IMAGES = { png = true, jpg = true, jpeg = true, bmp = true, tga = true }

---A node view.
---@class onlr_player.View
---@field panel ecs.Panel
---@field id integer the view's number on the link
---@field file string? the node file that it shows
---@field x number the point of the world at its top left
---@field y number
---@field zoom number layout units for each pixel of the game
---@field width number its size, in layout units
---@field height number
---@field scale number the surface's pixels for each layout unit
---@field chosen string[] the chosen nodes of its file, kept while another view has the focus
---@field image any? the last frame
---@field frame table? where the last frame was drawn from: x, y, zoom, width and height
---@field fresh boolean a frame arrived that was not shown yet
---@field visible boolean
---@field nodes table[] the nodes' bounds, in the order of drawing
---@field byPath table<string, table>
---@field error string? why the view shows no nodes
---@field drag table? what the pointer drags
---@field lastClick table? where the last click was, and which node it chose

local views = {} ---@type table<ecs.Panel, onlr_player.View>
local nextId = 0
local focused ---@type onlr_player.View? the node view that had the focus last

local function sync(view)
  if not view.file or view.width < 1 then
    return
  end
  players.setView(view.id, {
    path = view.file, x = view.x, y = view.y, zoom = view.zoom * view.scale,
    width = math.floor(view.width * view.scale), height = math.floor(view.height * view.scale), chosen = view.chosen,
  })
end

local function title(view)
  local file = view.file and project.file(view.file)
  view.panel.title = view.file and view.file:match("[^/]*$") or "Node view"
  view.panel.unsaved = file ~= nil and file.dirty
end

local function show(view, file)
  view.file = file
  view.chosen = {}
  view.nodes, view.byPath, view.error, view.image = {}, {}, nil, nil
  title(view)
  sync(view)
  view.panel:redraw()
end

local function viewOf(file)
  for _, view in pairs(views) do
    if view.file == file then
      return view
    end
  end
end

---Opens a node file in a node view, or shows the view that has it.
---@param file string
local function openFile(file)
  local view = viewOf(file)
  if view then
    ecs.layout.focus(view.panel)
    return
  end
  -- A node view that shows no file takes it.
  for _, other in pairs(views) do
    if not other.file then
      show(other, file)
      ecs.layout.focus(other.panel)
      return
    end
  end
  local target = focused and views[focused.panel] and focused.panel or next(views)
  ecs.layout.open("onlr_player.view", { file = file }, target, "center")
end

-- Places

local function toScreen(view, wx, wy)
  return (wx - view.x) * view.zoom, (wy - view.y) * view.zoom
end

local function toWorld(view, sx, sy)
  return sx / view.zoom + view.x, sy / view.zoom + view.y
end

local function nodeToWorld(node, x, y)
  local p = node.place
  return p[1] * x + p[3] * y + p[5], p[2] * x + p[4] * y + p[6]
end

local function worldToNode(place, x, y)
  local a, b, c, d = place[1], place[2], place[3], place[4]
  local det = a * d - b * c
  if det == 0 then
    return 0, 0
  end
  x, y = x - place[5], y - place[6]
  return (d * x - c * y) / det, (a * y - b * x) / det
end

local IDENTITY = { 1, 0, 0, 1, 0, 0 }

-- The nodes under a point of the view, the one that draws last first.
local function hits(view, sx, sy)
  local wx, wy = toWorld(view, sx, sy)
  local found = {}
  for i = #view.nodes, 1, -1 do
    local node = view.nodes[i]
    local hit
    if node.rect then
      local x, y = worldToNode(node.place, wx, wy)
      hit = x >= node.rect[1] and y >= node.rect[2] and x <= node.rect[1] + node.rect[3] and y <= node.rect[2] + node.rect[4]
    else
      -- A node without bounds shows as a marker at its place.
      local mx, my = toScreen(view, node.place[5], node.place[6])
      hit = math.abs(sx - mx) <= 7 and math.abs(sy - my) <= 7
    end
    if hit then
      found[#found + 1] = node.path
    end
  end
  return found
end

local function isChosen(view, path)
  for _, chosen in ipairs(view.chosen) do
    if chosen == path then
      return true
    end
  end
  return false
end

local function choose(view, paths)
  view.chosen = paths
  project.choose(view.file, paths)
end

-- Drawing

local function outline(surface, view, node, color, thickness)
  local r = node.rect
  local corners = { { r[1], r[2] }, { r[1] + r[3], r[2] }, { r[1] + r[3], r[2] + r[4] }, { r[1], r[2] + r[4] } }
  for i = 1, 4 do
    local a, b = corners[i], corners[i % 4 + 1]
    local x1, y1 = toScreen(view, nodeToWorld(node, a[1], a[2]))
    local x2, y2 = toScreen(view, nodeToWorld(node, b[1], b[2]))
    draw.line(surface, x1, y1, x2, y2, thickness, color)
  end
end

local function drawView(view, surface)
  local w, h = surface.width / surface.scale, surface.height / surface.scale
  if w ~= view.width or h ~= view.height or surface.scale ~= view.scale then
    view.width, view.height, view.scale = w, h, surface.scale
    sync(view)
  end
  draw.fill(surface, 0, 0, w, h, "background")

  -- The grid, when its lines are far enough apart to be told from each other.
  local grid = project.setting("grid") or 32
  local step = grid * view.zoom
  if step >= 8 then
    local fx = (-view.x * view.zoom) % step
    for x = fx, w, step do
      draw.fill(surface, x, 0, 1, h, "#ffffff10")
    end
    local fy = (-view.y * view.zoom) % step
    for y = fy, h, step do
      draw.fill(surface, 0, y, w, 1, "#ffffff10")
    end
  end

  -- The last frame, placed by where it was drawn from, so it follows the view until the next one comes.
  if view.image and view.frame then
    local f = view.frame
    local ratio = view.zoom / f.zoom
    local x, y = toScreen(view, f.x, f.y)
    draw.image(surface, view.image, x, y, f.width * ratio, f.height * ratio)
  end
  if view.fresh then
    view.fresh = false
    players.shown(view.id)
  end

  -- The window's frame: where the nodes that no camera holds show (DESIGN 13.3).
  local manifest = project.manifest()
  local window = manifest and manifest.window or {}
  local x0, y0 = toScreen(view, 0, 0)
  draw.outline(surface, x0, y0, (window.width or 800) * view.zoom, (window.height or 600) * view.zoom, 1, "textDim")

  for _, node in ipairs(view.nodes) do
    local chosen = isChosen(view, node.path)
    local color = node.errors and "#e06c75" or chosen and "accent" or nil
    if node.rect then
      if color then
        outline(surface, view, node, color, chosen and 2 or 1)
      end
    else
      local x, y = toScreen(view, node.place[5], node.place[6])
      draw.outline(surface, x - 4, y - 4, 8, 8, 1, color or "textDim")
    end
  end

  -- The tool's handles, on each chosen node's place.
  local tool = project.tool()
  for _, path in ipairs(view.chosen) do
    local node = view.byPath[path]
    if node then
      local x, y = toScreen(view, node.place[5], node.place[6])
      if tool == "move" then
        draw.line(surface, x - 10, y, x + 10, y, 2, "accent")
        draw.line(surface, x, y - 10, x, y + 10, 2, "accent")
      elseif tool == "turn" then
        draw.circle(surface, x, y, 14, 2, "accent")
        local ax, ay = toScreen(view, nodeToWorld(node, 1, 0))
        local length = math.max(1e-6, math.sqrt((ax - x) ^ 2 + (ay - y) ^ 2))
        draw.line(surface, x, y, x + (ax - x) / length * 14, y + (ay - y) / length * 14, 2, "accent")
      else
        draw.outline(surface, x - 12, y - 12, 24, 24, 2, "accent")
        draw.fill(surface, x + 8, y + 8, 8, 8, "accent")
      end
    end
  end

  if view.drag and view.drag.kind == "rectangle" then
    local d = view.drag
    local x, y = math.min(d.startX, d.x), math.min(d.startY, d.y)
    draw.outline(surface, x, y, math.abs(d.x - d.startX), math.abs(d.y - d.startY), 1, "accent")
  end

  local message = view.error or players.down
  if not view.file then
    message = project.folder() == "" and "No project is open." or "No node file is open."
  end
  if message then
    local font = draw.font("ui")
    local y = 12
    for line in (message .. "\n"):gmatch("(.-)\n") do
      draw.text(surface, font, line, 12, y, 13, view.file and "#e06c75" or "textDim")
      y = y + 18
    end
  end
end

-- The link's messages for the views

players.onView = function(kind, message, block)
  for _, view in pairs(views) do
    if kind == "down" then
      view.panel:redraw()
    elseif view.id == message.view then
      if kind == "frame" then
        if view.image then
          local iw, ih = view.image:size()
          if iw ~= message.width or ih ~= message.height then
            view.image:free()
            view.image = nil
          end
        end
        if view.image then
          draw.setImagePixels(view.image, block)
        else
          view.image = draw.newImage(message.width, message.height, block)
        end
        local sent = players.views[view.id]
        -- The frame was drawn from where the view was when the player last heard of it.
        view.frame = {
          x = sent and sent.x or view.x, y = sent and sent.y or view.y, zoom = (sent and sent.zoom or view.zoom) / view.scale,
          width = message.width / view.scale, height = message.height / view.scale,
        }
        view.error = nil
        if view.visible then
          view.fresh = true
          view.panel:redraw()
        else
          players.shown(view.id)
        end
      elseif kind == "bounds" then
        view.nodes = message.nodes or {}
        view.byPath = {}
        for _, node in ipairs(view.nodes) do
          view.byPath[node.path] = node
        end
        view.panel:redraw()
      elseif kind == "error" then
        view.error = tostring(message.message)
        view.nodes, view.byPath, view.image = {}, {}, nil
        view.panel:redraw()
      end
    end
  end
end

-- Dragging the chosen nodes with the tool

local function snap(value)
  if project.setting("snap") then
    local grid = project.setting("grid") or 32
    return math.floor(value / grid + 0.5) * grid
  end
  return value
end

local function startToolDrag(view, sx, sy)
  local tree = project.tree(view.file)
  local nodes = {}
  for _, path in ipairs(view.chosen) do
    local node, placed = tree.index[path], view.byPath[path]
    -- A node whose parent is dragged too moves with it.
    local carried = false
    local parent = node and node.parent
    while parent do
      carried = carried or isChosen(view, parent.path)
      parent = parent.parent
    end
    if node and placed and not carried then
      local parentPlace = placed.parent and view.byPath[placed.parent] and view.byPath[placed.parent].place or IDENTITY
      nodes[#nodes + 1] = {
        path = path, posX = node.posX, posY = node.posY, rot = node.rot, sclX = node.sclX, sclY = node.sclY,
        parentPlace = parentPlace, originX = placed.place[5], originY = placed.place[6],
      }
    end
  end
  local wx, wy = toWorld(view, sx, sy)
  view.drag = { kind = "tool", tool = project.tool(), nodes = nodes, startX = wx, startY = wy, fields = {} }
end

local function toolDrag(view, sx, sy)
  local d = view.drag
  local wx, wy = toWorld(view, sx, sy)
  for _, n in ipairs(d.nodes) do
    local fields = {}
    if d.tool == "move" then
      -- The pointer's move in the world, as the node's parent sees it.
      local p = n.parentPlace
      local fromX, fromY = worldToNode({ p[1], p[2], p[3], p[4], 0, 0 }, d.startX, d.startY)
      local toX, toY = worldToNode({ p[1], p[2], p[3], p[4], 0, 0 }, wx, wy)
      fields.posX, fields.posY = snap(n.posX + toX - fromX), snap(n.posY + toY - fromY)
    elseif d.tool == "turn" then
      -- Lua 5.5's math.atan takes both, as LuaJIT's math.atan2 does.
      ---@diagnostic disable-next-line: redundant-parameter
      local from = math.atan(d.startY - n.originY, d.startX - n.originX)
      ---@diagnostic disable-next-line: redundant-parameter
      local to = math.atan(wy - n.originY, wx - n.originX)
      fields.rot = n.rot + to - from
    else
      local from = math.sqrt((d.startX - n.originX) ^ 2 + (d.startY - n.originY) ^ 2)
      local to = math.sqrt((wx - n.originX) ^ 2 + (wy - n.originY) ^ 2)
      local factor = from > 0 and to / from or 1
      fields.sclX, fields.sclY = n.sclX * factor, n.sclY * factor
    end
    d.fields[n.path] = fields
    players.change(view.file, n.path, fields)
  end
end

-- Drops: an image makes a node with a sprite of it, and a node file an instance (DESIGN 13.3).
local function drop(view, event)
  if not view.file or type(event.value) ~= "table" then
    return
  end
  local folder = project.folder()
  local tree = project.tree(view.file)
  if not tree.first then
    return
  end
  local first = view.byPath[tree.first.path]
  local wx, wy = toWorld(view, event.x / view.scale, event.y / view.scale)
  local x, y = worldToNode(first and first.place or IDENTITY, wx, wy)
  x, y = snap(math.floor(x + 0.5)), snap(math.floor(y + 0.5))
  local made = {}
  for _, path in ipairs(event.value) do
    path = tostring(path):gsub("\\", "/")
    if path:sub(1, #folder) == folder then
      local inside = path:sub(#folder + 1)
      local ending = (inside:match("%.(%w+)$") or ""):lower()
      local id, message
      if inside:match("^nodes/.+%.lua$") then
        id, message = project.addInstance(view.file, tree.first.path, inside, x, y)
      elseif IMAGES[ending] then
        local name = inside:match("([^/]*)%.%w+$")
        id = project.addNode(view.file, tree.first.path, {
          name = name:sub(1, 1):upper() .. name:sub(2),
          posX = x ~= 0 and x or nil, posY = y ~= 0 and y or nil,
          components = { onlr = { sprite = { image = inside } } },
        })
      end
      if message then
        console.add(message, "error")
      end
      made[#made + 1] = id
    end
  end
  if #made > 0 then
    choose(view, made)
  end
end

local function pointer(view, event)
  local x, y = event.x / view.scale, event.y / view.scale
  if event.type == "pointerDown" then
    if event.button == 2 or (event.button == 1 and event.alt) then
      view.drag = { kind = "pan", startX = x, startY = y, viewX = view.x, viewY = view.y }
    elseif event.button == 1 and view.file then
      local found = hits(view, x, y)
      local top = found[1]
      view.press = { x = x, y = y, found = found, shift = event.shift, wasChosen = top ~= nil and isChosen(view, top) }
      if top and not event.shift and not isChosen(view, top) then
        choose(view, { top })
      end
    end
  elseif event.type == "pointerMove" then
    local d, press = view.drag, view.press
    if press and not d and (math.abs(x - press.x) > 3 or math.abs(y - press.y) > 3) then
      if press.found[1] and not press.shift then
        startToolDrag(view, press.x, press.y)
      else
        view.drag = { kind = "rectangle", startX = press.x, startY = press.y, x = x, y = y, shift = press.shift }
      end
      d = view.drag
    end
    if d and d.kind == "pan" then
      view.x = d.viewX - (x - d.startX) / view.zoom
      view.y = d.viewY - (y - d.startY) / view.zoom
      sync(view)
    elseif d and d.kind == "tool" then
      toolDrag(view, x, y)
    elseif d and d.kind == "rectangle" then
      d.x, d.y = x, y
    end
    if d then
      view.panel:redraw()
    end
  elseif event.type == "pointerUp" then
    local d, press = view.drag, view.press
    view.drag, view.press = nil, nil
    if d and d.kind == "tool" then
      if next(d.fields) then
        local label = d.tool == "move" and "Move" or d.tool == "turn" and "Turn" or "Scale"
        project.setFields(view.file, d.fields, label)
      end
    elseif d and d.kind == "rectangle" then
      -- Every node whose place or bounds' middle is in the rectangle.
      local x1, y1 = math.min(d.startX, d.x), math.min(d.startY, d.y)
      local x2, y2 = math.max(d.startX, d.x), math.max(d.startY, d.y)
      local paths = d.shift and { table.unpack(view.chosen) } or {}
      for _, node in ipairs(view.nodes) do
        local cx, cy = 0, 0
        if node.rect then
          cx, cy = node.rect[1] + node.rect[3] / 2, node.rect[2] + node.rect[4] / 2
        end
        local sx, sy = toScreen(view, nodeToWorld(node, cx, cy))
        if sx >= x1 and sx <= x2 and sy >= y1 and sy <= y2 and not isChosen({ chosen = paths }, node.path) then
          paths[#paths + 1] = node.path
        end
      end
      choose(view, paths)
    elseif press and not d then
      local found = press.found
      if press.shift then
        -- Shift adds the node to the choice, or takes it out.
        local paths = {}
        local had = false
        for _, path in ipairs(view.chosen) do
          if path == found[1] then
            had = true
          else
            paths[#paths + 1] = path
          end
        end
        if found[1] and not had then
          paths[#paths + 1] = found[1]
        end
        choose(view, paths)
      elseif #found == 0 then
        choose(view, {})
      else
        -- Another click at the same place chooses the node under the chosen one.
        local last = view.lastClick
        local pick = found[1]
        if last and press.wasChosen and math.abs(last.x - x) <= 3 and math.abs(last.y - y) <= 3 then
          for i, path in ipairs(found) do
            if path == last.path then
              pick = found[i % #found + 1]
            end
          end
        end
        view.lastClick = { x = x, y = y, path = pick }
        choose(view, { pick })
      end
    end
    view.panel:redraw()
  elseif event.type == "wheel" then
    -- The wheel zooms around the pointer.
    local wx, wy = toWorld(view, x, y)
    local factor = (event.scrollY or 0) > 0 and 1.25 or 0.8
    view.zoom = math.max(0.05, math.min(32, view.zoom * factor))
    view.x, view.y = wx - x / view.zoom, wy - y / view.zoom
    sync(view)
    view.panel:redraw()
  end
end

ecs.panel.registerType({
  name = "view",
  title = "Node view",
  stateVersion = STATE_VERSION,
  create = function(panel, saved, version)
    nextId = nextId + 1
    ---@type onlr_player.View
    local view = {
      panel = panel, id = nextId, x = -40, y = -40, zoom = 1, width = 0, height = 0, scale = 1, chosen = {},
      fresh = false, visible = true, nodes = {}, byPath = {},
    }
    if version == STATE_VERSION and type(saved) == "table" then
      view.file = saved.file
      view.x, view.y, view.zoom = saved.x or view.x, saved.y or view.y, saved.zoom or 1
    end
    if view.file and not project.file(view.file) then
      view.file = nil
    end
    if not view.file and project.folder() ~= "" and next(views) == nil then
      view.file = project.manifest() and project.manifest().startNode
    end
    views[panel] = view
    panel:acceptDrops({ "file-list" })
    title(view)
    return view
  end,
  draw = drawView,
  event = function(view, event)
    local kind = event.type
    if kind == "focused" then
      focused = view
      if view.file then
        project.choose(view.file, view.chosen)
      end
    elseif kind == "shown" then
      view.visible = true
    elseif kind == "hidden" then
      view.visible = false
    elseif kind == "drop" then
      drop(view, event)
    elseif kind == "pointerDown" or kind == "pointerMove" or kind == "pointerUp" or kind == "wheel" then
      pointer(view, event)
    end
  end,
  saveState = function(view)
    return { file = view.file, x = view.x, y = view.y, zoom = view.zoom }
  end,
  save = function(view)
    if view.file and not project.saveFile(view.file) then
      return nil, view.file .. " is not saved"
    end
    return true
  end,
  destroy = function(view)
    players.setView(view.id, nil)
    if view.image then
      view.image:free()
    end
    if focused == view then
      focused = nil
    end
    views[view.panel] = nil
  end,
})

-- The project's events

ecs.event.subscribe("onlr_project.opened", function()
  console.setFolder(project.folder())
  players.restartEdit()
  local manifest = project.manifest()
  for _, view in pairs(views) do
    if not view.file or not project.file(view.file) then
      show(view, nil)
    end
  end
  -- The start node opens in the first node view that shows no file.
  local start = manifest and manifest.startNode
  if start and project.file(start) and not viewOf(start) then
    for _, view in pairs(views) do
      if not view.file then
        show(view, start)
        project.choose(start, {})
        break
      end
    end
  end
end)

ecs.event.subscribe("onlr_project.closed", function()
  players.stop()
  players.stopEdit()
  for _, view in pairs(views) do
    show(view, nil)
  end
end)

ecs.event.subscribe("onlr_project.changed", function(_, value)
  players.filesChanged()
  for _, view in pairs(views) do
    if view.file and not project.file(view.file).data and not project.file(view.file).error then
      show(view, nil)
    end
    title(view)
  end
  -- Undoing or redoing a change of a file that no node view shows opens a view of it (DESIGN 13.6).
  if value and value.history then
    for _, path in ipairs(value.files) do
      local file = project.file(path)
      if file and file.kind == "node" and file.data and file.dirty and not viewOf(path) then
        openFile(path)
      end
    end
  end
end)

ecs.event.subscribe("onlr_project.saved", function()
  for _, view in pairs(views) do
    title(view)
  end
end)

ecs.event.subscribe("onlr_project.chosen", function(_, chosen)
  for _, view in pairs(views) do
    if view.file == chosen.file then
      view.chosen = chosen.paths
      sync(view)
      view.panel:redraw()
    end
  end
end)

for _, name in ipairs({ "onlr_project.tool", "onlr_project.settings" }) do
  ecs.event.subscribe(name, function()
    for _, view in pairs(views) do
      view.panel:redraw()
    end
  end)
end

ecs.event.subscribe("onlr_project.disk", function(_, value)
  if value.kind == "code" then
    -- A script or the manifest changed: the edit player starts again, so nothing of the old code stays in it (DESIGN 12.5).
    players.restartEdit()
  elseif value.kind == "asset" then
    players.reload(value.path)
  end
end)

-- The functions

local function current()
  if focused and views[focused.panel] and focused.file then
    return focused
  end
  local chosen = project.chosen()
  return chosen.file and viewOf(chosen.file) or nil
end

local function onChosen(fn)
  return function()
    local chosen = project.chosen()
    if chosen.file and #chosen.paths > 0 then
      fn(chosen.file, chosen.paths)
    end
  end
end

local function say(_, message)
  if message then
    console.add(message, "warn")
  end
end

ecs.service.register({
  openFile = { sig = "void(string file)", doc = "Open a node file in a node view", fn = openFile },
  focusedFile = { sig = "string()", doc = "The node file of the node view that has the focus, or an empty text", fn = function()
    local view = current()
    return view and view.file or ""
  end },
  play = { sig = "void()", doc = "Play", fn = function()
    players.play()
  end },
  playFile = { sig = "void()", doc = "Play This File", fn = function()
    local view = current()
    players.play(view and view.file)
  end },
  pause = { sig = "void()", doc = "Pause or resume", fn = function()
    players.pause(not players.running.paused)
  end },
  step = { sig = "void()", doc = "Step", fn = players.step },
  stop = { sig = "void()", doc = "Stop", fn = players.stop },
  restart = { sig = "void()", doc = "Start the edit player again", fn = players.restartEdit },
  running = { sig = "value()", doc = "The running game: whether it plays and is paused, its tree and the watched values", fn = function()
    return players.running
  end },
  watch = { sig = "void(bool tree, value nodes)", doc = "Ask the running game for its tree, and for the values of nodes", fn = players.watch },
  set = { sig = "void(value message)", doc = "Set a value of a running node", fn = players.set },
  editReady = { sig = "bool()", doc = "Whether the edit player runs", fn = players.editReady },
  view = { sig = "value(string file)", doc = "The node view of a node file: its place, zoom and the nodes' bounds", fn = viewOf },
  delete = { sig = "void()", doc = "Delete the chosen nodes", fn = onChosen(function(file, paths)
    say(project.deleteNodes(file, paths))
  end) },
  duplicate = { sig = "void()", doc = "Duplicate the chosen nodes", fn = onChosen(function(file, paths)
    local made = project.duplicate(file, paths)
    if #made > 0 then
      project.choose(file, made)
    end
  end) },
  copy = { sig = "void()", doc = "Copy the chosen nodes", fn = onChosen(project.copyNodes) },
  paste = { sig = "void()", doc = "Paste the copied nodes", fn = function()
    local chosen = project.chosen()
    if chosen.file then
      local made = project.paste(chosen.file, chosen.paths[1] or "")
      if #made > 0 then
        project.choose(chosen.file, made)
      end
    end
  end },
  toolMove = { sig = "void()", doc = "The move tool", fn = function()
    project.setTool("move")
  end },
  toolTurn = { sig = "void()", doc = "The turn tool", fn = function()
    project.setTool("turn")
  end },
  toolScale = { sig = "void()", doc = "The scale tool", fn = function()
    project.setTool("scale")
  end },
})

for key, name in pairs({
  ["Delete"] = "onlr_player.delete", ["Ctrl+D"] = "onlr_player.duplicate", ["Ctrl+C"] = "onlr_player.copy",
  ["Ctrl+V"] = "onlr_player.paste", ["Ctrl+Z"] = "onlr_project.undo", ["Ctrl+Y"] = "onlr_project.redo",
  ["Ctrl+Shift+Z"] = "onlr_project.redo", ["Ctrl+S"] = "onlr_project.save", ["F5"] = "onlr_player.play",
  ["F6"] = "onlr_player.playFile", ["F7"] = "onlr_player.pause", ["F8"] = "onlr_player.step",
  ["Shift+F5"] = "onlr_player.stop", ["W"] = "onlr_player.toolMove", ["E"] = "onlr_player.toolTurn",
  ["R"] = "onlr_player.toolScale",
}) do
  ecs.key.bind("onlr_player.view", key, name)
end

if project.folder() ~= "" then
  console.setFolder(project.folder())
  players.ensureEdit()
end
