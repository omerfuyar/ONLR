-- The inspector (DESIGN 13.4): the chosen nodes' own fields, then each of their components under its type's name,
-- with one row for each property and the control of its kind (DESIGN 6.2).

local ecs = require("ecs")
local ui = require("ui")
local fs = require("fs")
local project = require("onlr_project")
local player = require("onlr_player")
local console = require("console")
local shared = require("shared")

local STYLES = ui.styles()
local STATE_VERSION = 1
local RED = "#e06c75"

-- A value that differs among the chosen nodes: its control shows empty.
local MIXED = {}

local function same(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then
    return a == b
  end
  for k, v in pairs(a) do
    if not same(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

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

local function copy(value)
  if type(value) ~= "table" then
    return value
  end
  local c = {}
  for k, v in pairs(value) do
    c[k] = copy(v)
  end
  return c
end

local function label(text, tooltip)
  return ui.text(text, { width = 110, tooltip = tooltip })
end

-- A number's control: a number field, or an empty text field while the nodes differ.
local function number(id, value, set, decl)
  local options = decl and decl.options or {}
  if value == MIXED or type(value) ~= "number" then
    return ui.field("", { id = id, grow = 1, onSubmit = function(text)
      local n = tonumber(text)
      if n then
        set(n)
      end
    end })
  end
  return ui.number(value, {
    id = id, grow = 1, min = options.min, max = options.max, step = decl and decl.kind == "integer" and 1 or nil,
    onSubmit = set,
  })
end

local function text(id, value, set, valid)
  return ui.field(value ~= MIXED and type(value) == "string" and value or "", { id = id, grow = 1, valid = valid, onSubmit = function(new)
    set(new)
  end })
end

---What an inspector shows: the chosen nodes of a node file.
---@class onlr_views.Subject
---@field file string
---@field paths string[]
---@field nodes onlr_project.Node[]
---@field tree onlr_project.Tree

-- The control of a property's kind. set gets the new value; drops notes the rows that take a dragged file or node.
local function control(state, subject, id, decl, value, set)
  local kind = decl.kind
  local options = decl.options or {}
  if kind == "bool" then
    return ui.toggle(value == true, { id = id, onChange = set })
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
    return ui.dropdown(selected, choices, { id = id, grow = 1, onSelect = function(choice)
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
      parts[5] = ui.space({ width = 18, height = 18, grow = 0, border = "textDim",
        background = ("#%02x%02x%02x%02x"):format(byte(color[1]), byte(color[2]), byte(color[3]), byte(color[4])) })
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
  elseif kind == "image" or kind == "sound" or kind == "file" or kind == "nodeFile" then
    -- A file is set by dragging it from the files panel onto the row, or by typing its path.
    local known = value == nil or value == MIXED or value == "" or fs.info(project.folder() .. tostring(value)) ~= nil
    state.drops[#state.drops + 1] = { id = id, type = "file-list", set = set, extensions = options.extensions, nodeFile = kind == "nodeFile" }
    return text(id, value, function(new)
      set(new ~= "" and new or nil)
    end, known)
  elseif kind == "font" then
    local font = type(value) == "table" and value or {}
    local known = not font.path or fs.info(project.folder() .. tostring(font.path)) ~= nil
    state.drops[#state.drops + 1] = { id = id, type = "file-list", set = function(path)
      set({ path = path, size = font.size or options.size or 12 })
    end }
    return ui.row({ gap = 4, grow = 1 }, {
      text(id, value ~= MIXED and font.path or MIXED, function(new)
        set({ path = new ~= "" and new or nil, size = font.size or options.size or 12 })
      end, known),
      number(id .. ":size", value ~= MIXED and (font.size or options.size or 12) or MIXED, function(n)
        set({ path = font.path, size = n })
      end),
    })
  elseif kind == "node" or kind == "component" then
    -- A node is set by dragging it from the nodes panel onto the row.
    local named = type(value) == "string" and subject.tree.index[value]
    local shown = value == MIXED and "" or named and (named.name or value) or value and (tostring(value) .. " (no such node)") or "(none)"
    state.drops[#state.drops + 1] = { id = id, type = "onlr.node", set = set, needs = kind == "component" and decl.type or nil, tree = subject.tree }
    return ui.row({ id = id, gap = 4, grow = 1, align = "center" }, {
      ui.text(shown, { grow = 1, color = value and value ~= MIXED and not named and RED or nil }),
      (value ~= nil and ui.button("Clear", { id = id .. ":clear", onClick = function()
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
  if decl.kind == "group" then
    out[#out + 1] = ui.row({ gap = 6 }, { ui.text(name, { style = STYLES.heading, tooltip = description, grow = 1 }), mark })
    local group = type(value) == "table" and value or {}
    for _, field in ipairs(decl.fields or {}) do
      local fieldValue = value == MIXED and MIXED or group[field.name]
      if fieldValue == nil then
        fieldValue = field.default
      end
      rows(state, subject, out, id .. "." .. field.name, field, fieldValue, function(new)
        local whole = copy(group)
        whole[field.name] = new
        set(whole)
      end)
    end
  elseif decl.kind == "list" then
    local list = type(value) == "table" and value or {}
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      ui.text(name, { style = STYLES.heading, tooltip = description, grow = 1 }),
      mark,
      ui.button("Add", { id = id .. ":add", onClick = function()
        local whole = copy(list)
        local item = decl.item and decl.item.default
        if item == nil then
          item = decl.item and (decl.item.kind == "string" and "" or (decl.item.kind == "number" or decl.item.kind == "integer") and 0) or ""
        end
        whole[#whole + 1] = copy(item)
        set(whole)
      end }),
    })
    for i, item in ipairs(list) do
      local inner = {}
      rows(state, subject, inner, id .. "." .. i, decl.item or { kind = "string" }, item, function(new)
        local whole = copy(list)
        if new == nil then
          table.remove(whole, i)
        else
          whole[i] = new
        end
        set(whole)
      end, tostring(i))
      inner[#inner + 1] = ui.row({}, { ui.space(), ui.button("Remove", { id = id .. "." .. i .. ":remove", onClick = function()
        local whole = copy(list)
        table.remove(whole, i)
        set(whole)
      end }) })
      for _, element in ipairs(inner) do
        out[#out + 1] = element
      end
    end
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

local function fileSubject(state, out)
  local file = shared.file()
  local chosen = project.chosen()
  if not file or #chosen.paths == 0 then
    out[#out + 1] = ui.text(project.folder() == "" and "No project is open." or "No node is chosen.", { style = STYLES.note })
    return
  end
  local tree = project.tree(file)
  local nodes, paths = {}, {}
  for _, path in ipairs(chosen.paths) do
    if tree.index[path] then
      nodes[#nodes + 1] = tree.index[path]
      paths[#paths + 1] = path
    end
  end
  if #nodes == 0 then
    out[#out + 1] = ui.text(tree.error or "No node is chosen.", { style = STYLES.note, wrap = true })
    return
  end
  ---@type onlr_views.Subject
  local subject = { file = file, paths = paths, nodes = nodes, tree = tree }
  local key = table.concat(paths, ",")
  local first = nodes[1]

  out[#out + 1] = ui.text(#nodes == 1 and (first.name or "(no name)") or (#nodes .. " nodes"), { style = STYLES.title })
  if #nodes == 1 and first.instanceOf then
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      ui.text("Instance of " .. first.instanceOf, { style = STYLES.note, grow = 1 }),
      ui.button("Open base", { id = "openBase", onClick = function()
        player.openFile(first.instanceOf)
      end }),
    })
  elseif #nodes == 1 and not first.own then
    out[#out + 1] = ui.text("A node of an instance's base. Its changes are the instance's.", { style = STYLES.note, wrap = true })
  end
  for _, node in ipairs(nodes) do
    for _, message in ipairs(node.errors) do
      out[#out + 1] = ui.text(message, { color = RED, wrap = true })
    end
  end
  -- A change of an instance that names no node is marked, and can be cleared (DESIGN 13.6).
  if #nodes == 1 and first.holder and first.path == first.holder.id then
    for _, unused in ipairs(tree.unused[first.path] or {}) do
      out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
        ui.text(("A change names %s, which is no node."):format(unused), { color = RED, grow = 1 }),
        ui.button("Clear", { id = "unused:" .. unused, onClick = function()
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
    local set = setField(field[1])
    if field[1] == "rot" then
      -- The inspector shows the angle in degrees; the file keeps LÖVE's radians.
      if value ~= MIXED then
        value = math.floor(math.deg(value) * 1000 + 0.5) / 1000
      end
      local inner = set
      set = function(degrees)
        inner(math.rad(degrees))
      end
    end
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      label(field[2]), number(key .. ":" .. field[1], value, set), fieldMark(field[1]),
    })
  end
  out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
    label("Active"),
    ui.toggle(common(nodes, function(n)
      return n.active
    end) == true, { id = key .. ":active", onChange = setField("active") }),
    fieldMark("active"),
  })

  -- The components that all of the chosen nodes have, in the order of their names.
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
  table.sort(types)
  local known = {}
  for _, name in ipairs(project.typeNames()) do
    known[name] = true
  end

  for _, typeName in ipairs(types) do
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

    out[#out + 1] = ui.separator()
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      ui.button(folded and "+" or "-", { id = cid .. ":fold", onClick = function()
        state.folded[typeName] = not folded or nil
        state.panel:redraw()
      end }),
      ui.text(typeName, { style = STYLES.heading, grow = 1, color = not known[typeName] and RED or nil }),
      ui.toggle(valueOf("enabled", true) == true, { id = cid .. ":enabled", tooltip = "Whether the component is on", onChange = setProperty("enabled") }),
      propertyMark("enabled"),
      ui.button("Remove", { id = cid .. ":remove", onClick = function()
        local _, message = project.removeComponent(file, paths, typeName)
        if message then
          console.add(message, "warn")
        end
      end }),
    })
    if not folded then
      local declared = {}
      if not known[typeName] then
        -- A type that the editor does not find shows as the node file writes it, and its values can be given to another.
        out[#out + 1] = ui.text("The project has no such type. Its values are kept.", { color = RED, wrap = true })
        local names = project.typeNames()
        out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
          label("Give values to"),
          ui.dropdown(0, names, { id = cid .. ":give", grow = 1, onSelect = function(choice)
            project.giveValues(file, paths, typeName, names[choice])
          end }),
        })
      elseif info and info.error then
        out[#out + 1] = ui.text(tostring(info.error), { color = RED, wrap = true })
      elseif not info then
        out[#out + 1] = ui.text("The edit player is down, so the values show without their kinds.", { style = STYLES.note, wrap = true })
      end
      for _, decl in ipairs(info and info.properties or {}) do
        declared[decl.name] = true
        rows(state, subject, out, cid .. ":" .. decl.name, decl, valueOf(decl.name, decl.default), setProperty(decl.name), nil,
          propertyMark(decl.name))
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
        out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
          label(name),
          ui.text(shown, { grow = 1, color = info and info.properties and RED or nil }),
          (#targets > 0 and ui.dropdown(0, targets, { id = cid .. ":give:" .. name, tooltip = "Give the value to a property", onSelect = function(choice)
            project.giveValues(file, paths, typeName, typeName, name, targets[choice])
          end })) --[[@as ui.Element]],
        })
      end
    end
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
    ui.dropdown(0, offered, { id = key .. ":addComponent", grow = 1, onSelect = function(choice)
      project.addComponent(file, paths, offered[choice])
    end }),
  })
end

-- The running game's chosen node: a change is sent to the play player, and is gone at Stop (DESIGN 12.6).
local function runningSubject(state, out)
  local running = player.running()
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
      player.set({ node = node.n, field = field, value = value })
    end
  end
  out[#out + 1] = ui.text(node.name or "(no name)", { style = STYLES.title })
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
  out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
    label("Active"), ui.toggle(node.active == true, { id = key .. ":active", onChange = setField("active") }),
  })
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
      ui.toggle(values.enabled == true, { id = cid .. ":enabled", onChange = function(on)
        player.set({ node = node.n, component = typeName, property = "enabled", value = on })
      end }),
    })
    for _, decl in ipairs(info and info.properties or {}) do
      local value = values[decl.name]
      if VALUES[decl.kind] then
        out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
          label(decl.options and decl.options.label or shared.words(decl.name)),
          control(state, { tree = { index = {} } }, cid .. ":" .. decl.name, decl, value, function(new)
            player.set({ node = node.n, component = typeName, property = decl.name, value = new })
          end),
        })
      else
        local shown = type(value) == "table" and (value.path or "(a table)") or value == nil and "(none)" or tostring(value)
        out[#out + 1] = ui.row({ gap = 6 }, { label(shared.words(decl.name)), ui.text(shown, { grow = 1 }) })
      end
    end
  end
end

local function draw(state, surface)
  state.drops = {}
  state.scale = surface.scale
  local out = {}
  if shared.running and player.running().playing then
    runningSubject(state, out)
  else
    fileSubject(state, out)
  end
  ui.show(state.panel, surface, ui.scroll({ id = "inspector", padding = 8, gap = 6 }, out))
end

-- A file or a node dropped on a reference's row sets it (DESIGN 13.4).
local function drop(state, event)
  local x, y = event.x / state.scale, event.y / state.scale
  for _, row in ipairs(state.drops) do
    local rect = ui.rect(state.panel, row.id)
    if rect and row.type == event.dataType and x >= rect.x - 120 and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height then
      if row.type == "file-list" then
        local folder = project.folder()
        local path = type(event.value) == "table" and tostring(event.value[1] or ""):gsub("\\", "/") or ""
        if path:sub(1, #folder) == folder then
          path = path:sub(#folder + 1)
          local ending = (path:match("%.(%w+)$") or ""):lower()
          local fits = not row.extensions
          for _, extension in ipairs(row.extensions or {}) do
            fits = fits or extension:lower() == ending
          end
          if row.nodeFile and not path:match("^nodes/.+%.lua$") then
            fits = false
          end
          if fits then
            row.set(path)
          end
        end
      elseif type(event.value) == "table" and event.value.file == shared.file() then
        local node = row.tree.index[event.value.path]
        if node and (not row.needs or node.components[row.needs]) then
          row.set(event.value.path)
        elseif node then
          console.add(("The node %s has no component %s."):format(node.name or node.path, row.needs), "warn")
        end
      end
      return
    end
  end
end

ecs.panel.registerType({
  name = "inspector",
  title = "Inspector",
  stateVersion = STATE_VERSION,
  create = function(panel, saved, version)
    local state = { panel = panel, folded = {}, drops = {}, scale = 1 }
    if version == STATE_VERSION and type(saved) == "table" then
      state.folded = saved.folded or {}
    end
    panel:acceptDrops({ "file-list", "onlr.node" })
    shared.follow(panel)
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
    return { folded = state.folded }
  end,
  destroy = function(state)
    shared.forget(state.panel)
    ui.forget(state.panel)
  end,
})
