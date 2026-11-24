-- The search over everything (DESIGN 13.8): one key opens it, and it finds the project's nodes, files, component types and the
-- functions that its scripts define, and the editor's functions, as Unity's search does. Return opens what is chosen.

local ecs = require("ecs")
local ui = require("ui")
local fs = require("fs")
local project = require("project")
local nodeview = require("nodeview")
local console = require("console")
local viewer = require("viewer")
local files = require("files")

local STYLES = ui.styles()
local LIMIT = 200 -- the most results that show, so a short query in a big project stays quick

---What the search finds.
---@class onlr.editor.Found
---@field kind string Node, File, Type, Function or Command
---@field label string what it is called
---@field detail string where it is, which the search matches too
---@field open fun() what Return does

local searches = {} ---@type table<ecs.Panel, onlr.editor.Search> every open search, by its panel
local index -- every item, made again when the project changes
local target -- the panel that had the focus when the search was opened, for a command that acts on a panel

-- The project's files, apart from what starts with a dot, with their paths from the project's folder.
local function eachFile(folder, prefix, out)
  for _, entry in ipairs(fs.list(folder .. prefix, "") or {}) do
    if entry.name:sub(1, 1) ~= "." then
      if entry.type == "folder" then
        eachFile(folder, prefix .. entry.name .. "/", out)
      else
        out[#out + 1] = prefix .. entry.name
      end
    end
  end
  return out
end

-- Opens a file as a double click in the files panel does: a node file in a node view, a script in the code editor, any other in the
-- asset viewer.
local function openFile(path)
  files.reveal(path)
  if path:match("^nodes/.+%.lua$") then
    nodeview.openFile(path)
  elseif path:match("%.lua$") then
    console.open(path, 1)
  else
    viewer.open(project.folder() .. path)
  end
end

-- The functions that a script defines, `function Player:jump(` and `local function step(`, with their lines.
local function functionsOf(path, out)
  local file = io.open(project.folder() .. path, "r")
  if not file then
    return
  end
  local line = 0
  for text in file:lines() do
    line = line + 1
    local name = text:match("^%s*function%s+([%w_.:]+)%s*%(") or text:match("^%s*local%s+function%s+([%w_]+)%s*%(")
    if name then
      local at = line
      out[#out + 1] = { kind = "Function", label = name, detail = path .. ":" .. at, open = function()
        files.reveal(path)
        console.open(path, at)
      end }
    end
  end
  file:close()
end

local function build()
  local items = {}
  local folder = project.folder()
  if folder ~= "" then
    local files = eachFile(folder, "", {})
    table.sort(files)
    for _, path in ipairs(files) do
      -- the nodes of every node file, its own ones: an instance's are found in its base's file
      if path:match("^nodes/.+%.lua$") and project.file(path) then
        local tree = project.tree(path)
        for _, node in ipairs(tree.order or {}) do
          if node.own then
            local nodePath = node.path
            items[#items + 1] = { kind = "Node", label = node.name or "(no name)", detail = path, open = function()
              nodeview.showNodes(path, { nodePath })
            end }
          end
        end
      end
      -- the functions of the project's own code, not of the engine and the packages, which it holds as copies
      if path:match("%.lua$") and not path:match("^packages/") and not path:match("^nodes/") and path ~= "manifest.lua" then
        functionsOf(path, items)
      end
      items[#items + 1] = { kind = "File", label = path:match("[^/]*$"), detail = path, open = function()
        openFile(path)
      end }
    end
    for _, name in ipairs(project.typeNames()) do
      local file = project.typeFile(name)
      items[#items + 1] = { kind = "Type", label = name, detail = file, open = function()
        if file ~= "" then
          files.reveal(file)
          console.open(file, 1)
        end
      end }
    end
  end
  -- the editor's functions, which keys run, as Unity's search finds its menus' items
  for _, entry in ipairs(ecs.key.functions()) do
    local name, panel = entry.name, entry.panel
    items[#items + 1] = { kind = "Command", label = entry.description ~= "" and entry.description or name, detail = name, open = function()
      local fn = ecs.service.get(name)
      if fn and panel then
        fn(target)
      elseif fn then
        fn()
      end
    end }
  end
  return items
end

---A panel of the search.
---@class onlr.editor.Search
---@field panel ecs.Panel
---@field query string
---@field items onlr.editor.Found[] what matches the query
---@field selected integer the chosen result
local Search = {}
Search.__index = Search

-- Finds what matches the query again.
function Search:refresh()
  index = index or build()
  self.items = {}
  if self.query ~= "" then
    for _, item in ipairs(index) do
      if ui.matches(self.query, item.label .. "\n" .. item.detail .. "\n" .. item.kind) then
        self.items[#self.items + 1] = item
        if #self.items == LIMIT then
          break
        end
      end
    end
  end
  self.selected = math.min(math.max(self.selected, 1), math.max(#self.items, 1))
  self.panel:redraw()
end

function Search:choose(i)
  local item = self.items[i]
  if item then
    item.open()
  end
end

-- The results' rows, only those in view.
function Search:rows()
  local first, last = ui.range(self.panel, "results", #self.items)
  local rows = {}
  for i = first, last do
    local item = self.items[i]
    rows[#rows + 1] = ui.row({ style = STYLES.item, gap = 8 }, {
      ui.text(item.kind, { style = STYLES.note, width = 70 }),
      ui.text(item.label),
      ui.text(item.detail, { style = STYLES.note, grow = 1 }),
    })
  end
  return rows, first
end

function Search:draw(surface)
  local rows, first = self:rows()
  local list
  if #self.items == 0 then
    list = ui.list({ id = "results", grow = 1 }, {
      ui.text(self.query == "" and "Type to find nodes, files, types, functions and commands." or "Nothing matches the search.",
        { color = "textDim", selectable = false }),
    })
  else
    list = ui.list({
      id = "results", grow = 1, selected = self.selected, count = #self.items, first = first,
      onSelect = function(i)
        self.selected = i
      end,
      onActivate = function(i)
        self:choose(i)
      end,
    }, rows)
  end
  ui.show(self.panel, surface, ui.column({ padding = 8, gap = 6 }, {
    ui.search(self.query, {
      placeholder = "Search everything",
      results = "results",
      onChange = function(query)
        self.query = query
        self:refresh()
      end,
      onSubmit = function()
        self:choose(self.selected)
      end,
    }),
    list,
  }))
end

-- What the project holds changed: the index is made again at the next search.
for _, name in ipairs({ "onlr.opened", "onlr.closed", "onlr.changed", "onlr.types", "onlr.disk", "onlr.renamed", "files.changed" }) do
  ecs.event.subscribe(name, function()
    index = nil
    for _, search in pairs(searches) do
      search:refresh()
    end
  end)
end

function Search.create(panel)
  local self = setmetatable({ panel = panel, query = "", items = {}, selected = 1 }, Search)
  searches[panel] = self
  ui.edit(panel, "search")
  return self
end

function Search:event(event)
  ui.event(self.panel, event)
end

function Search:saveState()
  -- not read back; a test reads what shows
  local shown = {}
  for i, item in ipairs(self.items) do
    shown[i] = item.kind .. " " .. item.label .. " " .. item.detail
  end
  return { query = self.query, selected = self.selected, shown = shown }
end

function Search:destroy()
  searches[self.panel] = nil
  ui.forget(self.panel)
end

ecs.panel.registerType({
  name = "search",
  title = "Search",
  create = Search.create,
  draw = Search.draw,
  event = Search.event,
  saveState = Search.saveState,
  destroy = Search.destroy,
})

local search = {}

-- Opens the search, or gives the open one the focus, with the keys in its field.
function search.open()
  local focus = ecs.layout.getFocus()
  if focus and not searches[focus] then
    target = focus
  end
  local open = next(searches)
  if open then
    ecs.layout.focus(open)
    ui.edit(open, "search")
    return
  end
  local panel, message = ecs.layout.open("onlr.search")
  if not panel then
    console.add(message or "The search cannot open.", "warn")
  end
end

search.functions = {
  search = { sig = "void()", doc = "Search everything: nodes, files, types, functions and commands", fn = search.open },
}

return search
