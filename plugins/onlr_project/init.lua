-- The open project (DESIGN 13.1): its manifest, its node files, the chosen nodes, the chosen tool and the history.
-- It reads and writes the files, and watches the folder. Panels show the project, change it through these functions,
-- and hear of changes through its events. No panel is here.

local ecs = require("ecs")
local fs = require("fs")
local process = require("process")
local format = require("format")
local resolve = require("resolve")

---A data file of the project, as the editor holds it.
---@class onlr_project.File
---@field path string its path in the project, such as "nodes/level.lua"
---@field kind "node"|"manifest"
---@field data table? its table. Nil when the file does not load
---@field error string? why it does not load
---@field disk string? the file's text on disk, as the editor last read or wrote it
---@field saved string? what the editor writes for the table on disk
---@field dirty boolean it has changes that are not saved
---@field handwritten boolean a person wrote its text, so a save asks first (DESIGN 4.2)
---@field missing boolean? the project has no such file

---A change that can be undone: the tables of the files that it changed, before and after (DESIGN 13.6).
---@class onlr_project.Record
---@field label string
---@field files table<string, {before: table?, after: table?}>

---@class onlr_project.Project
---@field folder string the project's folder, ending with a slash
---@field files table<string, onlr_project.File>
---@field history onlr_project.Record[]
---@field position integer how many records of the history are done
---@field chosen {file: string?, paths: string[]}
---@field tool "move"|"turn"|"scale"
---@field settings table what the editor keeps for the project in .onlr/
---@field space table the names that components can hold
---@field typeNames string[]
---@field typeFiles table<string, string>
---@field types table<string, table> what the edit player answered of each type
---@field trees table<string, onlr_project.Tree>
---@field watches table<string, any>
---@field touch (fun(path: string))?

---@type onlr_project.Project?
local P

local recent = {} ---@type string[] the folders of the projects opened last

for _, name in ipairs({ "opened", "closed", "changed", "chosen", "tool", "types", "saved", "disk", "said", "settings", "renamed" }) do
  ecs.event.declare(name)
end

local function say(text)
  ecs.log.info(text)
  ecs.event.emit("onlr_project.said", text)
end

local function absolute(path)
  return assert(P).folder .. path
end

local function isNodeFile(path)
  return path:match("^nodes/.+%.lua$") ~= nil
end

-- Every file under a folder of the project, apart from what starts with a dot.
local function walk(dir, visit, folders)
  for _, entry in ipairs(fs.list(absolute(dir), "") or {}) do
    if entry.name:sub(1, 1) ~= "." then
      local path = dir == "" and entry.name or (dir .. "/" .. entry.name)
      if entry.type == "folder" then
        if folders then
          folders(path)
        end
        walk(path, visit, folders)
      else
        visit(path)
      end
    end
  end
end

-- Files

local function refresh(file)
  if file.data then
    file.dirty = format.write(file.data, file.kind) ~= file.saved
  else
    file.dirty = false
  end
end

-- Gives one of two nodes that share an id a new one (DESIGN 4.2).
local function fixIds(file)
  local taken, twice = {}, {}
  local function entry(e)
    if type(e) ~= "table" then
      return
    end
    if type(e.id) == "string" then
      if taken[e.id] then
        twice[#twice + 1] = e
      end
      taken[e.id] = true
    end
    for _, child in ipairs(type(e.children) == "table" and e.children or {}) do
      entry(child)
    end
    if type(e.instance) == "table" and type(e.instance.changes) == "table" then
      for _, change in pairs(e.instance.changes) do
        for _, child in ipairs(type(change) == "table" and type(change.children) == "table" and change.children or {}) do
          entry(child)
        end
      end
    end
  end
  entry(file.data)
  for _, e in ipairs(twice) do
    local old = e.id
    e.id = format.newId(taken)
    taken[e.id] = true
    say(("%s: the id %s was there twice, so one node is now %s"):format(file.path, old, e.id))
  end
end

local function readFile(path)
  local kind = path == "manifest.lua" and "manifest" or "node"
  ---@type onlr_project.File
  local file = { path = path, kind = kind, dirty = false, handwritten = false }
  local text = format.readFile(absolute(path))
  if not text then
    file.error = path .. ": no such file"
    file.missing = true
    return file
  end
  file.disk = text
  local data, err = format.read(text, path)
  if not data then
    file.error = err
    return file
  end
  file.data = data
  file.saved = format.write(data, kind)
  file.handwritten = text:gsub("\r\n", "\n") ~= file.saved
  if kind == "node" then
    fixIds(file)
    refresh(file)
  end
  return file
end

---@return onlr_project.File?
local function getFile(path)
  if not P then
    return nil
  end
  local file = P.files[path]
  if not file and (isNodeFile(path) or path == "manifest.lua") then
    file = readFile(path)
    P.files[path] = file
  end
  return file
end

---@type onlr_project.Source
local source = {
  file = function(path)
    local file = getFile(path)
    if not file then
      return nil, path .. ": not a node file"
    end
    return file.data, file.error
  end,
  space = {},
  properties = function(typeName)
    local info = P and P.types[typeName]
    return info and info.properties
  end,
}

local function tree(path)
  local p = assert(P)
  local t = p.trees[path]
  if not t then
    t = resolve.tree(path, source)
    p.trees[path] = t
  end
  return t
end

-- Component types

local function scanTypes()
  local p = assert(P)
  local space, names, files = {}, {}, {}
  local function scan(dir, into, prefix)
    for _, entry in ipairs(fs.list(absolute(dir), "") or {}) do
      local name = entry.name:match("^(.*)%.lua$")
      if entry.type == "file" and name and format.isName(name) then
        into[name] = true
        names[#names + 1] = prefix .. name
        files[prefix .. name] = dir .. "/" .. entry.name
      elseif entry.type == "folder" and format.isName(entry.name) then
        if fs.info(absolute(dir .. "/" .. entry.name .. "/init.lua")) then
          into[entry.name] = true
          names[#names + 1] = prefix .. entry.name
          files[prefix .. entry.name] = dir .. "/" .. entry.name .. "/init.lua"
        elseif into[entry.name] == nil then
          into[entry.name] = {}
          scan(dir .. "/" .. entry.name, into[entry.name], prefix .. entry.name .. ".")
        end
      end
    end
  end
  scan("components", space, "")
  for _, entry in ipairs(fs.list(absolute("packages"), "") or {}) do
    if entry.type == "folder" and format.isName(entry.name) and fs.info(absolute("packages/" .. entry.name .. "/components")) then
      if space[entry.name] == nil then
        space[entry.name] = {}
        scan("packages/" .. entry.name .. "/components", space[entry.name], entry.name .. ".")
      end
    end
  end
  table.sort(names)
  local changed = not format.same(names, p.typeNames)
  p.space, p.typeNames, p.typeFiles = space, names, files
  source.space = space
  p.trees = {}
  if changed then
    -- A definition of node.components, so a code editor knows what node.components.player is (DESIGN 4.3).
    local lines = { "---@meta", "-- The project's component types. The editor writes this file.", "", "---@class onlr.Components" }
    local function fields(t, prefix)
      local keys = {}
      for key in pairs(t) do
        keys[#keys + 1] = key
      end
      table.sort(keys)
      local parts = {}
      for _, key in ipairs(keys) do
        if t[key] == true then
          parts[#parts + 1] = ("%s: %s?"):format(key, prefix .. key)
        else
          parts[#parts + 1] = ("%s: {%s}"):format(key, fields(t[key], prefix .. key .. "."))
        end
      end
      return table.concat(parts, ", "), keys
    end
    local _, keys = fields(space, "")
    for _, key in ipairs(keys) do
      if key ~= "onlr" then
        if space[key] == true then
          lines[#lines + 1] = ("---@field %s %s?"):format(key, key)
        else
          lines[#lines + 1] = ("---@field %s {%s}"):format(key, (fields(space[key], key .. ".")))
        end
      end
    end
    fs.makeFolder(absolute(".onlr"))
    format.writeFile(absolute(".onlr/components.lua"), table.concat(lines, "\n") .. "\n")
  end
  return changed
end

-- The history

local function emitChanged(paths, history)
  local p = assert(P)
  p.trees = {}
  for _, path in ipairs(paths) do
    local file = p.files[path]
    if file then
      refresh(file)
    end
  end
  ecs.event.emit("onlr_project.changed", { files = paths, history = history or false })
end

-- Takes out of the history every record that changed a file, when the file goes back to what is on disk (DESIGN 13.6).
local function dropHistory(path)
  local p = assert(P)
  local kept, position = {}, 0
  for i, record in ipairs(p.history) do
    if not record.files[path] then
      kept[#kept + 1] = record
      if i <= p.position then
        position = position + 1
      end
    end
  end
  p.history, p.position = kept, position
end

---Makes one change of the history: fn changes the files' tables, after telling which with touch.
---@param label string what the change is, such as "Move"
---@param fn fun(touch: fun(path: string): table?) touch gives a file's table, and notes how it was
---@return boolean changed whether anything changed
local function edit(label, fn)
  local p = assert(P)
  local before = {}
  local function touch(path)
    local file = getFile(path)
    if before[path] == nil then
      before[path] = file and file.data and format.copy(file.data) or false
    end
    return file and file.data
  end
  local ok, err = pcall(fn, touch)
  if not ok then
    for path, old in pairs(before) do
      if old and p.files[path] then
        p.files[path].data = old
      end
    end
    p.trees = {}
    error(err, 0)
  end
  ---@type onlr_project.Record
  local record = { label = label, files = {} }
  local paths = {}
  for path, old in pairs(before) do
    local file = p.files[path]
    local after = file and file.data
    if not format.same(old or nil, after) then
      record.files[path] = { before = old or nil, after = format.copy(after) }
      paths[#paths + 1] = path
    end
  end
  if #paths == 0 then
    p.trees = {}
    return false
  end
  table.sort(paths)
  for i = #p.history, p.position + 1, -1 do
    p.history[i] = nil
  end
  p.history[#p.history + 1] = record
  p.position = #p.history
  emitChanged(paths)
  return true
end

local function step(record, field)
  local p = assert(P)
  local paths = {}
  for path, change in pairs(record.files) do
    -- Undoing a change that made a file leaves the file (DESIGN 13.5).
    if change[field] then
      local file = getFile(path)
      if file then
        file.data = format.copy(change[field])
        file.error = nil
        paths[#paths + 1] = path
      end
    end
  end
  table.sort(paths)
  -- A node that the change took away is no longer chosen.
  emitChanged(paths, true)
  if p.chosen.file then
    local t = tree(p.chosen.file)
    local kept = {}
    for _, path in ipairs(p.chosen.paths) do
      if t.index[path] then
        kept[#kept + 1] = path
      end
    end
    if #kept ~= #p.chosen.paths then
      p.chosen.paths = kept
      ecs.event.emit("onlr_project.chosen", p.chosen)
    end
  end
end

-- Saving

local function saveFile(file)
  if not file.dirty or not file.data then
    return true
  end
  if file.handwritten then
    local answer = ecs.dialog.showMessage("Save " .. file.path,
      file.path .. " holds code or comments that a person wrote. Saving writes its values only, and they are lost.",
      { "Replace", "Keep the file" })
    if answer ~= 1 then
      return false
    end
  end
  local text = format.write(file.data, file.kind)
  local folder = file.path:match("^(.*)/[^/]*$")
  if folder then
    fs.makeFolder(absolute(folder))
  end
  local ok, err = format.writeFile(absolute(file.path), text)
  if not ok then
    say(("%s is not saved: %s"):format(file.path, tostring(err)))
    return false
  end
  file.disk, file.saved, file.dirty, file.handwritten = text, text, false, false
  return true
end

local function saveAll()
  local p = P
  if not p then
    return true
  end
  local paths, all = {}, true
  for path, file in pairs(p.files) do
    if file.dirty then
      if saveFile(file) then
        paths[#paths + 1] = path
      else
        all = false
      end
    end
  end
  if #paths > 0 then
    table.sort(paths)
    ecs.event.emit("onlr_project.saved", { files = paths })
  end
  return all
end

-- Puts a file back to what is on disk.
local function revert(path)
  local p = assert(P)
  dropHistory(path)
  p.files[path] = nil
  getFile(path)
  emitChanged({ path }, true)
end

local function isDirty()
  for _, file in pairs(P and P.files or {}) do
    if file.dirty then
      return true
    end
  end
  return false
end

-- The editor's own settings for the project, kept in .onlr/ (DESIGN 13.3).
local SETTINGS = { grid = 32, snap = false }

local function readSettings()
  local p = assert(P)
  p.settings = format.copy(SETTINGS)
  local text = format.readFile(absolute(".onlr/editor.lua"))
  local data = text and format.read(text, ".onlr/editor.lua")
  for key, value in pairs(data or {}) do
    p.settings[key] = value
  end
  p.settings.format = nil
end

local function writeSettings()
  local p = assert(P)
  local data = format.copy(p.settings)
  data.format = format.FORMAT
  fs.makeFolder(absolute(".onlr"))
  format.writeFile(absolute(".onlr/editor.lua"), format.write(data, "data"))
end

-- Watching the folder

local pending = {} ---@type table<string, string> the paths that changed on disk, and how
local pendingTimer

local watchFolder

local function diskChanged()
  pendingTimer = nil
  local p = P
  local changes = pending
  pending = {}
  if not p then
    return
  end
  local code, reread = false, {}
  for path, change in pairs(changes) do
    local info = fs.info(absolute(path))
    if info and info.type == "folder" then
      watchFolder(path)
      code = code or path:match("^components") ~= nil or path:match("^packages") ~= nil
    elseif isNodeFile(path) or path == "manifest.lua" then
      local file = p.files[path]
      local text = format.readFile(absolute(path))
      if not text then
        if file then
          dropHistory(path)
          p.files[path] = nil
          reread[#reread + 1] = path
        end
      elseif not file or text ~= file.disk then
        local keep = false
        if file and file.dirty then
          -- The editor's copy has changes too: the user says which to keep (DESIGN 13.6).
          keep = ecs.dialog.showMessage(path .. " changed on disk",
            path .. " changed outside the editor, and the editor holds changes of it that are not saved.",
            { "Keep the editor's", "Read the file" }) == 1
        end
        if keep and file then
          file.disk = text
        else
          dropHistory(path)
          p.files[path] = nil
          getFile(path)
          reread[#reread + 1] = path
        end
      end
      if path == "manifest.lua" then
        code = true
      end
    elseif path:match("%.lua$") then
      code = true
    else
      ecs.event.emit("onlr_project.disk", { path = path, kind = "asset", change = change })
    end
  end
  if #reread > 0 then
    table.sort(reread)
    emitChanged(reread, true)
  end
  if code then
    -- A script changed: what the edit player answered of the types is old (DESIGN 12.5).
    scanTypes()
    p.types = {}
    p.trees = {}
    ecs.event.emit("onlr_project.disk", { kind = "code" })
    ecs.event.emit("onlr_project.types")
  end
  ecs.event.emit("onlr_project.disk", { kind = "files" })
end

function watchFolder(dir)
  local p = assert(P)
  if p.watches[dir] then
    return
  end
  p.watches[dir] = fs.watch(absolute(dir), function(_, name, change)
    if name:sub(1, 1) == "." or name:match("%.new$") then
      return
    end
    pending[dir == "" and name or (dir .. "/" .. name)] = change
    if not pendingTimer then
      pendingTimer = ecs.timer.start(0.05, false, diskChanged)
    end
  end) or true
  for _, entry in ipairs(fs.list(absolute(dir), "") or {}) do
    if entry.type == "folder" and entry.name:sub(1, 1) ~= "." then
      watchFolder(dir == "" and entry.name or (dir .. "/" .. entry.name))
    end
  end
end

-- Opening and closing

local function copyFolder(from, to)
  fs.makeFolder(to)
  for _, entry in ipairs(fs.list(from, "") or {}) do
    if entry.type == "folder" then
      copyFolder(from .. "/" .. entry.name, to .. "/" .. entry.name)
    else
      fs.copy(from .. "/" .. entry.name, to .. "/" .. entry.name)
    end
  end
end

local function removeFolder(path)
  for _, entry in ipairs(fs.list(path, "") or {}) do
    if entry.type == "folder" then
      removeFolder(path .. "/" .. entry.name)
    else
      os.remove(path .. "/" .. entry.name)
    end
  end
  os.remove(path)
end

-- The folder that the editor was started in. fs reads a relative path from the executable's folder, so the editor
-- makes every path whole first.
local function workingFolder()
  local folder = os.getenv("PWD")
  if not folder then
    local pipe = io.popen("cd")
    folder = pipe and pipe:read("l") or "."
    if pipe then
      pipe:close()
    end
  end
  return (folder:gsub("\\", "/"))
end

-- A path from its root, without "." and ".." in it.
local function whole(path)
  path = path:gsub("\\", "/")
  if not path:match("^/") and not path:match("^%a:/") then
    path = workingFolder() .. "/" .. path
  end
  local parts = {}
  for part in path:gmatch("[^/]+") do
    if part == ".." and #parts > 0 then
      parts[#parts] = nil
    elseif part ~= "." then
      parts[#parts + 1] = part
    end
  end
  local start = path:match("^/") and "/" or ""
  return start .. table.concat(parts, "/") .. (path:sub(-1) == "/" and "/" or "")
end

-- ONLR's own folder, which holds the engine and the player's files beside plugins/.
local function home()
  return whole(ecs.plugin.folder .. "../../")
end

local function engineVersion(folder)
  local text = format.readFile(folder .. "manifest.lua")
  local data = text and format.read(text, "manifest.lua")
  return data and data.version
end

local function close()
  local p = P
  if not p then
    return true
  end
  if isDirty() then
    local answer = ecs.dialog.showMessage("Close the project", "The project has changes that are not saved.",
      { "Save", "Do not save", "Cancel" })
    if answer == 1 then
      if not saveAll() then
        return false
      end
    elseif answer ~= 2 then
      return false
    end
  end
  for _, watch in pairs(p.watches) do
    if watch ~= true then
      watch:stop()
    end
  end
  P = nil
  ecs.event.emit("onlr_project.closed")
  return true
end

local function open(folder)
  folder = whole(folder)
  local info = fs.info(folder)
  if info and info.type ~= "folder" then
    folder = folder:match("^(.*)/[^/]*$") or "."
  end
  if folder:sub(-1) ~= "/" then
    folder = folder .. "/"
  end
  -- A file inside a project opens the project: the folder above that holds the manifest.
  local at = folder
  while not fs.info(at .. "manifest.lua") do
    local up = at:match("^(.*/)[^/]+/$")
    if not up then
      say(folder .. " is not a project of ONLR: it has no manifest.lua")
      return false
    end
    at = up
  end
  folder = at
  if not close() then
    return false
  end

  -- The editor works on a project that holds its own version of the engine (DESIGN 3.3).
  local ours, theirs = engineVersion(home() .. "engine/"), engineVersion(folder .. "packages/onlr/")
  if ours and theirs ~= ours then
    local answer = ecs.dialog.showMessage("Update the engine",
      ("The project holds the engine %s, and this editor works with %s. Updating replaces packages/onlr/."):format(
        tostring(theirs or "of no version"), ours), { "Update", "Cancel" })
    if answer ~= 1 then
      return false
    end
    removeFolder(folder .. "packages/onlr")
    copyFolder(home() .. "engine", folder .. "packages/onlr")
  end

  P = {
    folder = folder, files = {}, history = {}, position = 0, chosen = { paths = {} }, tool = "move", settings = {},
    space = {}, typeNames = {}, typeFiles = {}, types = {}, trees = {}, watches = {},
  }
  readSettings()
  scanTypes()
  getFile("manifest.lua")
  walk("nodes", function(path)
    if isNodeFile(path) then
      getFile(path)
    end
  end)
  watchFolder("")

  for i = #recent, 1, -1 do
    if recent[i] == folder then
      table.remove(recent, i)
    end
  end
  table.insert(recent, 1, folder)
  recent[9] = nil
  ecs.event.emit("onlr_project.opened", { folder = folder })
  return true
end

local SCRIPT = [[
-- %s
local onlr = require("onlr")

---@class %s : onlr.Component
local %s = {}

function %s:load()
end

function %s:update(dt)
end

function %s:draw()
end

return %s
]]

local function scriptText(path)
  local name = path:match("^components/(.*)%.lua$") or path:match("([^/]*)%.lua$") or "script"
  name = name:gsub("/init$", ""):gsub("/", ".")
  local short = name:match("[^.]*$")
  local class = short:sub(1, 1):upper() .. short:sub(2)
  return SCRIPT:format(path, name, class, class, class, class, class)
end

local function new(folder)
  folder = whole(folder)
  if folder:sub(-1) ~= "/" then
    folder = folder .. "/"
  end
  fs.makeFolder(folder)
  if #(fs.list(folder, "") or {}) > 0 then
    say(folder .. " is not empty, so no project is made in it")
    return false
  end
  local name = folder:match("([^/]+)/$") or "game"
  local function write(path, text)
    format.writeFile(folder .. path, text)
  end
  write("main.lua", '-- Code outside functions runs in the editor too, when it draws the node view.\n'
    .. '-- The game\'s own start goes in love.load.\nrequire("packages.onlr").start()\n')
  write("conf.lua", 'function love.conf(t)\n  require("packages.onlr").conf(t)\nend\n')
  write("manifest.lua", format.write({
    format = format.FORMAT, name = name, id = name:lower():gsub("[^%w]", ""), gameVersion = "0.1.0", loveVersion = "11.5",
    startNode = "nodes/start.lua", window = { width = 1280, height = 720 },
  }, "manifest"))
  write(".gitignore", ".onlr/\n")
  write(".luarc.json", '{\n  "runtime.version": "LuaJIT",\n'
    .. '  "runtime.path": ["?.lua", "?/init.lua", "packages/?.lua", "packages/?/init.lua"],\n'
    .. '  "workspace.library": [".onlr"]\n}\n')
  for _, dir in ipairs({ "components", "shared", "nodes", "packages", ".onlr" }) do
    fs.makeFolder(folder .. dir)
  end
  write("nodes/start.lua", format.write({ format = format.FORMAT, id = format.newId({}), name = "Start" }, "node"))
  copyFolder(home() .. "engine", folder .. "packages/onlr")
  -- LÖVE's own definitions, for a code editor (DESIGN 4.3), where ONLR holds them.
  if fs.info(home() .. "build/love2d/library") then
    copyFolder(home() .. "build/love2d/library", folder .. ".onlr/love2d")
  end
  return open(folder)
end

-- Changing nodes

-- The table that a node's change is written to: an own node's entry, or its change in the instance that holds it.
---@return table change nil when the instance has no such change and none is made
local function target(node, create)
  if node.own then
    return node.raw
  end
  local holder = node.holder
  if not holder or not node.key then
    error(("the node %s cannot be changed: its base does not load"):format(node.path), 0)
  end
  local changes = holder.instance.changes
  if not changes then
    if not create then
      ---@diagnostic disable-next-line: return-type-mismatch
      return nil
    end
    changes = {}
    holder.instance.changes = changes
  end
  if not changes[node.key] and create then
    changes[node.key] = {}
  end
  return changes[node.key]
end

-- Takes out a change that is left empty, and the changes table with it.
local function prune(node)
  local holder = node.holder
  if node.own or not holder or not holder.instance.changes then
    return
  end
  local change = holder.instance.changes[node.key]
  if change and next(change) == nil then
    holder.instance.changes[node.key] = nil
  end
  if next(holder.instance.changes) == nil then
    holder.instance.changes = nil
  end
end

local function nodesOf(file, paths)
  local t = resolve.tree(file, source)
  if t.error then
    error(t.error, 0)
  end
  local list = {}
  for _, path in ipairs(paths) do
    local node = t.index[path]
    if node then
      list[#list + 1] = node
    end
  end
  return list, t
end

local function declOf(typeName, name)
  for _, p in ipairs(source.properties(typeName) or {}) do
    if p.name == name then
      return p
    end
  end
end

-- Calls fn for each value of a property that names a node: the value itself, or the items of a list and the fields of a group.
-- Without a declaration, every text is taken for one.
local function eachReference(container, key, decl, fn)
  local value = container[key]
  if decl == nil or decl.kind == "node" or decl.kind == "component" then
    if type(value) == "string" then
      fn(container, key, value, decl)
    end
  elseif decl.kind == "list" and type(value) == "table" then
    for i = #value, 1, -1 do
      eachReference(value, i, decl.item, fn)
    end
  elseif decl.kind == "group" and type(value) == "table" then
    for _, field in ipairs(decl.fields or {}) do
      eachReference(value, field.name, field, fn)
    end
  end
end

local function clear(container, key)
  if type(key) == "number" then
    table.remove(container, key)
  else
    container[key] = nil
  end
end

-- What each node file that is made of a file names today, so a change can tell what it breaks.
local function namesBefore(file)
  local p = assert(P)
  local before = {}
  for path, other in pairs(p.files) do
    if other.kind == "node" and other.data then
      local t = resolve.tree(path, source)
      if not t.error and t.files[file] then
        local unused = {}
        for id, keys in pairs(t.unused) do
          unused[id] = {}
          for _, key in ipairs(keys) do
            unused[id][key] = true
          end
        end
        before[path] = { index = t.index, unused = unused }
      end
    end
  end
  return before
end

-- After a change that took nodes away: clears every property that names one of them, and drops every change of an
-- instance that names one, in every node file (DESIGN 13.6). remap may give a name that still finds its node.
local function clearNames(before, touch, remap)
  for path, was in pairs(before) do
    local t = resolve.tree(path, source)
    if not t.error then
      for id, keys in pairs(t.unused) do
        for _, key in ipairs(keys) do
          if not (was.unused[id] and was.unused[id][key]) then
            touch(path)
            local entry = t.instances[id]
            local change = entry.instance.changes[key]
            entry.instance.changes[key] = nil
            local to = remap and remap(key)
            if to and to ~= key then
              entry.instance.changes[to] = change
            end
            if next(entry.instance.changes) == nil then
              entry.instance.changes = nil
            end
          end
        end
      end
      resolve.values(t, source, function(values, name, decl)
        eachReference(values, name, decl, function(container, key, value)
          if was.index[value] and not t.index[value] then
            touch(path)
            local to = remap and remap(value)
            if to and to ~= value then
              container[key] = to
            else
              clear(container, key)
            end
          end
        end)
      end)
    end
  end
end

-- The list that holds a node's entry in its file, and its place there.
local function locate(data, entry)
  local function search(e)
    local lists = {}
    if type(e.children) == "table" then
      lists[#lists + 1] = e.children
    end
    if type(e.instance) == "table" then
      for _, change in pairs(e.instance.changes or {}) do
        if type(change.children) == "table" then
          lists[#lists + 1] = change.children
        end
      end
    end
    for _, list in ipairs(lists) do
      for i, child in ipairs(list) do
        if child == entry then
          return list, i
        end
        local found, at = search(child)
        if found then
          return found, at
        end
      end
    end
  end
  return search(data)
end

-- The entry, in the shown file, of a node that the file holds itself: a plain node, or an instance.
local function entryOf(node)
  if node.own then
    return node.raw
  elseif node.holder and node.path == node.holder.id then
    return node.holder
  end
end

local function setField(file, paths, field, value)
  return edit("Change " .. field, function(touch)
    touch(file)
    for _, node in ipairs((nodesOf(file, paths))) do
      local t = target(node, true)
      local default = format.DEFAULTS[field]
      if not node.own then
        default = node.base[field]
      end
      if value == default then
        t[field] = nil
      else
        t[field] = value
      end
      prune(node)
    end
  end)
end

-- Sets fields of many nodes as one change, such as the places of the nodes that a drag moved.
local function setFields(file, changes, label)
  local paths = {}
  for path in pairs(changes) do
    paths[#paths + 1] = path
  end
  return edit(label or "Change", function(touch)
    touch(file)
    for _, node in ipairs((nodesOf(file, paths))) do
      local t = target(node, true)
      for field, value in pairs(changes[node.path]) do
        local default = format.DEFAULTS[field]
        if not node.own then
          default = node.base[field]
        end
        if value == default then
          t[field] = nil
        else
          t[field] = value
        end
      end
      prune(node)
    end
  end)
end

local function setProperty(file, paths, typeName, name, value)
  return edit("Change " .. name, function(touch)
    touch(file)
    for _, node in ipairs((nodesOf(file, paths))) do
      local c = node.components[typeName]
      if c then
        local decl = declOf(typeName, name)
        local default = decl and decl.default
        if name == "enabled" then
          default = true
        end
        if not node.own and c.base and c.base[name] ~= nil then
          default = c.base[name]
        end
        local entry = target(node, true)
        local values = resolve.component(entry, typeName, true)
        if value == nil or format.same(value, default) then
          values[name] = nil
        else
          values[name] = format.copy(value)
        end
        -- A change that sets nothing of a base's component any more leaves no table of it.
        if not node.own and c.base and next(values) == nil then
          resolve.dropComponent(entry, typeName)
        end
        prune(node)
      end
    end
  end)
end

local function addComponent(file, paths, typeName)
  return edit("Add " .. typeName, function(touch)
    touch(file)
    for _, node in ipairs((nodesOf(file, paths))) do
      if not node.components[typeName] then
        resolve.component(target(node, true), typeName, true)
      end
    end
  end)
end

---@return boolean changed
---@return string? message why a component stays
local function removeComponent(file, paths, typeName)
  local message
  local changed = edit("Remove " .. typeName, function(touch)
    touch(file)
    local list, t = nodesOf(file, paths)
    for _, node in ipairs(list) do
      local c = node.components[typeName]
      if c and c.base and not node.own then
        message = "A component of the base cannot be removed in the instance. It can be turned off."
      elseif c then
        resolve.dropComponent(target(node, true), typeName)
        prune(node)
        -- The properties that name the component are cleared (DESIGN 13.6).
        resolve.values(t, source, function(values, name, decl)
          eachReference(values, name, decl or {}, function(container, key, value, d)
            if d and d.kind == "component" and d.type == typeName and value == node.path then
              clear(container, key)
            end
          end)
        end)
      end
    end
  end)
  return changed, message
end

-- Gives a component's values to another type, or one value to another property, such as after a script was renamed
-- outside the editor (DESIGN 13.4).
local function giveValues(file, paths, typeName, toType, name, toName)
  return edit("Give values", function(touch)
    touch(file)
    for _, node in ipairs((nodesOf(file, paths))) do
      local entry = target(node, false)
      local values = entry and resolve.component(entry, typeName)
      if values and name then
        if values[name] ~= nil then
          resolve.component(entry, toType, true)[toName] = values[name]
          values[name] = nil
        end
      elseif values then
        local into = resolve.component(entry, toType, true)
        for key, value in pairs(values) do
          if into[key] == nil then
            into[key] = value
          end
        end
        resolve.dropComponent(entry, typeName)
      end
    end
  end)
end

-- Drops a change of an instance that names no node (DESIGN 13.6).
local function dropChange(file, instanceId, key)
  return edit("Clear a change", function(touch)
    touch(file)
    local t = resolve.tree(file, source)
    local entry = t.instances[instanceId]
    if entry and entry.instance.changes then
      entry.instance.changes[key] = nil
      if next(entry.instance.changes) == nil then
        entry.instance.changes = nil
      end
    end
  end)
end

local function ids(data)
  local taken = {}
  local function entry(e)
    if type(e.id) == "string" then
      taken[e.id] = true
    end
    for _, child in ipairs(type(e.children) == "table" and e.children or {}) do
      entry(child)
    end
    if type(e.instance) == "table" then
      for _, change in pairs(e.instance.changes or {}) do
        for _, child in ipairs(type(change.children) == "table" and change.children or {}) do
          entry(child)
        end
      end
    end
  end
  entry(data)
  return taken
end

-- The list of children that a new node of a parent is written to.
local function childrenOf(parent)
  local t = target(parent, true)
  t.children = t.children or {}
  return t.children
end

---@return string? id the new node's id
local function addNode(file, parentPath, entry)
  local id
  edit("Add a node", function(touch)
    local data = touch(file)
    local list, t = nodesOf(file, { parentPath })
    local parent = list[1] or t.first
    entry = format.copy(entry or {})
    entry.id = format.newId(ids(data))
    entry.name = entry.name or (not entry.instance and "Node" or nil)
    id = entry.id
    table.insert(childrenOf(parent), entry)
  end)
  return id
end

---@return string? id the instance's id
---@return string? message
local function addInstance(file, parentPath, base, x, y)
  local made = resolve.tree(base, source)
  if made.error then
    return nil, made.error
  elseif made.files[file] then
    return nil, "A node file cannot hold itself."
  end
  local first = getFile(base).data.id
  local change = {}
  if x and x ~= made.first.posX then
    change.posX = x
  end
  if y and y ~= made.first.posY then
    change.posY = y
  end
  return addNode(file, parentPath, { instance = { base = base, changes = next(change) and { [first] = change } or nil } })
end

---@return boolean changed
---@return string? message why a node stays
local function deleteNodes(file, paths)
  local message
  local changed = edit("Delete", function(touch)
    local data = touch(file)
    local before = namesBefore(file)
    local list, t = nodesOf(file, paths)
    for _, node in ipairs(list) do
      local entry = entryOf(node)
      if node == t.first then
        message = "A node file's first node cannot be deleted."
      elseif not entry then
        message = "A node of the base cannot be deleted in the instance. It can be turned off."
      else
        local children, at = locate(data, entry)
        if children then
          table.remove(children, at)
        end
      end
    end
    assert(P).trees = {}
    clearNames(before, touch)
  end)
  local p = assert(P)
  if changed and p.chosen.file == file then
    p.chosen.paths = {}
    ecs.event.emit("onlr_project.chosen", p.chosen)
  end
  return changed, message
end

-- Copies of entries with new ids. A value of a copy that names another node of the copies names that node's copy (DESIGN 13.4).
local function clones(entries, taken)
  local map = {}
  local function renew(e)
    if type(e.id) == "string" then
      local id = format.newId(taken)
      taken[id] = true
      map[e.id] = id
      e.id = id
    end
    for _, child in ipairs(type(e.children) == "table" and e.children or {}) do
      renew(child)
    end
    if type(e.instance) == "table" then
      for _, change in pairs(e.instance.changes or {}) do
        for _, child in ipairs(type(change.children) == "table" and change.children or {}) do
          renew(child)
        end
      end
    end
  end
  local function rename(value)
    if type(value) == "string" then
      local head, rest = value:match("^([^/]+)(.*)$")
      if head and map[head] then
        return map[head] .. rest
      end
    elseif type(value) == "table" then
      for key, item in pairs(value) do
        value[key] = rename(item)
      end
    end
    return value
  end
  local function values(e)
    if type(e.components) == "table" then
      rename(e.components)
    end
    for _, child in ipairs(type(e.children) == "table" and e.children or {}) do
      values(child)
    end
    if type(e.instance) == "table" then
      for _, change in pairs(e.instance.changes or {}) do
        values(change)
      end
    end
  end
  local copies = {}
  for i, entry in ipairs(entries) do
    copies[i] = format.copy(entry)
    renew(copies[i])
  end
  for _, copy in ipairs(copies) do
    values(copy)
  end
  return copies
end

---@return string[] ids the copies' ids
local function duplicate(file, paths)
  local made = {}
  edit("Duplicate", function(touch)
    local data = touch(file)
    local taken = ids(data)
    for _, node in ipairs((nodesOf(file, paths))) do
      local entry = entryOf(node)
      local children, at = locate(data, entry or {})
      if entry and children then
        local copy = clones({ entry }, taken)[1]
        table.insert(children, at + 1, copy)
        made[#made + 1] = copy.id
      end
    end
  end)
  return made
end

local clipboard = {} ---@type table[] the copied nodes' entries

local function copyNodes(file, paths)
  clipboard = {}
  for _, node in ipairs((nodesOf(file, paths))) do
    local entry = entryOf(node)
    if entry then
      clipboard[#clipboard + 1] = format.copy(entry)
    end
  end
  return #clipboard
end

---@return string[] ids the pasted nodes' ids
local function paste(file, parentPath)
  local made = {}
  if #clipboard == 0 then
    return made
  end
  edit("Paste", function(touch)
    local data = touch(file)
    local list, t = nodesOf(file, { parentPath })
    local children = childrenOf(list[1] or t.first)
    for _, copy in ipairs(clones(clipboard, ids(data))) do
      copy.format = nil
      children[#children + 1] = copy
      made[#made + 1] = copy.id
    end
  end)
  return made
end

---@return boolean changed
---@return string? message
local function moveNodes(file, paths, parentPath, index)
  local message
  local changed = edit("Move in the tree", function(touch)
    local data = touch(file)
    local list, t = nodesOf(file, paths)
    local parent = t.index[parentPath] or t.first
    for _, node in ipairs(list) do
      local entry = entryOf(node)
      local inside = parent
      while inside and inside ~= node do
        inside = inside.parent
      end
      if not entry or node == t.first then
        message = "A node of the base cannot be moved in the instance."
      elseif inside then
        message = "A node cannot be moved under itself."
      else
        local from, at = locate(data, entry)
        table.remove(from, at)
        local to = childrenOf(parent)
        local place = index and math.max(1, math.min(index, #to + 1)) or (#to + 1)
        table.insert(to, place, entry)
        if index then
          index = place + 1
        end
      end
    end
  end)
  return changed, message
end

---Writes a node, with all under it, to a new node file, and puts an instance of it in its place (DESIGN 13.5).
---@return boolean changed
---@return string? message
local function saveAsNodeFile(file, path, newFile)
  if not isNodeFile(newFile) then
    return false, "A node file is a Lua file in nodes/."
  elseif fs.info(absolute(newFile)) then
    return false, newFile .. " is there already."
  end
  local message
  local changed = edit("Save as node file", function(touch)
    local data = touch(file)
    local before = namesBefore(file)
    local list, t = nodesOf(file, { path })
    local node = list[1]
    if not node or not node.own or node == t.first then
      message = "Only a node of this file's own, other than its first, is saved as a node file."
      return
    end
    local entry = node.raw
    local children, at = locate(data, entry)
    -- The nodes that move: the node and all under it.
    local moved = {}
    local function mark(n)
      moved[n.path] = n
      for _, child in ipairs(n.children) do
        mark(child)
      end
    end
    mark(node)
    local instanceId = format.newId(ids(data))
    local changes = {}
    -- A value among them that names a node outside them is set by a change of the instance.
    local function outside(e, key)
      if type(e.components) == "table" then
        for typeName, values in pairs(resolve.flatten(e.components, source.space)) do
          for name in pairs(values) do
            local leaves = false
            eachReference(values, name, declOf(typeName, name), function(_, _, value)
              local head = value:match("^[^/]+")
              if t.index[value] and not moved[head] then
                leaves = true
              end
            end)
            if leaves then
              changes[key] = changes[key] or {}
              resolve.component(changes[key], typeName, true)[name] = values[name]
              values[name] = nil
            end
          end
        end
      end
      for _, child in ipairs(type(e.children) == "table" and e.children or {}) do
        if not child.instance then
          outside(child, child.id)
        end
      end
    end
    outside(entry, entry.id)
    local made = format.copy(entry)
    made.format = format.FORMAT
    local p = assert(P)
    ---@type onlr_project.File
    local new = { path = newFile, kind = "node", data = made, dirty = true, handwritten = false, saved = "" }
    p.files[newFile] = new
    saveFile(new)
    children[at] = { id = instanceId, instance = { base = newFile, changes = next(changes) and changes or nil } }
    p.trees = {}
    -- What named one of the nodes names it through the instance.
    clearNames(before, touch, function(name)
      local parts = {}
      for part in name:gmatch("[^/]+") do
        parts[#parts + 1] = part
      end
      for i, part in ipairs(parts) do
        if part == entry.id then
          parts[i] = instanceId
          return table.concat(parts, "/")
        elseif moved[part] then
          table.insert(parts, i, instanceId)
          return table.concat(parts, "/")
        end
      end
    end)
  end)
  return changed, message
end

local function newNodeFile(path, base)
  if not isNodeFile(path) then
    return false, "A node file is a Lua file in nodes/."
  elseif fs.info(absolute(path)) then
    return false, path .. " is there already."
  end
  local name = path:match("([^/]*)%.lua$")
  local data = { format = format.FORMAT, id = format.newId({}) }
  if base then
    -- A variant: a node file whose first node is an instance of another (DESIGN 9).
    data.instance = { base = base }
  else
    data.name = name:sub(1, 1):upper() .. name:sub(2)
  end
  local folder = path:match("^(.*)/[^/]*$")
  fs.makeFolder(absolute(folder))
  format.writeFile(absolute(path), format.write(data, "node"))
  getFile(path)
  emitChanged({ path }, true)
  return true
end

local function newScript(path)
  if fs.info(absolute(path)) then
    return false, path .. " is there already."
  end
  local folder = path:match("^(.*)/[^/]*$")
  if folder then
    fs.makeFolder(absolute(folder))
  end
  format.writeFile(absolute(path), scriptText(path))
  return true
end

-- Files: renaming, moving and deleting (DESIGN 13.7)

local function typeOfScript(path)
  local name = path:match("^components/(.*)%.lua$")
  return name and name:gsub("/init$", ""):gsub("/", ".")
end

-- Changes every path and type name that names a file, in every node file and in the manifest.
local function renameNames(from, to)
  local p = assert(P)
  local isFolder = fs.info(absolute(to)) and fs.info(absolute(to)).type == "folder"
  local function renamed(value)
    if value == from then
      return to
    elseif isFolder and value:sub(1, #from + 1) == from .. "/" then
      return to .. value:sub(#from + 1)
    end
  end
  local oldType, newType = typeOfScript(from), typeOfScript(to)
  local changed = {}
  local function strings(t)
    local any = false
    for key, value in pairs(t) do
      if type(value) == "string" then
        local new = renamed(value)
        if new then
          t[key] = new
          any = true
        end
      elseif type(value) == "table" then
        any = strings(value) or any
      end
    end
    return any
  end
  local function entries(e)
    local any = false
    if oldType and newType and oldType ~= newType then
      local values = resolve.component(e, oldType)
      if values then
        resolve.dropComponent(e, oldType)
        local into = resolve.component(e, newType, true)
        for key, value in pairs(values) do
          into[key] = value
        end
        any = true
      end
    end
    for _, child in ipairs(type(e.children) == "table" and e.children or {}) do
      any = entries(child) or any
    end
    if type(e.instance) == "table" then
      for _, change in pairs(e.instance.changes or {}) do
        any = entries(change) or any
      end
    end
    return any
  end
  for path, file in pairs(p.files) do
    if file.data then
      local any = strings(file.data)
      if file.kind == "node" then
        any = entries(file.data) or any
      end
      if any then
        changed[#changed + 1] = path
        dropHistory(path)
        refresh(file)
      end
    end
  end
  return changed
end

---@return boolean ok
---@return string? message
local function renameFile(from, to)
  local p = assert(P)
  if fs.info(absolute(to)) then
    return false, to .. " is there already."
  end
  -- Every file with changes is saved first, since a rename is not in the history.
  if not saveAll() then
    return false, "The project is not saved."
  end
  local folder = to:match("^(.*)/[^/]*$")
  if folder then
    fs.makeFolder(absolute(folder))
  end
  local ok, err = os.rename(absolute(from), absolute(to))
  if not ok then
    return false, err
  end
  -- The node files that moved are read again under their new paths.
  local movedFiles = {}
  for path in pairs(p.files) do
    if path == from or path:sub(1, #from + 1) == from .. "/" then
      movedFiles[#movedFiles + 1] = path
    end
  end
  for _, path in ipairs(movedFiles) do
    dropHistory(path)
    p.files[path] = nil
    getFile(to .. path:sub(#from + 1))
  end
  local changed = renameNames(from, to)
  saveAll()
  scanTypes()
  p.types = {}
  if p.chosen.file and (p.chosen.file == from or p.chosen.file:sub(1, #from + 1) == from .. "/") then
    p.chosen.file = to .. p.chosen.file:sub(#from + 1)
  end
  ecs.event.emit("onlr_project.renamed", { from = from, to = to })
  emitChanged(changed, true)
  ecs.event.emit("onlr_project.types")
  return true
end

---The node files that name a file, for the question before it is deleted.
---@return string[]
local function usersOf(path)
  local users = {}
  local function names(t)
    for _, value in pairs(t) do
      if value == path or (type(value) == "string" and value:sub(1, #path + 1) == path .. "/") then
        return true
      elseif type(value) == "table" and names(value) then
        return true
      end
    end
    return false
  end
  local typeName = typeOfScript(path)
  for other, file in pairs(assert(P).files) do
    if other ~= path and file.data then
      local uses = names(file.data)
      if not uses and typeName and file.kind == "node" then
        local t = tree(other)
        for _, node in ipairs(t.order) do
          uses = uses or node.components[typeName] ~= nil
        end
      end
      if uses then
        users[#users + 1] = other
      end
    end
  end
  table.sort(users)
  return users
end

---Deletes a file: it goes to the system's trash, or else to .onlr/trash/ in the project.
---@return boolean ok
local function deleteFile(path)
  local p = assert(P)
  local _, code = process.run({ "gio", "trash", absolute(path) }, "", "")
  if code ~= 0 then
    fs.makeFolder(absolute(".onlr"))
    fs.makeFolder(absolute(".onlr/trash"))
    local name = path:gsub("/", "_")
    if not os.rename(absolute(path), absolute(".onlr/trash/" .. os.time() .. "_" .. name)) then
      return false
    end
  end
  local gone = {}
  for other in pairs(p.files) do
    if other == path or other:sub(1, #path + 1) == path .. "/" then
      gone[#gone + 1] = other
    end
  end
  for _, other in ipairs(gone) do
    dropHistory(other)
    p.files[other] = nil
  end
  emitChanged({ path }, true)
  return true
end

-- The functions

local function choose(file, paths)
  local p = assert(P)
  p.chosen = { file = file, paths = paths or {} }
  ecs.event.emit("onlr_project.chosen", p.chosen)
end

ecs.service.register({
  open = { sig = "void(string folder)", doc = "Open a project's folder", fn = function(folder)
    open(folder)
  end },
  create = { sig = "void(string folder)", doc = "Make a new project in an empty folder, and open it", fn = function(folder)
    new(folder)
  end },
  close = { sig = "bool()", doc = "Close the project, after asking about unsaved work", fn = close },
  newProject = { sig = "void()", doc = "New Project", fn = function()
    ecs.dialog.show({ type = "openFolder" }, function(files)
      if files and files[1] then
        new(files[1])
      end
    end)
  end },
  openProject = { sig = "void()", doc = "Open Project", fn = function()
    ecs.dialog.show({ type = "openFolder" }, function(files)
      if files and files[1] then
        open(files[1])
      end
    end)
  end },
  recent = { sig = "value()", doc = "The folders of the projects opened last", fn = function()
    return recent
  end },
  folder = { sig = "string()", doc = "The open project's folder, ending with a slash, or an empty text", fn = function()
    return P and P.folder or ""
  end },
  home = { sig = "string()", doc = "ONLR's own folder, which holds the engine and the player's files", fn = home },
  file = { sig = "value(string path)", doc = "A data file of the project, as the editor holds it", fn = getFile },
  text = { sig = "string(string path)", doc = "A data file's text, as the editor would write it now", fn = function(path)
    local file = getFile(path)
    return file and file.data and format.write(file.data, file.kind) or ""
  end },
  manifest = { sig = "value()", doc = "The manifest's table", fn = function()
    local file = getFile("manifest.lua")
    return file and file.data
  end },
  setManifest = { sig = "void(string field, value value)", doc = "Set a field of the manifest; a dot names a field of a table, as window.width", fn = function(field, value)
    edit("Change " .. field, function(touch)
      local t = touch("manifest.lua")
      if not t then
        return
      end
      local last
      for part in field:gmatch("[^.]+") do
        if last then
          t[last] = type(t[last]) == "table" and t[last] or {}
          t = t[last]
        end
        last = part
      end
      t[last] = value
    end)
  end },
  nodeFiles = { sig = "value()", doc = "The paths of the project's node files, in order", fn = function()
    local list = {}
    if P then
      walk("nodes", function(path)
        if isNodeFile(path) then
          list[#list + 1] = path
        end
      end)
    end
    table.sort(list)
    return list
  end },
  tree = { sig = "value(string path)", doc = "The nodes of a node file, with its instances' nodes", fn = function(path)
    return P and tree(path)
  end },
  typeNames = { sig = "value()", doc = "The names of the project's component types, in order", fn = function()
    return P and P.typeNames or {}
  end },
  typeFile = { sig = "string(string type)", doc = "The file of a component type", fn = function(name)
    return P and P.typeFiles[name] or ""
  end },
  typeInfo = { sig = "value(string type)", doc = "What the edit player answered of a type: its properties, or nil", fn = function(name)
    return P and P.types[name]
  end },
  setTypeInfo = { sig = "void(string type, value info)", doc = "Keep what the edit player answered of a type", fn = function(name, info)
    if P then
      P.types[name] = info
      P.trees = {}
      ecs.event.emit("onlr_project.types")
    end
  end },
  chosen = { sig = "value()", doc = "The chosen nodes: their file, and their paths", fn = function()
    return P and P.chosen or { paths = {} }
  end },
  choose = { sig = "void(string file, value paths)", doc = "Choose nodes of a node file", fn = choose },
  tool = { sig = "string()", doc = "The chosen tool: move, turn or scale", fn = function()
    return P and P.tool or "move"
  end },
  setTool = { sig = "void(string tool)", doc = "Choose a tool", fn = function(tool)
    if P then
      P.tool = tool
      ecs.event.emit("onlr_project.tool", tool)
    end
  end },
  setting = { sig = "value(string name)", doc = "A setting that the editor keeps for the project, such as grid or snap", fn = function(name)
    return P and P.settings[name]
  end },
  setSetting = { sig = "void(string name, value value)", doc = "Set such a setting", fn = function(name, value)
    if P then
      P.settings[name] = value
      writeSettings()
      ecs.event.emit("onlr_project.settings", name)
    end
  end },
  setField = { sig = "bool(string file, value paths, string field, value value)", doc = "Set a field of nodes", fn = setField },
  setFields = { sig = "bool(string file, value changes, string label)",
    doc = "Set fields of many nodes as one change: changes holds each node's fields by its path", fn = setFields },
  setProperty = { sig = "bool(string file, value paths, string type, string property, value value)",
    doc = "Set a value of the nodes' components; nil puts back the default, or the base's value", fn = setProperty },
  addComponent = { sig = "bool(string file, value paths, string type)", doc = "Add a component to nodes", fn = addComponent },
  removeComponent = { sig = "bool(string file, value paths, string type)", doc = "Remove a component from nodes", fn = removeComponent },
  giveValues = { sig = "bool(string file, value paths, string type, string toType, string property, string toProperty)",
    doc = "Give a component's values to another type, or one value to another property", fn = giveValues },
  dropChange = { sig = "bool(string file, string instance, string key)", doc = "Drop a change of an instance", fn = dropChange },
  addNode = { sig = "string(string file, string parent, value entry)", doc = "Add a node under another; gives its id", fn = addNode },
  addInstance = { sig = "string(string file, string parent, string base, double x, double y)",
    doc = "Add an instance of a node file under a node; gives its id", fn = addInstance },
  deleteNodes = { sig = "bool(string file, value paths)", doc = "Delete nodes, with all under them", fn = deleteNodes },
  duplicate = { sig = "value(string file, value paths)", doc = "Duplicate nodes; gives the copies' ids", fn = duplicate },
  copyNodes = { sig = "int(string file, value paths)", doc = "Copy nodes", fn = copyNodes },
  paste = { sig = "value(string file, string parent)", doc = "Paste the copied nodes under a node; gives their ids", fn = paste },
  moveNodes = { sig = "bool(string file, value paths, string parent, int index)", doc = "Move nodes under another node", fn = moveNodes },
  saveAsNodeFile = { sig = "bool(string file, string path, string newFile)",
    doc = "Write a node to a new node file, and put an instance of it in its place", fn = saveAsNodeFile },
  newNodeFile = { sig = "bool(string path, string base)", doc = "Make a node file; with a base, a variant of it", fn = newNodeFile },
  newScript = { sig = "bool(string path)", doc = "Make a script from the template", fn = newScript },
  renameFile = { sig = "bool(string from, string to)", doc = "Rename or move a file, and change what names it", fn = renameFile },
  usersOf = { sig = "value(string path)", doc = "The data files that name a file", fn = usersOf },
  deleteFile = { sig = "bool(string path)", doc = "Delete a file", fn = deleteFile },
  revert = { sig = "void(string path)", doc = "Put a data file back to what is on disk", fn = function(path)
    if P then
      revert(path)
    end
  end },
  isDirty = { sig = "bool()", doc = "Whether a file has changes that are not saved", fn = isDirty },
  save = { sig = "void()", doc = "Save", fn = function()
    saveAll()
  end },
  saveAll = { sig = "bool()", doc = "Save every file with changes; false when one is not saved", fn = saveAll },
  saveFile = { sig = "bool(string path)", doc = "Save one data file", fn = function(path)
    local file = P and P.files[path]
    if not file then
      return true
    end
    local ok = saveFile(file)
    if ok then
      ecs.event.emit("onlr_project.saved", { files = { path } })
    end
    return ok
  end },
  undo = { sig = "void()", doc = "Undo", fn = function()
    if P and P.position > 0 then
      P.position = P.position - 1
      step(P.history[P.position + 1], "before")
    end
  end },
  redo = { sig = "void()", doc = "Redo", fn = function()
    if P and P.position < #P.history then
      P.position = P.position + 1
      step(P.history[P.position], "after")
    end
  end },
  historyState = { sig = "value()", doc = "The history: how many changes are done, and how many it holds", fn = function()
    return { position = P and P.position or 0, count = P and #P.history or 0 }
  end },
  openPath = { sig = "void(string path)", doc = "Open the project that holds a file or a folder", fn = function(path)
    open(path)
  end },
})

ecs.plugin.register({
  stateVersion = 1,
  saveState = function()
    return { recent = recent, folder = P and P.folder }
  end,
  restoreState = function(saved, version)
    if version == 1 and type(saved) == "table" then
      recent = saved.recent or {}
      if saved.folder and fs.info(saved.folder .. "manifest.lua") then
        open(saved.folder)
      end
    end
  end,
})
