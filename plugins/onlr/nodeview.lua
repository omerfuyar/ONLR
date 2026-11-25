-- The node view (DESIGN 13.3), and the functions Play, Play This File, Pause, Step and Stop.
-- A node view shows a view of a node file: the preview draws the nodes into a frame, and the panel draws over it
-- the grid, the window's frame, the outlines of the chosen nodes and the handles of the tool (DESIGN 12.3).
-- It draws with gpu: the frame is a texture on the graphics card, which each frame replaces, so drawing the panel copies no pixels (DESIGN 12.4).

local ecs = require("ecs")
local draw = require("draw")
local gpu = require("gpu")
local project = require("project")
local format = require("format")
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
---@field lastDown table? where the Shape tool's last press was, for 0.4 seconds, so a second one there is a double click
---@field point onlr.editor.Handle? the point that the Shape tool clicked last, which Delete removes

local views = {} ---@type table<ecs.Panel, onlr.editor.View>
local nextId = 0
local focused ---@type onlr.editor.View? the node view that had the focus last

local NO_MARKS = {}

-- The eye and the lock (DESIGN 13.3): the nodes of a node file that the user hid in the node view, or locked against being chosen
-- there, kept in the project's settings by the file and the node's path. A mark holds for the nodes under the node too.
---@param kind "hidden"|"locked"
---@return table<string, boolean>
local function marks(kind, file)
  local all = project.setting(kind)
  return type(all) == "table" and type(all[file]) == "table" and all[file] or NO_MARKS
end

-- Whether a node of a view, or a node above it, has the mark. The answers for the view's nodes are kept, and made again
-- when the marks or the nodes change, so a draw and a click ask each node once, not each node's parents (DESIGN 13.3).
local function isMarked(view, kind, path)
  local set = marks(kind, view.file)
  view.marked = view.marked or {}
  local kept = view.marked[kind]
  if not kept or kept.set ~= set or kept.byPath ~= view.byPath then
    local answers = {}
    local function ask(at)
      local answer = answers[at]
      if answer == nil then
        local node = view.byPath[at]
        answer = set[at] == true or (node ~= nil and node.parent ~= nil and view.byPath[node.parent] ~= nil and ask(node.parent))
        answers[at] = answer
      end
      return answer
    end
    for _, node in ipairs(view.nodes) do
      ask(node.path)
    end
    kept = { set = set, byPath = view.byPath, answers = answers }
    view.marked[kind] = kept
  end
  local answer = kept.answers[path]
  if answer == nil then
    return set[path] == true
  end
  return answer
end

-- Marks the nodes, or takes the mark off when each has it already, as Unity's eye does for many.
local function toggleMarks(kind, file, paths)
  local all = format.copy(type(project.setting(kind)) == "table" and project.setting(kind) or {})
  local set = type(all[file]) == "table" and all[file] or {}
  local every = #paths > 0
  for _, path in ipairs(paths) do
    every = every and set[path] == true
  end
  for _, path in ipairs(paths) do
    set[path] = not every or nil
  end
  all[file] = next(set) and set or nil
  project.setSetting(kind, all)
end

-- Picking a node for a reference (DESIGN 13.4): the inspector's Pick button waits for the next click on a node, in a node view or in
-- the node hierarchy, which sets the reference in place of choosing the node.
---@class onlr.editor.Picking
---@field id string the inspector's row
---@field file string the node file whose nodes it takes
---@field label string the property's name, for the node view's line
---@field needs string? for a reference to a component, the type that the node must have
---@field set fun(path: string)
local picking ---@type onlr.editor.Picking?

local function redrawViews()
  for _, view in pairs(views) do
    view.panel:redraw()
  end
end

---@param p onlr.editor.Picking?
local function startPick(p)
  picking = p
  redrawViews()
  ecs.event.emit("onlr.picking", p and p.id or false)
end

-- Gives the waiting reference the node clicked; true when a pick was waiting, so the click chooses nothing.
local function pick(file, path)
  local p = picking
  if not p then
    return false
  end
  startPick(nil)
  local node = path and file == p.file and project.tree(file).index[path]
  if node and p.needs and not node.components[p.needs] then
    console.add(("The node %s has no component %s."):format(node.name or node.path, p.needs), "warn", nil, "onlr")
  elseif node then
    p.set(path)
  elseif path then
    console.add("A reference names a node of its own node file.", "warn", nil, "onlr")
  end
  return true
end

local function hiddenList(file)
  local list = {}
  for path in pairs(marks("hidden", file)) do
    list[#list + 1] = path
  end
  table.sort(list)
  return list
end

local function sync(view)
  if not view.file or view.width < 1 then
    return
  end
  runners.setView(view.id, {
    path = view.file, x = view.x, y = view.y, zoom = view.zoom * view.scale,
    width = math.floor(view.width * view.scale), height = math.floor(view.height * view.scale), chosen = view.chosen,
    hidden = hiddenList(view.file),
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

---Opens a node file in a node view, or shows the view that has it. With paths, the view chooses those nodes, which it keeps when it
---gets the focus.
---@param file string
---@param paths string[]?
local function openFile(file, paths)
  local view = viewOf(file)
  if not view then
    -- A node view that shows no file takes it.
    for _, other in pairs(views) do
      if not other.file and not view then
        show(other, file)
        view = other
      end
    end
  end
  if view then
    if paths then
      view.chosen = paths
      project.choose(file, paths)
    end
    ecs.layout.focus(view.panel)
    return
  end
  local target = focused and views[focused.panel] and focused.panel or next(views)
  ecs.layout.open("onlr.view", { file = file, chosen = paths }, target, "center")
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

-- The middle of a node's bounds in the world, or its place for a node without bounds.
local function boundsMiddle(node)
  local r = node.rect
  if r then
    return nodeToWorld(node, r[1] + r[3] / 2, r[2] + r[4] / 2)
  end
  return node.place[5], node.place[6]
end

-- The middle of the rectangle in the world that holds every chosen node: their bounds' corners, or their places.
local function selectionMiddle(view)
  local x1, y1, x2, y2
  local function add(x, y)
    x1, y1 = math.min(x1 or x, x), math.min(y1 or y, y)
    x2, y2 = math.max(x2 or x, x), math.max(y2 or y, y)
  end
  for _, path in ipairs(view.chosen) do
    local node = view.byPath[path]
    if node and node.rect then
      local r = node.rect
      add(nodeToWorld(node, r[1], r[2]))
      add(nodeToWorld(node, r[1] + r[3], r[2]))
      add(nodeToWorld(node, r[1], r[2] + r[4]))
      add(nodeToWorld(node, r[1] + r[3], r[2] + r[4]))
    elseif node then
      add(node.place[5], node.place[6])
    end
  end
  if x1 then
    return (x1 + x2) / 2, (y1 + y2) / 2
  end
end

-- What the chosen nodes are, and their places, turns and scales in the node file, to tell whether anything changed them since a
-- turn. It reads the file, which a change writes at once, not the places that the preview sends back a frame later.
local function placesKey(view)
  local index = project.file(view.file) and project.tree(view.file).index or {}
  local parts = {}
  for _, path in ipairs(view.chosen) do
    local n = index[path] or {}
    parts[#parts + 1] = ("%s %s %s %s %s %s"):format(path, n.posX, n.posY, n.rot, n.sclX, n.sclY)
  end
  return table.concat(parts, "\n")
end

-- The pivot that the chosen nodes turn and scale around, a setting of the project (DESIGN 13.3): each node's own place,
-- the middle of each node's bounds, or the middle of the whole choice.
local function pivotMode()
  local pivot = project.setting("pivot")
  return (pivot == "bounds" or pivot == "selection") and pivot or "own"
end

-- The one gizmo of the chosen nodes: its place in the world, and the node that leads, the one chosen last. It is at the lead's
-- place, the middle of the lead's bounds, or the middle of the choice, by the pivot.
local function gizmo(view)
  local lead
  for i = #view.chosen, 1, -1 do
    lead = lead or view.byPath[view.chosen[i]]
  end
  if not lead then
    return nil
  end
  local mode = pivotMode()
  if mode == "own" then
    return lead.place[5], lead.place[6], lead
  elseif mode == "bounds" then
    local x, y = boundsMiddle(lead)
    return x, y, lead
  end
  -- A turn or a scale goes around the point it started from, and the gizmo stays there, though the box around the turned bounds
  -- changes; after it, the point is kept while the chosen nodes are where it left them, so a second turn goes around the same one.
  local d = view.drag
  if d and d.kind == "tool" and d.tool ~= "move" then
    return d.centerX, d.centerY, lead
  end
  local kept = view.keptPivot
  if kept and kept.key == placesKey(view) then
    return kept.x, kept.y, lead
  end
  view.keptPivot = nil
  local x, y = selectionMiddle(view)
  return x, y, lead
end

-- The directions of a node's own x and y in the world, of length 1, which the scale tool's grips follow (DESIGN 13.3); the world's
-- for an axis that a scale of 0 flattens.
local function ownAxes(node)
  local p = node.place
  local xl, yl = math.sqrt(p[1] ^ 2 + p[2] ^ 2), math.sqrt(p[3] ^ 2 + p[4] ^ 2)
  local ux, uy = 1, 0
  local vx, vy = 0, 1
  if xl > 1e-9 then
    ux, uy = p[1] / xl, p[2] / xl
  end
  if yl > 1e-9 then
    vx, vy = p[3] / yl, p[4] / yl
  end
  return ux, uy, vx, vy
end

-- The scale tool's grip on an axis: whether a point of the panel is on the line from the gizmo along the direction, or on its box.
local function onGrip(x, y, dx, dy, sx, sy)
  local along = (sx - x) * dx + (sy - y) * dy
  local across = math.abs((sx - x) * -dy + (sy - y) * dx)
  return along >= 14 and along <= HANDLE + 6 and across <= 6
end

-- The nodes under a point of the view, the one that draws last first.
local function hits(view, sx, sy)
  local wx, wy = toWorld(view, sx, sy)
  local found = {}
  for i = #view.nodes, 1, -1 do
    local node = view.nodes[i]
    local hit
    if isMarked(view, "hidden", node.path) or isMarked(view, "locked", node.path) then
      hit = false
    elseif node.rect then
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

-- The gizmo's handle under a point of the panel (DESIGN 13.3): the leading node's path and the axis, "x" or "y" for an arrow of the
-- move tool and the scale tool's grips, and "both" for the square between the arrows, the turn tool's ring or the scale tool's square; or nil.
local function handleAt(view, sx, sy)
  local gx, gy, lead = gizmo(view)
  if not gx or not lead then
    return nil
  end
  local x, y = toScreen(view, gx, gy)
  local tool = project.tool()
  if tool == "move" then
    if sx >= x + SQUARE and sx <= x + SQUARE + SQUARE_SIZE and sy >= y + SQUARE and sy <= y + SQUARE + SQUARE_SIZE then
      return lead.path, "both"
    elseif math.abs(sy - y) <= 6 and sx >= x + 8 and sx <= x + HANDLE + 4 then
      return lead.path, "x"
    elseif math.abs(sx - x) <= 6 and sy >= y + 8 and sy <= y + HANDLE + 4 then
      return lead.path, "y"
    end
  elseif tool == "scale" then
    local ux, uy, vx, vy = ownAxes(lead)
    if math.abs(sx - x) <= 12 and math.abs(sy - y) <= 12 then
      return lead.path, "both"
    elseif onGrip(x, y, ux, uy, sx, sy) then
      return lead.path, "x"
    elseif onGrip(x, y, vx, vy, sx, sy) then
      return lead.path, "y"
    end
  elseif tool == "turn" and math.abs(sx - x) <= 16 and math.abs(sy - y) <= 16 then
    return lead.path, "both"
  end
end

-- The Shape tool (DESIGN 13.3): handles of the one chosen node, in its own space. Each property that its type marks with the option
-- handles, a vector or a list of vectors, has one at each point; onlr.shape's rectangle has one at each corner and at each edge's
-- middle, and its circle one on its edge, to the right of its middle.

local POINT = 5 -- half a handle's size, in the panel

-- Whether a property shows by its option when, with the component's values (DESIGN 6.2), so a polygon's points have no handles
-- while the shape is a rectangle.
local function shownWith(decl, values)
  for other, wanted in pairs(decl.options and decl.options.when or {}) do
    local found = false
    for _, each in ipairs(type(wanted) == "table" and wanted or { wanted }) do
      found = found or each == values[other]
    end
    if not found then
      return false
    end
  end
  return true
end

---A handle of the Shape tool: a point of a property, an edge or a corner of a rectangle, or a circle's radius.
---@class onlr.editor.Handle
---@field type string the component's type
---@field name string? the property of a point
---@field index integer? the point's place in a list
---@field edges {x: "l"|"r"|nil, y: "t"|"b"|nil}? a rectangle's edges that it moves
---@field radius boolean? a circle's
---@field x number in the node's space
---@field y number
---@field values table the component's values, its defaults for those that it lacks
---@field scales boolean? the Rectangle tool's on a node's bounds, which scales the node
---@field rect number[]? the bounds that such a handle is on, in the node's space

-- The handles of the one chosen node, and its lists of points, to which a double click adds one. Nothing while more are chosen.
---@return onlr.editor.Handle[] handles, table[] lists, table? placed, string? path
local function shapeHandles(view)
  local path = #view.chosen == 1 and view.chosen[1] or nil
  local placed = path and view.byPath[path]
  local node = placed and view.file and project.tree(view.file).index[path]
  if not node then
    return {}, {}
  end
  local handles, lists = {}, {}
  local typeNames = {}
  for typeName in pairs(node.components) do
    typeNames[#typeNames + 1] = typeName
  end
  table.sort(typeNames)
  for _, typeName in ipairs(typeNames) do
    local info = project.typeInfo(typeName)
    local own = node.components[typeName].values or {}
    local values = {}
    for _, decl in ipairs(info and info.properties or {}) do
      local value = own[decl.name]
      if value == nil then
        value = decl.default
      end
      values[decl.name] = value
    end
    -- while a handle is dragged, its component's handles show the dragged values, which the history gets at the release
    local d = view.drag
    if d and d.kind == "handle" and d.handle.type == typeName then
      for name, value in pairs(d.changed) do
        values[name] = value
      end
    end
    for _, decl in ipairs(info and info.properties or {}) do
      local value = values[decl.name]
      if decl.options and decl.options.handles and type(value) == "table" and shownWith(decl, values) then
        if decl.kind == "vector" then
          handles[#handles + 1] = { type = typeName, name = decl.name, x = value.x or 0, y = value.y or 0, values = values }
        elseif decl.kind == "list" then
          for i, point in ipairs(value) do
            handles[#handles + 1] = { type = typeName, name = decl.name, index = i, x = point.x or 0, y = point.y or 0, values = values }
          end
          lists[#lists + 1] = { type = typeName, name = decl.name, points = value, values = values }
        end
      end
    end
    local origin = type(values.origin) == "table" and values.origin or { x = 0, y = 0 }
    if typeName == "onlr.shape" and values.kind == "rectangle" then
      local l, t = -origin.x, -origin.y
      local at = { l = l, r = l + (values.width or 0), t = t, b = t + (values.height or 0) }
      for _, e in ipairs({ { "l", "t" }, { "r", "t" }, { "r", "b" }, { "l", "b" }, { "l" }, { "r" }, { nil, "t" }, { nil, "b" } }) do
        handles[#handles + 1] = {
          type = typeName, edges = { x = e[1], y = e[2] }, values = values,
          x = e[1] and at[e[1]] or (at.l + at.r) / 2, y = e[2] and at[e[2]] or (at.t + at.b) / 2,
        }
      end
    elseif typeName == "onlr.shape" and values.kind == "circle" then
      handles[#handles + 1] = { type = typeName, radius = true, x = -origin.x + (values.radius or 0), y = -origin.y, values = values }
    end
  end
  return handles, lists, placed, path
end

-- The Shape tool's handle under a point of the panel, the last drawn first.
---@return onlr.editor.Handle?
local function shapeHandleAt(view, sx, sy)
  local handles, _, placed = shapeHandles(view)
  for i = #handles, 1, -1 do
    local h = handles[i]
    local x, y = toScreen(view, nodeToWorld(placed, h.x, h.y))
    if math.abs(sx - x) <= POINT + 3 and math.abs(sy - y) <= POINT + 3 then
      return h
    end
  end
end

-- The Rectangle tool (DESIGN 13.3): handles at the corners and edges' middles of the one chosen node. A node whose onlr.shape is a
-- rectangle gets the shape's, as the Shape tool's, which change its size; any other gets its bounds', which scale the node.
---@return onlr.editor.Handle[] handles, table? placed, string? path
local function rectHandles(view)
  local all, _, placed, path = shapeHandles(view)
  if not placed then
    return {}
  end
  local handles = {}
  for _, h in ipairs(all) do
    if h.type == "onlr.shape" and h.edges then
      handles[#handles + 1] = h
    end
  end
  if #handles == 0 and placed.rect then
    local r = placed.rect
    local at = { l = r[1], r = r[1] + r[3], t = r[2], b = r[2] + r[4] }
    for _, e in ipairs({ { "l", "t" }, { "r", "t" }, { "r", "b" }, { "l", "b" }, { "l" }, { "r" }, { nil, "t" }, { nil, "b" } }) do
      handles[#handles + 1] = {
        type = "", scales = true, edges = { x = e[1], y = e[2] }, values = {}, rect = r,
        x = e[1] and at[e[1]] or (at.l + at.r) / 2, y = e[2] and at[e[2]] or (at.t + at.b) / 2,
      }
    end
  end
  return handles, placed, path
end

-- The handle of the Shape or Rectangle tool under a point of the panel.
---@return onlr.editor.Handle?
local function toolHandleAt(view, sx, sy)
  local tool = project.tool()
  if tool == "shape" then
    return shapeHandleAt(view, sx, sy)
  elseif tool == "rect" then
    -- the nearest, since a small node's handles are near each other
    local handles, placed = rectHandles(view)
    local best, distance
    for _, h in ipairs(handles) do
      local x, y = toScreen(view, nodeToWorld(placed, h.x, h.y))
      local far = math.max(math.abs(sx - x), math.abs(sy - y))
      if far <= POINT + 3 and (not distance or far < distance) then
        best, distance = h, far
      end
    end
    return best
  end
end

-- Whether two handles are one: the same point, edges or radius of the same component.
local function sameHandle(a, b)
  if not a or not b or a.type ~= b.type or a.name ~= b.name or a.index ~= b.index or a.radius ~= b.radius then
    return false
  end
  return (a.edges and a.edges.x) == (b.edges and b.edges.x) and (a.edges and a.edges.y) == (b.edges and b.edges.y)
end

-- The chosen paths as a set, made again when the view's list is another one; the list is replaced, never changed in place.
local function isChosen(view, path)
  if view.chosenFor ~= view.chosen then
    local set = {}
    for _, chosen in ipairs(view.chosen) do
      set[chosen] = true
    end
    view.chosenFor, view.chosenSet = view.chosen, set
  end
  return view.chosenSet[path] == true
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
  local left, top, right, bottom = r[1], r[2], r[1] + r[3], r[2] + r[4]
  local ax, ay = toScreen(view, nodeToWorld(node, left, top))
  local bx, by = toScreen(view, nodeToWorld(node, right, top))
  local cx, cy = toScreen(view, nodeToWorld(node, right, bottom))
  local dx, dy = toScreen(view, nodeToWorld(node, left, bottom))
  gpu.line(surface, ax, ay, bx, by, thickness, color)
  gpu.line(surface, bx, by, cx, cy, thickness, color)
  gpu.line(surface, cx, cy, dx, dy, thickness, color)
  gpu.line(surface, dx, dy, ax, ay, thickness, color)
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
    if isMarked(view, "hidden", node.path) then
      -- a hidden node draws nothing, not even its outline or its marker
    elseif node.rect then
      if color then
        outline(surface, view, node, color, chosen and 2 or 1)
      end
    else
      local x, y = toScreen(view, node.place[5], node.place[6])
      frameRect(surface, x - 4, y - 4, 8, 8, 1, color or "textDim")
    end
  end

  -- The one gizmo of the chosen nodes, at the pivot's place (DESIGN 13.3).
  local tool = project.tool()
  local gx, gy, lead = gizmo(view)
  if gx and lead then
    local x, y = toScreen(view, gx, gy)
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
      local ox, oy = toScreen(view, lead.place[5], lead.place[6])
      local ax, ay = toScreen(view, nodeToWorld(lead, 1, 0))
      local length = math.max(1e-6, math.sqrt((ax - ox) ^ 2 + (ay - oy) ^ 2))
      gpu.line(surface, x, y, x + (ax - ox) / length * 14, y + (ay - oy) / length * 14, 2, "accent")
    elseif tool == "scale" then
      -- a grip along each of the leading node's own axes scales that axis alone, as Unity's do; the square scales both
      local axis = view.drag and view.drag.kind == "tool" and view.drag.axis
      local ux, uy, vx, vy = ownAxes(lead)
      for _, grip in ipairs({ { "x", ux, uy, AXIS_X }, { "y", vx, vy, AXIS_Y } }) do
        local color = axis == grip[1] and "accent" or grip[4]
        local ex, ey = x + grip[2] * HANDLE, y + grip[3] * HANDLE
        gpu.line(surface, x + grip[2] * 14, y + grip[3] * 14, ex, ey, 2, color)
        gpu.fill(surface, ex - 5, ey - 5, 10, 10, color)
      end
      if axis == "both" then
        gpu.fill(surface, x - 12, y - 12, 24, 24, "accent")
      end
      frameRect(surface, x - 12, y - 12, 24, 24, 2, "accent")
      gpu.fill(surface, x + 8, y + 8, 8, 8, "accent")
    end
  end

  -- The Shape tool's handles: squares, filled while dragged and for the point that Delete removes. A list's points are joined in their
  -- order, so a path shows; a polygon's outline is the shape's own.
  if tool == "shape" or tool == "rect" then
    local handles, lists, placed
    if tool == "shape" then
      handles, lists, placed = shapeHandles(view)
    else
      handles, placed = rectHandles(view)
      lists = {}
    end
    for _, list in ipairs(lists) do
      for i = 2, #list.points do
        local a, b = list.points[i - 1], list.points[i]
        local ax, ay = toScreen(view, nodeToWorld(placed, a.x or 0, a.y or 0))
        local bx, by = toScreen(view, nodeToWorld(placed, b.x or 0, b.y or 0))
        gpu.line(surface, ax, ay, bx, by, 1, "#ffffff60")
      end
    end
    local dragged = view.drag and view.drag.kind == "handle" and view.drag.handle
    for _, h in ipairs(handles) do
      local x, y = toScreen(view, nodeToWorld(placed, h.x, h.y))
      if sameHandle(h, dragged) or h.index and sameHandle(h, view.point) then
        gpu.fill(surface, x - POINT, y - POINT, POINT * 2, POINT * 2, "accent")
      else
        gpu.fill(surface, x - POINT, y - POINT, POINT * 2, POINT * 2, "background")
      end
      frameRect(surface, x - POINT, y - POINT, POINT * 2, POINT * 2, 1, "accent")
    end
  end

  if view.drag and view.drag.kind == "rectangle" then
    local d = view.drag
    local x, y = math.min(d.startX, d.x), math.min(d.startY, d.y)
    frameRect(surface, x, y, math.abs(d.x - d.startX), math.abs(d.y - d.startY), 1, "accent")
  end

  view.x, view.y, view.zoom = wantX, wantY, wantZoom

  if picking and view.file == picking.file then
    gpu.text(surface, draw.font("ui"), ("Click the node for %s, here or in the node hierarchy. Escape ends it."):format(picking.label), 12, h - 22, 13, "accent")
  end

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
  -- Each node turns and scales around its pivot, a setting of the project (DESIGN 13.3): its own place, the middle of its bounds, or
  -- the middle of the choice. The pointer's turn and distance are seen from the gizmo, so every node turns and scales by one amount.
  local mode = pivotMode()
  local centerX, centerY = gizmo(view)
  for _, n in ipairs(nodes) do
    if mode == "own" then
      n.pivotX, n.pivotY = n.originX, n.originY
    elseif mode == "bounds" then
      n.pivotX, n.pivotY = boundsMiddle(view.byPath[n.path])
    else
      n.pivotX, n.pivotY = centerX, centerY
    end
  end
  local wx, wy = toWorld(view, sx, sy)
  local lead = select(3, gizmo(view))
  local ux, uy, vx, vy = 1, 0, 0, 1
  if lead then
    ux, uy, vx, vy = ownAxes(lead)
  end
  view.drag = {
    kind = "tool", tool = project.tool() == "rect" and "move" or project.tool(), nodes = nodes, startX = wx, startY = wy, centerX = centerX, centerY = centerY, fields = {},
    axes = { x = { ux, uy }, y = { vx, vy } },
  }
end

local TURN_STEP = math.pi / 12

local function toolDrag(view, sx, sy, ctrl)
  local d = view.drag
  local wx, wy = toWorld(view, sx, sy)
  local cx, cy = d.centerX, d.centerY
  local angle = math.atan2(wy - cy, wx - cx) - math.atan2(d.startY - cy, d.startX - cx)
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
    elseif d.axis == "x" or d.axis == "y" then
      -- a grip scales along the leading node's axis alone, by how far the pointer goes along it from the gizmo; each node scales its
      -- own x or y by that amount
      local u = d.axes[d.axis]
      local from = (d.startX - cx) * u[1] + (d.startY - cy) * u[2]
      local f = math.abs(from) > 1e-9 and ((wx - cx) * u[1] + (wy - cy) * u[2]) / from or 1
      local along = offX * u[1] + offY * u[2]
      toX, toY = (f - 1) * along * u[1], (f - 1) * along * u[2]
      fields.sclX = d.axis == "x" and n.sclX * f or n.sclX
      fields.sclY = d.axis == "y" and n.sclY * f or n.sclY
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

-- The Shape tool's drag: the values that a handle moved to a point of its node's space gives its component. A point snaps to the grid
-- in the node's space, and a radius in steps of the grid; a rectangle's edge stops at the edge across from it.
---@param h onlr.editor.Handle
local function handleValues(h, nx, ny, ctrl)
  local v = h.values
  local origin = type(v.origin) == "table" and v.origin or { x = 0, y = 0 }
  if h.radius then
    return { radius = snap(math.sqrt((nx + origin.x) ^ 2 + (ny + origin.y) ^ 2), ctrl) }
  end
  nx, ny = snap(nx, ctrl), snap(ny, ctrl)
  if h.edges then
    local l, t = -origin.x, -origin.y
    local r, b = l + (v.width or 0), t + (v.height or 0)
    if h.edges.x == "l" then
      l = math.min(nx, r)
    elseif h.edges.x == "r" then
      r = math.max(nx, l)
    end
    if h.edges.y == "t" then
      t = math.min(ny, b)
    elseif h.edges.y == "b" then
      b = math.max(ny, t)
    end
    return { origin = { x = -l, y = -t }, width = r - l, height = b - t }
  elseif h.index then
    local list = {}
    for i, point in ipairs(v[h.name]) do
      list[i] = { x = point.x, y = point.y }
    end
    list[h.index] = { x = nx, y = ny }
    return { [h.name] = list }
  end
  return { [h.name] = { x = nx, y = ny } }
end

-- The Rectangle tool's drag on a node's bounds: the scale and place that put the dragged edges at a point of the node's space, as it
-- was at the press, while the edges across stay where they were. An edge stops just before the one across from it.
local function boundsFields(d, nx, ny, ctrl)
  local h, r = d.handle, d.handle.rect
  local kx, ky, ax, ay = 1, 1, 0, 0
  if h.edges.x and r[3] > 0 then
    if h.edges.x == "r" then
      kx, ax = math.max(snap(nx, ctrl) - r[1], r[3] / 100) / r[3], r[1]
    else
      kx, ax = math.max(r[1] + r[3] - snap(nx, ctrl), r[3] / 100) / r[3], r[1] + r[3]
    end
  end
  if h.edges.y and r[4] > 0 then
    if h.edges.y == "b" then
      ky, ay = math.max(snap(ny, ctrl) - r[2], r[4] / 100) / r[4], r[2]
    else
      ky, ay = math.max(r[2] + r[4] - snap(ny, ctrl), r[4] / 100) / r[4], r[2] + r[4]
    end
  end
  -- the edge across, at ax and ay, stays: the place moves by what the new scale would move it, turned by the node's angle
  local lx, ly = d.sclX * ax * (1 - kx), d.sclY * ay * (1 - ky)
  local cos, sin = math.cos(d.rot), math.sin(d.rot)
  return {
    posX = d.posX + lx * cos - ly * sin, posY = d.posY + lx * sin + ly * cos, sclX = d.sclX * kx, sclY = d.sclY * ky,
  }
end

-- A double click with the Shape tool adds a point to a list: between the two neighbouring points whose line is under the pointer,
-- or after the last, which closes a polygon between its last corner and its first.
local function addPoint(view, sx, sy, ctrl)
  local _, lists, placed, path = shapeHandles(view)
  if #lists == 0 or not placed then
    return false
  end
  local list, at = lists[1], #lists[1].points + 1
  for _, each in ipairs(lists) do
    for i = 2, #each.points do
      local ax, ay = toScreen(view, nodeToWorld(placed, each.points[i - 1].x or 0, each.points[i - 1].y or 0))
      local bx, by = toScreen(view, nodeToWorld(placed, each.points[i].x or 0, each.points[i].y or 0))
      local dx, dy = bx - ax, by - ay
      local length = dx * dx + dy * dy
      local f = length > 0 and math.max(0, math.min(1, ((sx - ax) * dx + (sy - ay) * dy) / length)) or 0
      if math.sqrt((ax + dx * f - sx) ^ 2 + (ay + dy * f - sy) ^ 2) <= 6 then
        list, at = each, i
      end
    end
  end
  local nx, ny = worldToNode(placed.place, toWorld(view, sx, sy))
  local points = {}
  for i, point in ipairs(list.points) do
    points[i] = { x = point.x, y = point.y }
  end
  table.insert(points, at, { x = snap(nx, ctrl), y = snap(ny, ctrl) })
  project.setValues(view.file, { path }, list.type, { [list.name] = points }, "Add a point")
  view.point = { type = list.type, name = list.name, index = at }
  return true
end

-- Delete with the Shape tool removes the point that the user clicked last.
local function removePoint(view)
  local p = view.point
  local _, lists, _, path = shapeHandles(view)
  for _, list in ipairs(lists) do
    if p and list.type == p.type and list.name == p.name and list.points[p.index] then
      local points = {}
      for i, point in ipairs(list.points) do
        if i ~= p.index then
          points[#points + 1] = { x = point.x, y = point.y }
        end
      end
      project.setValues(view.file, { path }, list.type, { [list.name] = points }, "Remove a point")
      view.point = nil
      return true
    end
  end
  return false
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
        console.add(message, "error", nil, "onlr")
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
    -- a file that does not load, such as one with git's conflict marks, has no top node to add to (DESIGN 4.2)
    local top = view.file and project.tree(view.file).first
    local first = top and view.byPath[top.path]
    local nx, ny = worldToNode(first and first.place or IDENTITY, wx, wy)
    nx, ny = snap(math.floor(nx + 0.5)), snap(math.floor(ny + 0.5))
    ui.menu(view.panel, event.x, event.y, {
      { label = "Add node here", enabled = top ~= nil, onClick = function()
        local id = project.addNode(view.file, top.path, { posX = nx ~= 0 and nx or nil, posY = ny ~= 0 and ny or nil })
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
    { label = "Select with children", keys = "Shift+A", onClick = functions.selectWithChildren.fn },
    { label = "Select all", keys = "Ctrl+A", onClick = functions.selectAll.fn },
    { line = true },
    { label = "Frame chosen", keys = "F", onClick = function()
      frame(view)
    end },
    { line = true },
    { label = "Hide in the view", keys = "H", onClick = functions.hideChosen.fn },
    { label = "Lock in the view", keys = "L", onClick = functions.lockChosen.fn },
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
  elseif event.type == "pointerDown" and event.button == 1 and not event.alt and picking then
    -- a pick waits: the node under the pointer is the reference's, and a click beside the nodes ends the pick
    pick(view.file, hits(view, x, y)[1])
  elseif event.type == "pointerDown" then
    if event.button == 2 or (event.button == 1 and event.alt) then
      view.drag = { kind = "pan", startX = x, startY = y, viewX = view.x, viewY = view.y }
    elseif event.button == 1 and view.file and toolHandleAt(view, x, y) then
      -- a handle of the Shape or the Rectangle tool is above the nodes, and drags its point, edge or radius
      local h = assert(toolHandleAt(view, x, y))
      view.press = { x = x, y = y, found = {}, handle = h, wasChosen = true }
      view.point = h.index and h or nil
      view.panel:redraw()
    elseif event.button == 1 and view.file and project.tool() == "shape" and view.lastDown
      and math.abs(view.lastDown.x - x) <= 3 and math.abs(view.lastDown.y - y) <= 3 and addPoint(view, x, y, event.ctrl) then
      -- a second press within 0.4 seconds, a double click, added a point
      view.lastDown = nil
    elseif event.button == 1 and view.file and handleAt(view, x, y) then
      -- a handle of the move or scale tool is above the nodes, and drags the chosen nodes along its axis, or both
      local path, axis = handleAt(view, x, y)
      view.press = { x = x, y = y, found = { path }, axis = axis, wasChosen = true }
    elseif event.button == 1 and view.file then
      if project.tool() == "shape" then
        view.point = nil
        local down = { x = x, y = y }
        view.lastDown = down
        ecs.timer.start(0.4, false, function()
          if view.lastDown == down then
            view.lastDown = nil
          end
        end)
      end
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
      if press.handle and press.handle.scales then
        -- the Rectangle tool on a node's bounds scales it from where the node was at the press
        local path = view.chosen[1]
        local node, placed = project.tree(view.file).index[path], view.byPath[path]
        view.drag = {
          kind = "bounds", handle = press.handle, path = path, fields = nil, place = { table.unpack(placed.place) },
          posX = node.posX, posY = node.posY, rot = node.rot, sclX = node.sclX, sclY = node.sclY,
        }
      elseif press.handle then
        view.drag = { kind = "handle", handle = press.handle, path = view.chosen[1], changed = {} }
      elseif press.found[1] and not press.shift then
        startToolDrag(view, press.x, press.y)
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
    elseif d and d.kind == "bounds" then
      local nx, ny = worldToNode(d.place, toWorld(view, x, y))
      d.fields = boundsFields(d, nx, ny, event.ctrl)
      runners.change(view.file, d.path, d.fields)
    elseif d and d.kind == "handle" and view.byPath[d.path] then
      local nx, ny = worldToNode(view.byPath[d.path].place, toWorld(view, x, y))
      d.changed = handleValues(d.handle, nx, ny, event.ctrl)
      runners.change(view.file, d.path, nil, { [d.handle.type] = d.changed })
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
        if d.tool ~= "move" and pivotMode() == "selection" then
          view.keptPivot = { key = placesKey(view), x = d.centerX, y = d.centerY }
        end
      end
    elseif d and d.kind == "bounds" then
      if d.fields then
        project.setFields(view.file, { [d.path] = d.fields }, "Size")
      end
    elseif d and d.kind == "handle" then
      if next(d.changed) then
        project.setValues(view.file, { d.path }, d.handle.type, d.changed, d.handle.index and "Move a point" or "Change " .. d.handle.type)
      end
    elseif d and d.kind == "rectangle" then
      -- Every node whose place or bounds' middle is in the rectangle.
      local x1, y1 = math.min(d.startX, d.x), math.min(d.startY, d.y)
      local x2, y2 = math.max(d.startX, d.x), math.max(d.startY, d.y)
      local paths = d.shift and format.copy(view.chosen) or {}
      local taken = {}
      for _, path in ipairs(paths) do
        taken[path] = true
      end
      for _, node in ipairs(view.nodes) do
        local cx, cy = 0, 0
        if node.rect then
          cx, cy = node.rect[1] + node.rect[3] / 2, node.rect[2] + node.rect[4] / 2
        end
        local sx, sy = toScreen(view, nodeToWorld(node, cx, cy))
        local free = not isMarked(view, "hidden", node.path) and not isMarked(view, "locked", node.path)
        if free and sx >= x1 and sx <= x2 and sy >= y1 and sy <= y2 and not taken[node.path] then
          paths[#paths + 1] = node.path
          taken[node.path] = true
        end
      end
      choose(view, paths)
    elseif press and not d and not press.axis and not press.handle then
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
        -- the Shape tool keeps its node chosen, so a double click beside the shape adds a point there
        if project.tool() ~= "shape" then
          choose(view, {})
        end
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
      view.chosen = type(saved.chosen) == "table" and saved.chosen or view.chosen
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
  runners.filesChanged(value and value.files or {})
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
      if not format.same(view.chosen, chosen.paths) then
        view.point = nil
      end
      view.chosen = chosen.paths
      sync(view)
      view.panel:redraw()
    end
  end
end)

for _, name in ipairs({ "onlr.tool", "onlr.settings" }) do
  ecs.event.subscribe(name, function(_, setting)
    for _, view in pairs(views) do
      if setting == "hidden" then
        sync(view)
      end
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
    console.add(message, "warn", nil, "onlr")
  end
end

-- The node file that the selections act on: the focused node view's, or the chosen nodes'.
local function shownFile()
  local view = current()
  local file = view and view.file or project.chosen().file
  if file and project.file(file) then
    return file
  end
end

-- A node and every node under it, in the tree's order, once each, after what `out` holds.
local function withChildren(node, out, seen)
  if not seen[node.path] then
    seen[node.path] = true
    out[#out + 1] = node.path
  end
  for _, child in ipairs(node.children or {}) do
    withChildren(child, out, seen)
  end
  return out
end

functions = {
  openFile = { sig = "void(string file)", doc = "Open a node file in a node view", fn = function(file)
    openFile(file)
  end },
  showNodes = { sig = "void(string file, value paths)", doc = "Open a node file in a node view, and choose nodes of it", fn = openFile },
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
  deleteChosen = { sig = "void()", doc = "Delete the chosen nodes; with the Shape tool, the point clicked last", fn = function()
    local view = current()
    if view and project.tool() == "shape" and view.point and removePoint(view) then
      return
    end
    onChosen(function(file, paths)
      say(project.deleteNodes(file, paths))
    end)()
  end },
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
  cancelPick = { sig = "void()", doc = "End a pick of a node for a reference, setting nothing", fn = function()
    startPick(nil)
  end },
  selectAll = { sig = "void()", doc = "Choose every node of the node file", fn = function()
    local file = shownFile()
    local top = file and project.tree(file).first
    if top then
      project.choose(file, withChildren(top, {}, {}))
    end
  end },
  selectWithChildren = { sig = "void()", doc = "Choose the chosen nodes and every node under them", fn = onChosen(function(file, paths)
    local tree, out, seen = project.tree(file), {}, {}
    for _, path in ipairs(paths) do
      local node = tree.index[path]
      if node then
        withChildren(node, out, seen)
      end
    end
    project.choose(file, out)
  end) },
  hideChosen = { sig = "void()", doc = "Hide the chosen nodes in the node view, or show them again", fn = onChosen(function(file, paths)
    toggleMarks("hidden", file, paths)
  end) },
  lockChosen = { sig = "void()", doc = "Lock the chosen nodes against being chosen in the node view, or unlock them", fn = onChosen(function(file, paths)
    toggleMarks("locked", file, paths)
  end) },
  toolMove = { sig = "void()", doc = "The move tool", fn = function()
    project.setTool("move")
  end },
  toolTurn = { sig = "void()", doc = "The turn tool", fn = function()
    project.setTool("turn")
  end },
  toolScale = { sig = "void()", doc = "The scale tool", fn = function()
    project.setTool("scale")
  end },
  toolRect = { sig = "void()", doc = "The Rectangle tool, which sizes a node by its corners and edges", fn = function()
    project.setTool("rect")
  end },
  toolShape = { sig = "void()", doc = "The Shape tool, which drags a shape's corners and edges and the points of a property", fn = function()
    project.setTool("shape")
  end },
  pivotOwn = { sig = "void()", doc = "Turn and scale the chosen nodes each around its own place", fn = function()
    project.setSetting("pivot", "own")
  end },
  pivotBounds = { sig = "void()", doc = "Turn and scale the chosen nodes each around the middle of its bounds", fn = function()
    project.setSetting("pivot", "bounds")
  end },
  pivotSelection = { sig = "void()", doc = "Turn and scale the chosen nodes around the middle of all of them", fn = function()
    project.setSetting("pivot", "selection")
  end },
}

for key, name in pairs({
  ["Delete"] = "onlr.deleteChosen", ["Ctrl+D"] = "onlr.duplicateChosen", ["Ctrl+C"] = "onlr.copyChosen",
  ["Ctrl+V"] = "onlr.pasteChosen", ["W"] = "onlr.toolMove", ["E"] = "onlr.toolTurn",
  ["R"] = "onlr.toolScale", ["T"] = "onlr.toolRect", ["Y"] = "onlr.toolShape", ["F"] = "onlr.frame", ["H"] = "onlr.hideChosen",
  ["L"] = "onlr.lockChosen", ["Escape"] = "onlr.cancelPick", ["Ctrl+A"] = "onlr.selectAll", ["Shift+A"] = "onlr.selectWithChildren",
}) do
  ecs.key.bind("onlr.view", key, name)
end

if project.folder() ~= "" then
  console.setFolder(project.folder())
  runners.ensurePreview()
end

-- The other parts call the functions themselves; init.lua registers them as the plugin's (DESIGN 13.1).
---@type table<string, any>
local part = {
  functions = functions,
  marks = marks,
  toggleMarks = toggleMarks,
  startPick = startPick,
  pick = pick,
  picking = function()
    return picking
  end,
}
for name, entry in pairs(functions) do
  part[name] = entry.fn
end
return part
