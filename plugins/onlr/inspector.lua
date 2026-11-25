-- The inspector (DESIGN 13.4): the chosen nodes' own fields, then each of their components under its type's name,
-- with one row for each property and the control of its kind (DESIGN 6.2).

local ecs = require("ecs")
local ui = require("ui")
local fs = require("fs")
local project = require("project")
local nodeview = require("nodeview")
local console = require("console")
local shared = require("shared")
local format = require("format")
local resolve = require("resolve")

local STYLES = ui.styles()
local STATE_VERSION = 1

-- The values that Copy Values kept, with their component's type, for Paste Values.
---@type { type: string, values: table }?
local copied

-- A value that differs among the chosen nodes: its control shows empty.
local MIXED = {}

local same, copy = format.same, format.copy

-- The one value that every node gives, or MIXED.
local function common(nodes, get)
  local value = get(nodes[1])
  for i = 2, #nodes do
    if not same(get(nodes[i]), value) then
      return MIXED
    end
  end
  return value
end

local function label(text, tooltip)
  return ui.text(text, { width = 110, tooltip = tooltip })
end

-- A number's control: a number field, or an empty text field while the nodes differ. With a width, it keeps that width.
local function number(id, value, set, decl, width)
  local options = decl and decl.options or {}
  if value == MIXED or type(value) ~= "number" then
    return ui.field("", { id = id, grow = 1, tooltip = "The nodes differ; Return sets the typed number on all of them", onSubmit = function(text)
      local n = tonumber(text)
      if n then
        set(n)
      end
    end })
  end
  return ui.number(value, {
    id = id, grow = width and 0 or 1, width = width, min = options.min, max = options.max, step = decl and decl.kind == "integer" and 1 or nil,
    tooltip = (options.degrees and "In degrees; a script reads radians. " or "") .. "Return takes the number; Up and Down change it",
    onSubmit = set,
  })
end

local function round(n)
  return n and math.floor(n * 1000 + 0.5) / 1000
end

-- An angle's field: the inspector shows and takes degrees, and the file and scripts keep LÖVE's radians (DESIGN 6.2). Gives the
-- declaration, the value and the setter in degrees.
local function inDegrees(decl, value, set)
  local options = {}
  for k, v in pairs(decl.options or {}) do
    options[k] = v
  end
  options.angle, options.degrees = nil, true
  options.min, options.max = round(options.min and math.deg(options.min)), round(options.max and math.deg(options.max))
  if type(value) == "number" then
    value = round(math.deg(value))
  end
  return { kind = decl.kind, name = decl.name, default = decl.default, options = options }, value, function(degrees)
    set(math.rad(degrees))
  end
end

-- A declaration whose angle option in when's form is made true or false by the component's values (DESIGN 6.2), with its
-- group's fields and its list's item; holds tells whether the component's values have the ones that a table names.
local function settleAngles(decl, holds)
  if not decl then
    return nil
  end
  local settled = {}
  for k, v in pairs(decl) do
    settled[k] = v
  end
  if decl.options and type(decl.options.angle) == "table" then
    settled.options = {}
    for k, v in pairs(decl.options) do
      settled.options[k] = v
    end
    settled.options.angle = holds(decl.options.angle)
  end
  if decl.fields then
    settled.fields = {}
    for i, field in ipairs(decl.fields) do
      settled.fields[i] = settleAngles(field, holds)
    end
  end
  settled.item = settleAngles(decl.item, holds)
  return settled
end

local function text(id, value, set, valid)
  return ui.field(value ~= MIXED and type(value) == "string" and value or "", { id = id, grow = 1, valid = valid, tooltip = "Return takes the text", onSubmit = function(new)
    set(new)
  end })
end

-- The endings that the system's dialog shows for a kind of file, as LÖVE reads them.
local PATTERNS = {
  image = "png;jpg;jpeg;bmp;tga;hdr;pic;exr;dds;ktx",
  sound = "wav;ogg;oga;ogv;mp3;flac;abc;mod;s3m;xm;it",
  font = "ttf;otf;fnt",
  nodeFile = "lua",
}

-- A path that the dialog gave or the user typed, from the project's folder. A game reads only its own folder (DESIGN 3.1),
-- so a file outside it is copied in first, after asking (DESIGN 13.4); nil when the user declines.
local function fromProject(path)
  return project.bringIn(path)
end

-- The field of a file's path, with a button that chooses the file in the system's dialog.
local function filePath(id, value, kind, extensions, set, valid)
  local pattern = PATTERNS[kind] or (extensions and table.concat(extensions, ";")) or nil
  return ui.path(value ~= MIXED and type(value) == "string" and value or "", { id = id, grow = 1, valid = valid, dialog = "openFile", pattern = pattern,
    tooltip = "Return takes a typed path; the button chooses a file of the project", onSubmit = function(new)
      local path = new == "" and "" or fromProject(new)
      if path then
        set(path)
      end
    end })
end

---What an inspector shows: the chosen nodes of a node file.
---@class onlr.editor.Subject
---@field file string
---@field paths string[]
---@field nodes onlr.editor.Node[]
---@field tree onlr.editor.Tree

-- The control of a property's kind. set gets the new value; drops notes the rows that take a dragged file or node.
local function control(state, subject, id, decl, value, set)
  local kind = decl.kind
  local options = decl.options or {}
  if kind == "number" and options.angle == true then
    decl, value, set = inDegrees(decl, value, set)
    options = decl.options
  end
  if kind == "bool" then
    return ui.toggle(value == true, { id = id, tooltip = "On or off", onChange = set })
  elseif (kind == "integer" or kind == "number") and type(options.min) == "number" and type(options.max) == "number" and type(value) == "number" then
    -- A number with a range shows a slider beside its field, as Unity's Range does; the slider's release is one change.
    local field = number(id, value, set, decl, 64)
    return ui.row({ gap = 4, grow = 1, align = "center" }, {
      ui.slider(value, { id = id .. ":slide", grow = 1, min = options.min, max = options.max, step = kind == "integer" and 1 or nil,
        tooltip = ("From %s to %s; a drag changes it"):format(options.min, options.max), onSubmit = set }),
      field,
    })
  elseif kind == "integer" or kind == "number" then
    return number(id, value, set, decl)
  elseif kind == "string" then
    return text(id, value, set)
  elseif kind == "choice" then
    local choices = options.choices or {}
    local selected = 0
    for i, choice in ipairs(choices) do
      if choice == value then
        selected = i
      end
    end
    return ui.dropdown(selected, choices, { id = id, grow = 1, tooltip = "One of the choices that the property declares", onSelect = function(choice)
      set(choices[choice])
    end })
  elseif kind == "color" then
    local color = type(value) == "table" and value or { 1, 1, 1, 1 }
    local parts = {}
    for i = 1, 4 do
      parts[i] = number(id .. ":" .. i, value ~= MIXED and (color[i] or 1) or MIXED, function(n)
        local new = copy(color)
        for j = 1, 4 do
          new[j] = new[j] or 1
        end
        new[i] = n
        set(new)
      end, { kind = "number", options = { min = 0, max = 1 } })
    end
    if value ~= MIXED then
      local function byte(n)
        return math.floor(math.max(0, math.min(1, n or 1)) * 255 + 0.5)
      end
      parts[5] = ui.color(("#%02x%02x%02x%02x"):format(byte(color[1]), byte(color[2]), byte(color[3]), byte(color[4])), {
        id = id .. ":pick", alpha = true, tooltip = "A click opens a picker", onChange = function(picked)
          local new = {}
          for i = 1, 4 do
            new[i] = tonumber(picked:sub(2 * i, 2 * i + 1), 16) / 255
          end
          set(new)
        end })
    end
    return ui.row({ gap = 4, grow = 1, align = "center" }, parts)
  elseif kind == "vector" then
    local vector = type(value) == "table" and value or { x = 0, y = 0 }
    local function part(field)
      return number(id .. ":" .. field, value ~= MIXED and (vector[field] or 0) or MIXED, function(n)
        set({ x = field == "x" and n or vector.x or 0, y = field == "y" and n or vector.y or 0 })
      end)
    end
    return ui.row({ gap = 4, grow = 1 }, { part("x"), part("y") })
  elseif kind == "sound" then
    -- A sound is a file and whether LÖVE streams it. The node file keeps a path alone while stream is the type's.
    local path, stream = value, options.stream or false
    if type(value) == "table" then
      path = value.path
      if value.stream ~= nil then
        stream = value.stream
      end
    end
    local function write(newPath, newStream)
      if newStream == (options.stream or false) then
        set(newPath)
      else
        set({ path = newPath, stream = newStream })
      end
    end
    local known = path == nil or path == MIXED or path == "" or fs.info(project.folder() .. tostring(path)) ~= nil
    state.drops[#state.drops + 1] = { id = id, type = "file-list", set = function(new)
      write(new, stream)
    end }
    return ui.row({ gap = 4, grow = 1, align = "center" }, {
      filePath(id, value ~= MIXED and path or MIXED, "sound", nil, function(new)
        write(new ~= "" and new or nil, stream)
      end, known),
      ui.toggle(value ~= MIXED and stream == true, { id = id .. ":stream", label = "Stream",
        tooltip = "LÖVE streams the file as it plays, as music needs. Off, it decodes it whole when it loads, as short sounds need",
        onChange = function(on)
          write(path, on)
        end }),
    })
  elseif kind == "image" or kind == "file" or kind == "nodeFile" then
    -- A file is set by dragging it from the files panel onto the row, by the system's dialog, or by typing its path.
    local known = value == nil or value == MIXED or value == "" or fs.info(project.folder() .. tostring(value)) ~= nil
    state.drops[#state.drops + 1] = { id = id, type = "file-list", set = set, extensions = options.extensions, nodeFile = kind == "nodeFile" }
    return filePath(id, value, kind, options.extensions, function(new)
      set(new ~= "" and new or nil)
    end, known)
  elseif kind == "font" then
    local font = type(value) == "table" and value or {}
    local known = not font.path or fs.info(project.folder() .. tostring(font.path)) ~= nil
    state.drops[#state.drops + 1] = { id = id, type = "file-list", set = function(path)
      set({ path = path, size = font.size or options.size or 12 })
    end }
    return ui.row({ gap = 4, grow = 1 }, {
      filePath(id, value ~= MIXED and font.path or MIXED, "font", nil, function(new)
        set({ path = new ~= "" and new or nil, size = font.size or options.size or 12 })
      end, known),
      number(id .. ":size", value ~= MIXED and (font.size or options.size or 12) or MIXED, function(n)
        set({ path = font.path, size = n })
      end),
    })
  elseif kind == "node" or kind == "component" then
    -- A node is set by dragging it from the node hierarchy onto the row, or by Pick and a click on it in a node view or the nodes
    -- panel, as Unity's round button does (DESIGN 13.4).
    local named = type(value) == "string" and subject.tree.index[value]
    local shown = value == MIXED and "" or named and (named.name or value) or value and (tostring(value) .. " (no such node)") or "(none)"
    local needs = kind == "component" and decl.type or nil
    state.drops[#state.drops + 1] = { id = id, type = "onlr.node", set = set, needs = needs, tree = subject.tree, file = subject.file }
    local waiting = nodeview.picking()
    local mine = waiting ~= nil and waiting.id == id
    return ui.row({ id = id, gap = 4, grow = 1, align = "center" }, {
      ui.text(mine and "Click a node..." or shown, { grow = 1, color = mine and "accent" or value and value ~= MIXED and not named and "error" or nil }),
      ui.button(mine and "Cancel" or "Pick", {
        id = id .. ":pick",
        tooltip = mine and "End the pick, setting nothing" or "Then click the node, in a node view or in the node hierarchy", keys = mine and "Escape" or nil,
        onClick = function()
          if mine then
            nodeview.startPick(nil)
          else
            nodeview.startPick({ id = id, file = subject.file, label = decl.name and shared.words(decl.name) or "the reference", needs = needs, set = set })
          end
        end,
      }),
      (value ~= nil and ui.button("Clear", { id = id .. ":clear", tooltip = "Take the value out", onClick = function()
        set(nil)
      end })) --[[@as ui.Element]],
    })
  end
  return ui.text(type(value) == "table" and "(a table)" or tostring(value), { grow = 1 })
end

-- The rows of a property: one row, or for a group and a list a heading with rows under it.
local function rows(state, subject, out, id, decl, value, set, title, mark)
  local name = title or (decl.options and decl.options.label) or shared.words(decl.name or "")
  local description = decl.options and decl.options.description
  -- a heading that the declaration names shows above the property, to part a type's properties
  local heading = decl.options and decl.options.heading
  if type(heading) == "string" and heading ~= "" then
    out[#out + 1] = ui.text(heading, { style = STYLES.heading })
  end
  if decl.kind == "group" or decl.kind == "list" then
    -- a group and a list fold, as a component does, under a heading whose click folds them; the inspector keeps what is folded by
    -- the property's place in its type, such as onlr.shape:points, so it stays folded for every node (DESIGN 13.4)
    local foldKey = id:gsub("^[^:]*:", "")
    local inner = {}
    if mark then
      inner[1] = ui.row({}, { ui.space(), mark })
    end
    if decl.kind == "group" then
      local group = type(value) == "table" and value or {}
      for _, field in ipairs(decl.fields or {}) do
        local fieldValue = value == MIXED and MIXED or group[field.name]
        if fieldValue == nil then
          fieldValue = field.default
        end
        rows(state, subject, inner, id .. "." .. field.name, field, fieldValue, function(new)
          local whole = copy(group)
          whole[field.name] = new
          set(whole)
        end)
      end
    else
      local list = type(value) == "table" and value or {}
      for i, item in ipairs(list) do
        rows(state, subject, inner, id .. "." .. i, decl.item or { kind = "string" }, item, function(new)
          local whole = copy(list)
          if new == nil then
            table.remove(whole, i)
          else
            whole[i] = new
          end
          set(whole)
        end, tostring(i))
        inner[#inner + 1] = ui.row({}, { ui.space(), ui.button("Remove", { id = id .. "." .. i .. ":remove", tooltip = "Take this item out of the list", onClick = function()
          local whole = copy(list)
          table.remove(whole, i)
          set(whole)
        end }) })
      end
      inner[#inner + 1] = ui.row({}, { ui.space(), ui.button("Add", { id = id .. ":add", tooltip = "Add an item to the list", onClick = function()
        local whole = copy(list)
        local item = decl.item and decl.item.default
        if item == nil then
          item = decl.item and (decl.item.kind == "string" and "" or (decl.item.kind == "number" or decl.item.kind == "integer") and 0) or ""
        end
        whole[#whole + 1] = copy(item)
        set(whole)
      end }) })
    end
    out[#out + 1] = ui.section(name, { id = id, gap = 6, tooltip = description, open = not state.folded[foldKey],
      onToggle = function(open)
        state.folded[foldKey] = not open or nil
        state.panel:redraw()
      end }, inner)
  else
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      label(name, description),
      control(state, subject, id, decl, value, set),
      mark,
    })
  end
end

-- The mark of a value that an instance's change sets: a click puts back the base's value (DESIGN 13.5).
local function resetMark(id, reset)
  return ui.button("Reset", { id = id .. ":reset", tooltip = "The instance changes this value. A click puts back the base's.", color = "accent", onClick = reset })
end

local FIELDS = {
  { "posX", "Position X" }, { "posY", "Position Y" }, { "rot", "Rotation" }, { "sclX", "Scale X" }, { "sclY", "Scale Y" }, { "z", "Z" },
}

-- The inspector's lock (DESIGN 13.4): a toggle that keeps the nodes that it shows while others are chosen.
local function lockToggle(state, file, paths)
  return ui.toggle(state.lock ~= nil, { id = "lock", label = "Lock", tooltip = "Keep showing these nodes while others are chosen",
    onChange = function(on)
      state.lock = on and { file = file, paths = format.copy(paths) } or nil
      state.panel:redraw()
    end })
end

local function fileSubject(state, out)
  local lock = state.lock
  local file = lock and lock.file or shared.file()
  local chosenPaths = lock and lock.paths or project.chosen().paths
  if lock and (project.folder() == "" or not fs.info(project.folder() .. lock.file)) then
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      ui.text("The locked node file is gone.", { style = STYLES.note, grow = 1, wrap = true }), lockToggle(state, file, chosenPaths),
    })
    return
  end
  if not file or #chosenPaths == 0 then
    out[#out + 1] = ui.text(project.folder() == "" and "No project is open." or "No node is chosen.", { style = STYLES.note })
    return
  end
  local tree = project.tree(file)
  local nodes, paths = {}, {}
  for _, path in ipairs(chosenPaths) do
    if tree.index[path] then
      nodes[#nodes + 1] = tree.index[path]
      paths[#paths + 1] = path
    end
  end
  if #nodes == 0 then
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      ui.text(tree.error or (lock and "The locked nodes are gone." or "No node is chosen."), { style = STYLES.note, wrap = true, grow = 1 }),
      lock and lockToggle(state, file, chosenPaths) or nil,
    })
    return
  end
  ---@type onlr.editor.Subject
  local subject = { file = file, paths = paths, nodes = nodes, tree = tree }
  local key = table.concat(paths, ",")
  local first = nodes[1]

  out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
    ui.text(#nodes == 1 and (first.name or "(no name)") or (#nodes .. " nodes"), { style = STYLES.title, grow = 1 }),
    lockToggle(state, file, paths),
  })
  if lock and file ~= shared.file() then
    out[#out + 1] = ui.text("Of " .. file, { style = STYLES.note })
  end
  if #nodes == 1 and first.instanceOf then
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      ui.text("Instance of " .. first.instanceOf, { style = STYLES.note, grow = 1 }),
      ui.button("Open base", { id = "openBase", tooltip = "Open the node file that this instance is of", onClick = function()
        nodeview.openFile(first.instanceOf)
      end }),
    })
  elseif #nodes == 1 and not first.own then
    out[#out + 1] = ui.text("A node of an instance's base. Its changes are the instance's.", { style = STYLES.note, wrap = true })
  end
  for _, node in ipairs(nodes) do
    for _, message in ipairs(node.errors) do
      out[#out + 1] = ui.text(message, { color = "error", wrap = true })
    end
  end
  -- A change of an instance that names no node is marked, and can be cleared (DESIGN 13.6).
  if #nodes == 1 and first.holder and first.path == first.holder.id then
    for _, unused in ipairs(tree.unused[first.path] or {}) do
      out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
        ui.text(("A change names %s, which is no node."):format(unused), { color = "error", grow = 1 }),
        ui.button("Clear", { id = "unused:" .. unused, tooltip = "Take the change out, as its node is gone", onClick = function()
          project.dropChange(file, first.path, unused)
        end }),
      })
    end
  end

  local function fieldMark(field)
    for _, node in ipairs(nodes) do
      if node.changed[field] then
        return resetMark(key .. ":" .. field, function()
          local changes = {}
          for _, other in ipairs(nodes) do
            if not other.own then
              changes[other.path] = { [field] = other.base[field] }
            end
          end
          project.setFields(file, changes, "Put back " .. field)
        end)
      end
    end
  end
  local function setField(field)
    return function(value)
      project.setField(file, paths, field, value)
    end
  end

  out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
    label("Active"),
    ui.toggle(common(nodes, function(n)
      return n.active
    end) == true, { id = key .. ":active", onChange = setField("active") }),
    fieldMark("active"),
  })
  out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
    label("Name"),
    text(key .. ":name", common(nodes, function(n)
      return n.name
    end), setField("name")),
    fieldMark("name"),
  })
  for _, field in ipairs(FIELDS) do
    local value = common(nodes, function(n)
      return n[field[1]]
    end)
    local set, decl = setField(field[1]), nil
    if field[1] == "rot" then
      decl, value, set = inDegrees({ kind = "number" }, value, set)
    end
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      label(field[2]), number(key .. ":" .. field[1], value, set, decl), fieldMark(field[1]),
    })
  end
  -- The components that all of the chosen nodes have, in the first node's order (DESIGN 5).
  local types = {}
  for typeName in pairs(first.components) do
    local all = true
    for _, node in ipairs(nodes) do
      all = all and node.components[typeName] ~= nil
    end
    if all then
      types[#types + 1] = typeName
    end
  end
  types = resolve.ordered(first.componentOrder, types)
  local orderChanged = false
  for _, node in ipairs(nodes) do
    orderChanged = orderChanged or node.changed.componentOrder == true
  end
  local known = {}
  for _, name in ipairs(project.typeNames()) do
    known[name] = true
  end

  for at, typeName in ipairs(types) do
    local info = project.typeInfo(typeName)
    local folded = state.folded[typeName]
    local cid = key .. ":" .. typeName
    local function setProperty(name)
      return function(value)
        project.setProperty(file, paths, typeName, name, value)
      end
    end
    local function valueOf(name, default)
      return common(nodes, function(n)
        local value = n.components[typeName].values[name]
        if value == nil then
          return default
        end
        return value
      end)
    end
    local function propertyMark(name)
      for _, node in ipairs(nodes) do
        local c = node.components[typeName]
        if not node.own and c.base and c.changed[name] then
          return resetMark(cid .. ":" .. name, function()
            project.setProperty(file, paths, typeName, name, nil)
          end)
        end
      end
    end

    -- A component is a section, which the user folds, and whose menu removes it; its first row turns it on and off.
    local body = {
      ui.row({ gap = 6, align = "center" }, {
        ui.toggle(valueOf("enabled", true) == true, { id = cid .. ":enabled", label = "Enabled", tooltip = "Whether the component is on", onChange = setProperty("enabled") }),
        propertyMark("enabled"),
      }),
    }
    local declared = {}
    if not known[typeName] then
      -- A type that the editor does not find shows as the node file writes it, and its values can be given to another.
      body[#body + 1] = ui.text("The project has no such type. Its values are kept.", { color = "error", wrap = true })
      local names = project.typeNames()
      body[#body + 1] = ui.row({ gap = 6, align = "center" }, {
        label("Give values to"),
        ui.dropdown(0, names, { id = cid .. ":give", grow = 1, tooltip = "Give the values to a type of the project", onSelect = function(choice)
          project.giveValues(file, paths, typeName, names[choice])
        end }),
      })
    elseif info and info.error then
      body[#body + 1] = ui.text(tostring(info.error), { color = "error", wrap = true })
    elseif not info then
      body[#body + 1] = ui.text("The preview is down, so the values show without their kinds.", { style = STYLES.note, wrap = true })
    end
    -- A property with when shows only while the properties that it names have one of their values (DESIGN 6.2); with chosen nodes
    -- of other values, it shows.
    local defaults = {}
    for _, decl in ipairs(info and info.properties or {}) do
      defaults[decl.name] = decl.default
    end
    -- Whether the component's values have the ones that a table in when's form names.
    local function holds(conditions)
      for other, wanted in pairs(conditions) do
        local value = valueOf(other, defaults[other])
        if value ~= MIXED then
          local list = type(wanted) == "table" and wanted or { wanted }
          local found = false
          for _, each in ipairs(list) do
            found = found or each == value
          end
          if not found then
            return false
          end
        end
      end
      return true
    end
    for _, decl in ipairs(info and info.properties or {}) do
      declared[decl.name] = true
      if holds(decl.options and decl.options.when or {}) then
        rows(state, subject, body, cid .. ":" .. decl.name, settleAngles(decl, holds), valueOf(decl.name, decl.default),
          setProperty(decl.name), nil, propertyMark(decl.name))
      end
    end
    -- Values of properties that the type does not declare, as the node file writes them.
    local extra = {}
    for _, node in ipairs(nodes) do
      for name in pairs(node.components[typeName].values) do
        if not declared[name] and name ~= "enabled" then
          extra[name] = true
        end
      end
    end
    local names = {}
    for name in pairs(extra) do
      names[#names + 1] = name
    end
    table.sort(names)
    local targets = {}
    for _, decl in ipairs(info and info.properties or {}) do
      targets[#targets + 1] = decl.name
    end
    for _, name in ipairs(names) do
      local value = valueOf(name)
      local shown = value == MIXED and "" or type(value) == "table" and "(a table)" or tostring(value)
      body[#body + 1] = ui.row({ gap = 6, align = "center" }, {
        label(name),
        ui.text(shown, { grow = 1, color = info and info.properties and "error" or nil }),
        (#targets > 0 and ui.dropdown(0, targets, { id = cid .. ":give:" .. name, tooltip = "Give the value to a property", onSelect = function(choice)
          project.giveValues(file, paths, typeName, typeName, name, targets[choice])
        end })) --[[@as ui.Element]],
      })
    end
    out[#out + 1] = ui.section(typeName, { id = cid, gap = 6, open = not folded,
      onToggle = function(open)
        state.folded[typeName] = not open or nil
        state.panel:redraw()
      end,
      onMenu = function(x, y)
        local script = project.typeFile(typeName)
        ui.menu(state.panel, x, y, {
          -- the type's script opens in the code editor, as the console's links do (DESIGN 13.4)
          { label = "Open script", enabled = script ~= "", onClick = function()
            console.open(script, 1)
          end },
          { line = true },
          -- The order is the node file's, in which the components run too (DESIGN 5).
          { label = "Move up", enabled = at > 1, onClick = function()
            project.moveComponent(file, paths, typeName, -1)
          end },
          { label = "Move down", enabled = at < #types, onClick = function()
            project.moveComponent(file, paths, typeName, 1)
          end },
          { label = "Put back the base's order", enabled = orderChanged, onClick = function()
            local changes = {}
            for _, node in ipairs(nodes) do
              if not node.own then
                changes[node.path] = { componentOrder = node.base.componentOrder }
              end
            end
            project.setFields(file, changes, "Put back the order")
          end },
          { line = true },
          -- Copy keeps the first chosen node's values of the component, which Paste gives to a component of the same type.
          { label = "Copy values", enabled = #nodes == 1, onClick = function()
            copied = { type = typeName, values = format.copy(first.components[typeName].values) }
          end },
          { label = "Paste values", enabled = copied ~= nil and copied.type == typeName, onClick = function()
            if copied then
              project.pasteValues(file, paths, typeName, copied.values)
            end
          end },
          { line = true },
          { label = "Remove component", onClick = function()
            local _, message = project.removeComponent(file, paths, typeName)
            if message then
              console.add(message, "warn", nil, "onlr")
            end
          end },
        })
      end }, body)
  end

  -- Adding a component offers the project's types that the nodes lack (DESIGN 13.4).
  local offered = {}
  for _, name in ipairs(project.typeNames()) do
    if not first.components[name] then
      offered[#offered + 1] = name
    end
  end
  out[#out + 1] = ui.separator()
  out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
    label("Add component"),
    -- the types are in folders by their names' dots, onlr, then camera, then view, as Unity's groups; a search finds them in any folder
    ui.dropdown(0, offered, { id = key .. ":addComponent", grow = 1, folders = ".", tooltip = "A type of the project that the nodes lack", onSelect = function(choice)
      project.addComponent(file, paths, offered[choice])
    end }),
  })
end

-- The running game's chosen node: a change is sent to the game, and is gone at Stop (DESIGN 12.6).
local function runningSubject(state, out)
  local running = nodeview.running()
  local node
  for _, n in ipairs(running.values or {}) do
    if n.n == shared.runningNode then
      node = n
    end
  end
  out[#out + 1] = ui.text("The running game. A change here is gone at Stop.", { style = STYLES.note, wrap = true })
  if not node then
    out[#out + 1] = ui.text("No running node is chosen.", { style = STYLES.note })
    return
  end
  local key = "run" .. node.n
  local function setField(field)
    return function(value)
      nodeview.set({ node = node.n, field = field, value = value })
    end
  end
  out[#out + 1] = ui.text(node.name or "(no name)", { style = STYLES.title })
  out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
    label("Active"), ui.toggle(node.active == true, { id = key .. ":active", tooltip = "Whether the node runs and draws", onChange = setField("active") }),
  })
  out[#out + 1] = ui.row({ gap = 6, align = "center" }, { label("Name"), text(key .. ":name", node.name, setField("name")) })
  for _, field in ipairs(FIELDS) do
    local value, set = node[field[1]], setField(field[1])
    if field[1] == "rot" then
      value = math.floor(math.deg(value) * 1000 + 0.5) / 1000
      local inner = set
      set = function(degrees)
        inner(math.rad(degrees))
      end
    end
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, { label(field[2]), number(key .. ":" .. field[1], value, set) })
  end
  local types = {}
  for typeName in pairs(node.components or {}) do
    types[#types + 1] = typeName
  end
  table.sort(types)
  local VALUES = { bool = true, integer = true, number = true, string = true, choice = true, color = true, vector = true }
  for _, typeName in ipairs(types) do
    local values = node.components[typeName]
    local info = project.typeInfo(typeName)
    local cid = key .. ":" .. typeName
    out[#out + 1] = ui.separator()
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      ui.text(typeName, { style = STYLES.heading, grow = 1 }),
      ui.toggle(values.enabled == true, { id = cid .. ":enabled", tooltip = "Whether the component is on", onChange = function(on)
        nodeview.set({ node = node.n, component = typeName, property = "enabled", value = on })
      end }),
    })
    for _, decl in ipairs(info and info.properties or {}) do
      local value = values[decl.name]
      if VALUES[decl.kind] then
        out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
          label(decl.options and decl.options.label or shared.words(decl.name)),
          control(state, { tree = { index = {} } }, cid .. ":" .. decl.name, decl, value, function(new)
            nodeview.set({ node = node.n, component = typeName, property = decl.name, value = new })
          end),
        })
      else
        local shown = type(value) == "table" and (value.path or "(a table)") or value == nil and "(none)" or tostring(value)
        out[#out + 1] = ui.row({ gap = 6 }, { label(shared.words(decl.name)), ui.text(shown, { grow = 1 }) })
      end
    end
  end
end

-- What a kind of file is called, by its extension.
local KINDS = {
  png = "Image", jpg = "Image", jpeg = "Image", bmp = "Image", tga = "Image",
  ogg = "Sound", wav = "Sound", mp3 = "Sound", flac = "Sound", ttf = "Font", otf = "Font",
}

-- A file that the files panel chose: its name, its kind, its size, and a node file's nodes (DESIGN 13.7).
local function chosenFileSubject(out)
  local path = assert(shared.chosenFile)
  local kind = path:match("^nodes/.+%.lua$") and "Node file" or path:match("%.lua$") and "Script"
    or KINDS[(path:match("%.([^./]+)$") or ""):lower()] or "File"
  local info = fs.info(project.folder() .. path)
  out[#out + 1] = ui.text(path:match("[^/]*$"), { style = STYLES.title })
  local rows = { { "Path", path }, { "Kind", kind } }
  if info and info.type == "file" then
    rows[#rows + 1] = { "Size", info.size < 1024 and ("%d bytes"):format(info.size) or ("%.1f KB"):format(info.size / 1024) }
  end
  if kind == "Node file" and project.file(path) then
    local count = 0
    for _ in pairs(project.tree(path).index) do
      count = count + 1
    end
    rows[#rows + 1] = { "Nodes", tostring(count) }
  end
  for _, row in ipairs(rows) do
    out[#out + 1] = ui.row({ gap = 6 }, { label(row[1]), ui.text(row[2], { grow = 1, wrap = true }) })
  end
  out[#out + 1] = ui.text("A double click in the files panel opens it.", { style = STYLES.note })
end

local function draw(state, surface)
  state.drops = {}
  state.scale = surface.scale
  local out = {}
  if state.lock then
    fileSubject(state, out)
  elseif shared.running and nodeview.running().playing then
    runningSubject(state, out)
  elseif shared.chosenFile then
    chosenFileSubject(out)
  else
    fileSubject(state, out)
  end
  local root = ui.scroll({ id = "inspector", padding = 8, gap = 6 }, out)
  ui.show(state.panel, surface, root)
  state.shown = root
end

-- The rectangles of the elements that have ids, in the panel's pixels, as the last draw laid them out, for a test (DESIGN 16).
local function rects(state)
  local found = {}
  local function walk(element)
    if element.id and not element.id:match("^root%.") then
      local r = ui.rect(state.panel, element.id)
      found[element.id] = r and { x = r.x, y = r.y, width = r.width, height = r.height }
    end
    for _, child in ipairs(element.children or {}) do
      walk(child)
    end
  end
  if state.shown then
    walk(state.shown)
  end
  return found
end

-- A file or a node dropped on a reference's row sets it (DESIGN 13.4).
local function drop(state, event)
  local x, y = event.x / state.scale, event.y / state.scale
  for _, row in ipairs(state.drops) do
    local rect = ui.rect(state.panel, row.id)
    if rect and row.type == event.dataType and x >= rect.x - 120 and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height then
      if row.type == "file-list" then
        local path = type(event.value) == "table" and tostring(event.value[1] or ""):gsub("\\", "/") or ""
        local ending = (path:match("%.(%w+)$") or ""):lower()
        local fits = path ~= "" and not row.extensions
        for _, extension in ipairs(row.extensions or {}) do
          fits = fits or extension:lower() == ending
        end
        local inside
        if fits and row.nodeFile then
          -- a node file must be one of the project's already
          local folder = project.folder()
          inside = path:sub(1, #folder) == folder and path:sub(#folder + 1) or nil
          if not (inside and inside:match("^nodes/.+%.lua$")) then
            console.add(("%s is no node file of the project's nodes/ folder."):format(path), "warn", nil, "onlr")
            inside = nil
          end
        elseif fits then
          -- a file from outside the project is copied in first, after asking, as a drop on a node view does (DESIGN 13.4)
          inside = project.bringIn(path)
        elseif path ~= "" then
          console.add(("%s is not a file that this row takes."):format(path), "warn", nil, "onlr")
        end
        if inside then
          row.set(inside)
        end
      elseif type(event.value) == "table" then
        -- a reference names a node of the file of the inspector's nodes, also while the inspector is locked on another file
        local node = event.value.file == row.file and row.tree.index[event.value.path]
        if node and (not row.needs or node.components[row.needs]) then
          row.set(event.value.path)
        elseif node then
          console.add(("The node %s has no component %s."):format(node.name or node.path, row.needs), "warn", nil, "onlr")
        else
          console.add(("A reference names a node of %s, the file of the inspector's nodes."):format(tostring(row.file)), "warn", nil, "onlr")
        end
      end
      return
    end
  end
end

-- A row's Pick shows that it waits, and the waiting ends when a node is clicked.
ecs.event.subscribe("onlr.picking", function()
  shared.redraw()
end)

ecs.panel.registerType({
  name = "inspector",
  title = "Inspector",
  stateVersion = STATE_VERSION,
  create = function(panel, saved, version)
    local state = { panel = panel, folded = {}, drops = {}, scale = 1 }
    shared.inspectors[panel] = true
    if version == STATE_VERSION and type(saved) == "table" then
      state.folded = saved.folded or {}
      state.lock = type(saved.lock) == "table" and type(saved.lock.file) == "string" and type(saved.lock.paths) == "table" and saved.lock or nil
    end
    panel:acceptDrops({ "file-list", "onlr.node" })
    shared.follow(panel, {
      "onlr.opened", "onlr.closed", "onlr.changed", "onlr.chosen", "onlr.tool", "onlr.types", "onlr.saved", "onlr.settings", "onlr.state",
      "onlr.running:tree", "onlr.running:values",
    })
    return state
  end,
  draw = draw,
  event = function(state, event)
    if event.type == "drop" then
      drop(state, event)
    else
      ui.event(state.panel, event)
    end
  end,
  saveState = function(state)
    -- The file that it shows is not read back; a test reads it here.
    return { folded = state.folded, lock = state.lock, file = shared.chosenFile, rects = rects(state) }
  end,
  destroy = function(state)
    shared.inspectors[state.panel] = nil
    shared.forget(state.panel)
    ui.forget(state.panel)
  end,
})
