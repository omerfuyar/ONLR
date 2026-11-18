-- The node view (DESIGN 13.3), and the functions Play, Play This File, Pause, Step and Stop.
-- A node view shows a view of a node file: the preview draws the nodes into a frame, and the panel draws over it
-- the grid, the window's frame, the outlines of the chosen nodes and the handles of the tool (DESIGN 12.3).
-- It draws with gpu: the frame is a texture on the graphics card, which each frame replaces, so drawing the panel copies no pixels (DESIGN 12.4).

local ecs = require("ecs")
local draw = require("draw")
local gpu = require("gpu")
local project = require("project")
local console = require("console")
local runners = require("runners")
local ui = require("ui")

local STATE_VERSION = 1
local IMAGES = { png = true, jpg = true, jpeg = true, bmp = true, tga = true }

---A node view.
---@class onlr.editor.View
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
---@field image gpu.texture? the last frame
---@field frame table? where the last frame was drawn from: x, y, zoom, width and height
---@field visible boolean
---@field nodes table[] the nodes' bounds, in the order of drawing
---@field byPath table<string, table>
---@field error string? why the view shows no nodes
---@field drag table? what the pointer drags
---@field lastClick table? where the last click was, and which node it chose

local views = {} ---@type table<ecs.Panel, onlr.editor.View>
local nextId = 0
local focused ---@type onlr.editor.View? the node view that had the focus last

local function sync(view)
  if not view.file or view.width < 1 then
    return
  end
  runners.setView(view.id, {
    path = view.file, x = view.x, y = view.y, zoom = view.zoom * view.scale,
    width = math.floor(view.width * view.scale), height = math.floor(view.height * view.scale), chosen = view.chosen,
  })
end

local function title(view)
  local file = view.file and project.file(view.file)
  view.panel.title = view.file and view.file:match("[^/]*$") or "Node view"
  view.panel.unsaved = file ~= nil and file.dirty
end

-- Frees the view's last frame, which the graphics card holds.
local function dropImage(view)
  if view.image then
    view.image:free()
    view.image = nil
  end
end

local function show(view, file)
  view.file = file
  view.chosen = {}
  dropImage(view)
  view.nodes, view.byPath, view.error = {}, {}, nil
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
  ecs.layout.open("onlr.view", { file = file }, target, "center")
end

-- Places

local function toScreen(view, wx, wy)
  return (wx - view.x) * view.zoom, (wy - view.y) * view.zoom
end

local function toWorld(view, sx, sy)
  return sx / view.zoom + view.x, sy / view.zoom + view.y
end

-- The move tool's arrows: their length on the screen, and their colours, as Unity's.
local HANDLE = 60
local AXIS_X, AXIS_Y = "#e06c75", "#98c379"
-- The square between the arrows: where it starts from the node's place, and its size.
local SQUARE, SQUARE_SIZE = 10, 18

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

-- The move tool's handle under a point of the panel: the chosen node's path and the axis, "x" or "y" for an arrow and "both" for the
-- square between them, or nil.
local function handleAt(view, sx, sy)
  if project.tool() ~= "move" then
    return nil
  end
  for _, path in ipairs(view.chosen) do
    local node = view.byPath[path]
    if node then
      local x, y = toScreen(view, node.place[5], node.place[6])
      if sx >= x + SQUARE and sx <= x + SQUARE + SQUARE_SIZE and sy >= y + SQUARE and sy <= y + SQUARE + SQUARE_SIZE then
        return path, "both"
      elseif math.abs(sy - y) <= 6 and sx >= x + 8 and sx <= x + HANDLE + 4 then
        return path, "x"
      elseif math.abs(sx - x) <= 6 and sy >= y + 8 and sy <= y + HANDLE + 4 then
        return path, "y"
      end
    end
  end
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

-- A rectangle's edges, inside it, as draw.outline draws them; gpu fills only.
local function frameRect(surface, x, y, w, h, thickness, color)
  gpu.fill(surface, x, y, w, thickness, color)
  gpu.fill(surface, x, y + h - thickness, w, thickness, color)
  gpu.fill(surface, x, y + thickness, thickness, h - thickness * 2, color)
  gpu.fill(surface, x + w - thickness, y + thickness, thickness, h - thickness * 2, color)
end

-- A circle's edge, of 32 lines.
local function circle(surface, x, y, radius, thickness, color)
  local step = math.pi * 2 / 32
  for i = 0, 31 do
    local a, b = i * step, (i + 1) * step
    gpu.line(surface, x + math.cos(a) * radius, y + math.sin(a) * radius, x + math.cos(b) * radius, y + math.sin(b) * radius, thickness, color)
  end
end

local function outline(surface, view, node, color, thickness)
  local r = node.rect
  local corners = { { r[1], r[2] }, { r[1] + r[3], r[2] }, { r[1] + r[3], r[2] + r[4] }, { r[1], r[2] + r[4] } }
  for i = 1, 4 do
    local a, b = corners[i], corners[i % 4 + 1]
    local x1, y1 = toScreen(view, nodeToWorld(node, a[1], a[2]))
    local x2, y2 = toScreen(view, nodeToWorld(node, b[1], b[2]))
    gpu.line(surface, x1, y1, x2, y2, thickness, color)
  end
end

local function drawView(view, surface)
  local w, h = surface.width / surface.scale, surface.height / surface.scale
  if w ~= view.width or h ~= view.height or surface.scale ~= view.scale then
    view.width, view.height, view.scale = w, h, surface.scale
    sync(view)
  end
  gpu.clear(surface, "background")

  -- The panel draws a whole picture only: the grid, the outlines and the handles from the place and zoom of the frame
  -- that it has, not from where the view wants to be, so nothing shows that the frame does not hold yet (DESIGN 12.4).
  local wantX, wantY, wantZoom = view.x, view.y, view.zoom
  if view.file and view.image and view.frame and not view.error and not runners.down then
    view.x, view.y, view.zoom = view.frame.x, view.frame.y, view.frame.zoom
  end

  -- The grid, when its lines are far enough apart to be told from each other.
  local grid = project.setting("grid") or 32
  local step = grid * view.zoom
  if step >= 8 then
    local fx = (-view.x * view.zoom) % step
    for x = fx, w, step do
      gpu.fill(surface, x, 0, 1, h, "#ffffff10")
    end
    local fy = (-view.y * view.zoom) % step
    for y = fy, h, step do
      gpu.fill(surface, 0, y, w, 1, "#ffffff10")
    end
  end

  -- The last frame, placed by where it was drawn from, so it follows the view until the next one comes.
  if view.image and view.frame then
    local f = view.frame
    local ratio = view.zoom / f.zoom
    local x, y = toScreen(view, f.x, f.y)
    gpu.image(surface, view.image, x, y, f.width * ratio, f.height * ratio)
  end

  -- The window's frame: where the nodes that no camera holds show, such as a score, named above its top left (DESIGN 13.3).
  local manifest = project.manifest()
  local window = manifest and manifest.window or {}
  local x0, y0 = toScreen(view, 0, 0)
  frameRect(surface, x0, y0, (window.width or 800) * view.zoom, (window.height or 600) * view.zoom, 1, "textDim")
  gpu.text(surface, draw.font("ui"), ("Window %d × %d"):format(window.width or 800, window.height or 600), x0, y0 - 16, 12, "textDim")

  for _, node in ipairs(view.nodes) do
    local chosen = isChosen(view, node.path)
    local color = node.errors and "#e06c75" or chosen and "accent" or nil
    if node.rect then
      if color then
        outline(surface, view, node, color, chosen and 2 or 1)
      end
    else
      local x, y = toScreen(view, node.place[5], node.place[6])
      frameRect(surface, x - 4, y - 4, 8, 8, 1, color or "textDim")
    end
  end

  -- The tool's handles, on each chosen node's place.
  local tool = project.tool()
  for _, path in ipairs(view.chosen) do
    local node = view.byPath[path]
    if node then
      local x, y = toScreen(view, node.place[5], node.place[6])
      if tool == "move" then
        -- the arrows along the world's x and y, which a drag moves along their axis alone, as Unity's do; y grows down, as in LÖVE
        local axis = view.drag and view.drag.kind == "tool" and view.drag.axis
        local xColor, yColor = axis == "x" and "accent" or AXIS_X, axis == "y" and "accent" or AXIS_Y
        gpu.line(surface, x, y, x + HANDLE, y, 2, xColor)
        gpu.line(surface, x + HANDLE, y, x + HANDLE - 8, y - 5, 2, xColor)
        gpu.line(surface, x + HANDLE, y, x + HANDLE - 8, y + 5, 2, xColor)
        gpu.line(surface, x, y, x, y + HANDLE, 2, yColor)
        gpu.line(surface, x, y + HANDLE, x - 5, y + HANDLE - 8, 2, yColor)
        gpu.line(surface, x, y + HANDLE, x + 5, y + HANDLE - 8, 2, yColor)
        -- the square between them moves on both axes, above whatever node is under it
        if axis == "both" then
          gpu.fill(surface, x + SQUARE, y + SQUARE, SQUARE_SIZE, SQUARE_SIZE, "accent")
        end
        frameRect(surface, x + SQUARE, y + SQUARE, SQUARE_SIZE, SQUARE_SIZE, 2, "accent")
      elseif tool == "turn" then
        circle(surface, x, y, 14, 2, "accent")
        local ax, ay = toScreen(view, nodeToWorld(node, 1, 0))
        local length = math.max(1e-6, math.sqrt((ax - x) ^ 2 + (ay - y) ^ 2))
        gpu.line(surface, x, y, x + (ax - x) / length * 14, y + (ay - y) / length * 14, 2, "accent")
      else
        frameRect(surface, x - 12, y - 12, 24, 24, 2, "accent")
        gpu.fill(surface, x + 8, y + 8, 8, 8, "accent")
      end
    end
  end

  if view.drag and view.drag.kind == "rectangle" then
    local d = view.drag
    local x, y = math.min(d.startX, d.x), math.min(d.startY, d.y)
    frameRect(surface, x, y, math.abs(d.x - d.startX), math.abs(d.y - d.startY), 1, "accent")
  end

  view.x, view.y, view.zoom = wantX, wantY, wantZoom

  local message = view.error or runners.down
  if not view.file then
    message = project.folder() == "" and "No project is open." or "No node file is open."
  end
  if message then
    local font = draw.font("ui")
    local y = 12
    for line in (message .. "\n"):gmatch("(.-)\n") do
      gpu.text(surface, font, line, 12, y, 13, view.file and "#e06c75" or "textDim")
      y = y + 18
    end
  end
end

-- The link's messages for the views

runners.onView = function(kind, message, block)
  for _, view in pairs(views) do
    if kind == "down" then
      view.panel:redraw()
    elseif view.id == message.view then
      if kind == "frame" then
        if view.image then
          local iw, ih = view.image:size()
          if iw ~= message.width or ih ~= message.height then
            dropImage(view)
          end
        end
        local failure
        if view.image then
          local _, why = view.image:update(block)
          failure = why
        else
          view.image, failure = gpu.texture(message.width, message.height, block)
        end
        -- Without a graphics card that gpu can use, the view says so in place of the nodes.
        if failure and failure ~= "" then
          view.error = "The node view cannot show the frame: " .. failure
          view.panel:redraw()
          return
        end
        -- The frame says where it was drawn from, which is not where the view is now while the user moves it.
        view.frame = {
          x = message.x, y = message.y, zoom = message.zoom / view.scale,
          width = message.width / view.scale, height = message.height / view.scale,
        }
        view.error = nil
        view.panel:redraw()
      elseif kind == "bounds" then
        view.nodes = message.nodes or {}
        view.byPath = {}
        for _, node in ipairs(view.nodes) do
          view.byPath[node.path] = node
        end
        view.panel:redraw()
      elseif kind == "error" then
        view.error = tostring(message.message)
        dropImage(view)
        view.nodes, view.byPath = {}, {}
        view.panel:redraw()
      end
    end
  end
end

-- Dragging the chosen nodes with the tool

-- Snaps a value to the grid while snapping is on. Ctrl held in a drag flips it, as in Unity.
local function snap(value, flip)
  local on = project.setting("snap") == true
  if flip then
    on = not on
  end
  if on then
    local grid = project.setting("grid") or 32
    return math.floor(value / grid + 0.5) * grid
  end
  return value
end

local function startToolDrag(view, sx, sy, lead)
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
  -- Many nodes turn and scale as one, around the middle of their places, or each around its own place:
  -- the pivot, a setting of the project (DESIGN 13.3).
  local midX, midY = 0, 0
  for _, n in ipairs(nodes) do
    midX, midY = midX + n.originX / #nodes, midY + n.originY / #nodes
  end
  -- The pointer's turn and distance are seen from the middle, or, with each node's own pivot, from the place of the node
  -- that the drag started on, so every node turns and scales by the same amount.
  local own = project.setting("pivot") == "own"
  local centerX, centerY = midX, midY
  for _, n in ipairs(nodes) do
    n.pivotX, n.pivotY = own and n.originX or midX, own and n.originY or midY
    if own and n.path == lead then
      centerX, centerY = n.originX, n.originY
    end
  end
  local wx, wy = toWorld(view, sx, sy)
  view.drag = { kind = "tool", tool = project.tool(), nodes = nodes, startX = wx, startY = wy, centerX = centerX, centerY = centerY, fields = {} }
end

local TURN_STEP = math.pi / 12

local function toolDrag(view, sx, sy, ctrl)
  local d = view.drag
  local wx, wy = toWorld(view, sx, sy)
  local cx, cy = d.centerX, d.centerY
  -- Lua 5.5's math.atan takes both, as LuaJIT's math.atan2 does.
  ---@diagnostic disable-next-line: redundant-parameter
  local angle = math.atan(wy - cy, wx - cx) - math.atan(d.startY - cy, d.startX - cx)
  -- With Ctrl, a turn goes in steps of 15 degrees.
  if ctrl then
    angle = math.floor(angle / TURN_STEP + 0.5) * TURN_STEP
  end
  local from = math.sqrt((d.startX - cx) ^ 2 + (d.startY - cy) ^ 2)
  local factor = from > 0 and math.sqrt((wx - cx) ^ 2 + (wy - cy) ^ 2) / from or 1
  for _, n in ipairs(d.nodes) do
    local fields = {}
    local p = n.parentPlace
    local linear = { p[1], p[2], p[3], p[4], 0, 0 }
    -- Where the node's place goes in the world, from the pivot that it turns and scales around.
    local offX, offY = n.originX - n.pivotX, n.originY - n.pivotY
    local toX, toY
    if d.tool == "move" then
      toX, toY = d.axis ~= "y" and wx - d.startX or 0, d.axis ~= "x" and wy - d.startY or 0
    elseif d.tool == "turn" then
      local cos, sin = math.cos(angle), math.sin(angle)
      toX, toY = offX * cos - offY * sin - offX, offX * sin + offY * cos - offY
      fields.rot = n.rot + angle
    else
      toX, toY = offX * factor - offX, offY * factor - offY
      fields.sclX, fields.sclY = n.sclX * factor, n.sclY * factor
    end
    -- The move in the world, as the node's parent sees it.
    local moveX, moveY = worldToNode(linear, toX, toY)
    if d.tool == "move" and d.axis then
      -- with a handle, only what moves snaps, so a node moved along one axis keeps its place on the other
      fields.posX = moveX ~= 0 and snap(n.posX + moveX, ctrl) or n.posX
      fields.posY = moveY ~= 0 and snap(n.posY + moveY, ctrl) or n.posY
    elseif d.tool == "move" then
      fields.posX, fields.posY = snap(n.posX + moveX, ctrl), snap(n.posY + moveY, ctrl)
    elseif offX ~= 0 or offY ~= 0 then
      fields.posX, fields.posY = n.posX + moveX, n.posY + moveY
    end
    d.fields[n.path] = fields
    runners.change(view.file, n.path, fields)
  end
end

-- Drops: an image makes a node with a sprite of it, and a node file an instance (DESIGN 13.3).
local function drop(view, event)
  if not view.file or type(event.value) ~= "table" then
    return
  end
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
    -- a file from outside the project is copied in first, after asking (DESIGN 13.4)
    local inside = project.bringIn(path)
    if inside then
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

-- The menu of a right click (DESIGN 13.3): about the chosen nodes when the click was on one, which it chose when it was not chosen,
-- or else about the point. ui.menu takes a place in the units of ui's layout, which on a panel that ui does not draw are its pixels.
local functions
-- Moves and zooms the view so that the chosen nodes fill it, or every node when none is chosen, as Unity's F does.
-- A lone node without bounds is centred at the zoom the view has.
local function frame(view)
  local minX, minY, maxX, maxY
  local function add(x, y)
    minX, maxX = math.min(minX or x, x), math.max(maxX or x, x)
    minY, maxY = math.min(minY or y, y), math.max(maxY or y, y)
  end
  local all = #view.chosen == 0
  for _, node in ipairs(view.nodes) do
    if all or isChosen(view, node.path) then
      local r = node.rect
      if r then
        add(nodeToWorld(node, r[1], r[2]))
        add(nodeToWorld(node, r[1] + r[3], r[2]))
        add(nodeToWorld(node, r[1], r[2] + r[4]))
        add(nodeToWorld(node, r[1] + r[3], r[2] + r[4]))
      else
        add(node.place[5], node.place[6])
      end
    end
  end
  if not minX or view.width < 1 then
    return
  end
  local w, h = maxX - minX, maxY - minY
  if w > 0 or h > 0 then
    -- A margin of a fifth of the view on each side.
    local zoom = math.min(view.width / math.max(w, 1e-3), view.height / math.max(h, 1e-3)) * 0.6
    view.zoom = math.max(0.05, math.min(32, zoom))
  end
  view.x = (minX + maxX) / 2 - view.width / 2 / view.zoom
  view.y = (minY + maxY) / 2 - view.height / 2 / view.zoom
  sync(view)
  view.panel:redraw()
end

local function menu(view, event, x, y)
  local found = hits(view, x, y)
  local wx, wy = toWorld(view, x, y)
  if #found == 0 then
    local first = view.byPath[project.tree(view.file).first.path]
    local nx, ny = worldToNode(first and first.place or IDENTITY, wx, wy)
    nx, ny = snap(math.floor(nx + 0.5)), snap(math.floor(ny + 0.5))
    ui.menu(view.panel, event.x, event.y, {
      { label = "Add node here", onClick = function()
        local id = project.addNode(view.file, project.tree(view.file).first.path, { posX = nx ~= 0 and nx or nil, posY = ny ~= 0 and ny or nil })
        if id then
          choose(view, { id })
        end
      end },
      { label = "Paste", keys = "Ctrl+V", onClick = functions.pasteChosen.fn },
      { line = true },
      { label = "Frame all", keys = "F", onClick = function()
        frame(view)
      end },
    })
    return
  end
  ui.menu(view.panel, event.x, event.y, {
    { label = "Duplicate", keys = "Ctrl+D", onClick = functions.duplicateChosen.fn },
    { label = "Delete", keys = "Delete", onClick = functions.deleteChosen.fn },
    { line = true },
    { label = "Copy", keys = "Ctrl+C", onClick = functions.copyChosen.fn },
    { label = "Paste", keys = "Ctrl+V", onClick = functions.pasteChosen.fn },
    { line = true },
    { label = "Frame chosen", keys = "F", onClick = function()
      frame(view)
    end },
  })
end

local function pointer(view, event)
  local x, y = event.x / view.scale, event.y / view.scale
  if event.type == "pointerDown" and event.button == 3 and view.file then
    local top = hits(view, x, y)[1]
    if top and not isChosen(view, top) then
      choose(view, { top })
    end
  elseif event.type == "pointerUp" and event.button == 3 and view.file and not view.drag then
    menu(view, event, x, y)
  elseif event.type == "pointerDown" then
    if event.button == 2 or (event.button == 1 and event.alt) then
      view.drag = { kind = "pan", startX = x, startY = y, viewX = view.x, viewY = view.y }
    elseif event.button == 1 and view.file and handleAt(view, x, y) then
      -- a handle of the move tool is above the nodes, and drags the chosen nodes along its axis, or both
      local path, axis = handleAt(view, x, y)
      view.press = { x = x, y = y, found = { path }, axis = axis, wasChosen = true }
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
        startToolDrag(view, press.x, press.y, press.found[1])
        view.drag.axis = press.axis
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
      toolDrag(view, x, y, event.ctrl)
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
    elseif press and not d and not press.axis then
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
  surface = "gpu",
  stateVersion = STATE_VERSION,
  create = function(panel, saved, version)
    nextId = nextId + 1
    ---@type onlr.editor.View
    local view = {
      panel = panel, id = nextId, x = -40, y = -40, zoom = 1, width = 0, height = 0, scale = 1, chosen = {},
      visible = true, nodes = {}, byPath = {},
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
        project.choose(view.file, view.chosen, true)
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
    ui.forget(view.panel)
    runners.setView(view.id, nil)
    dropImage(view)
    if focused == view then
      focused = nil
    end
    views[view.panel] = nil
  end,
})

-- The project's events

ecs.event.subscribe("onlr.opened", function()
  console.setFolder(project.folder())
  runners.restartPreview()
  local manifest = project.manifest()
  for _, view in pairs(views) do
    if not view.file or not project.file(view.file) then
      show(view, nil)
    end
  end
  -- The start node opens: in a node view that shows no file, or in a new one.
  local start = manifest and manifest.startNode
  if start and project.file(start) and not viewOf(start) then
    openFile(start)
    project.choose(start, {}, true)
  end
end)

ecs.event.subscribe("onlr.closed", function()
  runners.stop()
  runners.stopPreview()
  for _, view in pairs(views) do
    show(view, nil)
  end
end)

ecs.event.subscribe("onlr.changed", function(_, value)
  runners.filesChanged()
  for _, view in pairs(views) do
    -- A node view of a file that is gone shows no file.
    local file = view.file and project.file(view.file)
    if view.file and (not file or file.missing) then
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

-- A node view of a file that was renamed or moved shows it under its new path.
ecs.event.subscribe("onlr.renamed", function(_, value)
  for _, view in pairs(views) do
    if view.file and (view.file == value.from or view.file:sub(1, #value.from + 1) == value.from .. "/") then
      view.file = value.to .. view.file:sub(#value.from + 1)
      title(view)
      sync(view)
    end
  end
end)

ecs.event.subscribe("onlr.saved", function()
  for _, view in pairs(views) do
    title(view)
  end
end)

ecs.event.subscribe("onlr.chosen", function(_, chosen)
  for _, view in pairs(views) do
    if view.file == chosen.file then
      view.chosen = chosen.paths
      sync(view)
      view.panel:redraw()
    end
  end
end)

for _, name in ipairs({ "onlr.tool", "onlr.settings" }) do
  ecs.event.subscribe(name, function()
    for _, view in pairs(views) do
      view.panel:redraw()
    end
  end)
end

ecs.event.subscribe("onlr.disk", function(_, value)
  if value.kind == "code" then
    -- A script or the manifest changed: the preview starts again, so nothing of the old code stays in it (DESIGN 12.5).
    runners.restartPreview()
  elseif value.kind == "asset" then
    runners.reload(value.path)
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

functions = {
  openFile = { sig = "void(string file)", doc = "Open a node file in a node view", fn = openFile },
  focusedFile = { sig = "string()", doc = "The node file of the node view that has the focus, or an empty text", fn = function()
    local view = current()
    return view and view.file or ""
  end },
  play = { sig = "void()", doc = "Play", fn = function()
    runners.play()
  end },
  playFile = { sig = "void()", doc = "Play This File", fn = function()
    local view = current()
    runners.play(view and view.file)
  end },
  pause = { sig = "void()", doc = "Pause or resume", fn = function()
    runners.pause(not runners.running.paused)
  end },
  step = { sig = "void()", doc = "Step", fn = runners.step },
  stop = { sig = "void()", doc = "Stop", fn = runners.stop },
  restart = { sig = "void()", doc = "Start the preview again", fn = runners.restartPreview },
  running = { sig = "value()", doc = "The running game: whether it plays and is paused, its tree and the watched values", fn = function()
    return runners.running
  end },
  watch = { sig = "void(bool tree, value nodes)", doc = "Ask the running game for its tree, and for the values of nodes", fn = runners.watch },
  set = { sig = "void(value message)", doc = "Set a value of a running node", fn = runners.set },
  previewReady = { sig = "bool()", doc = "Whether the preview runs", fn = runners.previewReady },
  view = { sig = "value(string file)", doc = "The node view of a node file: its place, zoom and the nodes' bounds", fn = viewOf },
  deleteChosen = { sig = "void()", doc = "Delete the chosen nodes", fn = onChosen(function(file, paths)
    say(project.deleteNodes(file, paths))
  end) },
  duplicateChosen = { sig = "void()", doc = "Duplicate the chosen nodes", fn = onChosen(function(file, paths)
    local made = project.duplicate(file, paths)
    if #made > 0 then
      project.choose(file, made)
    end
  end) },
  copyChosen = { sig = "void()", doc = "Copy the chosen nodes", fn = onChosen(project.copyNodes) },
  pasteChosen = { sig = "void()", doc = "Paste the copied nodes", fn = function()
    local chosen = project.chosen()
    if chosen.file then
      local made = project.paste(chosen.file, chosen.paths[1] or "")
      if #made > 0 then
        project.choose(chosen.file, made)
      end
    end
  end },
  frame = { sig = "void()", doc = "Fit the node view to the chosen nodes, or to every node when none is chosen", fn = function()
    local view = current()
    if view then
      frame(view)
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
}

for key, name in pairs({
  ["Delete"] = "onlr.deleteChosen", ["Ctrl+D"] = "onlr.duplicateChosen", ["Ctrl+C"] = "onlr.copyChosen",
  ["Ctrl+V"] = "onlr.pasteChosen", ["Ctrl+Z"] = "onlr.undo", ["Ctrl+Y"] = "onlr.redo",
  ["Ctrl+Shift+Z"] = "onlr.redo", ["Ctrl+S"] = "onlr.save", ["F5"] = "onlr.play",
  ["F6"] = "onlr.playFile", ["F7"] = "onlr.pause", ["F8"] = "onlr.step",
  ["Shift+F5"] = "onlr.stop", ["W"] = "onlr.toolMove", ["E"] = "onlr.toolTurn",
  ["R"] = "onlr.toolScale", ["F"] = "onlr.frame",
}) do
  ecs.key.bind("onlr.view", key, name)
end

if project.folder() ~= "" then
  console.setFolder(project.folder())
  runners.ensurePreview()
end

-- The other parts call the functions themselves; init.lua registers them as the plugin's (DESIGN 13.1).
---@type table<string, any>
local part = { functions = functions }
for name, entry in pairs(functions) do
  part[name] = entry.fn
end
return part
