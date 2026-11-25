-- The panels of ONLR's own, apart from the node view (DESIGN 13.1): the node hierarchy, the inspector, the tools' bars,
-- the project settings, the history and the search. Each shows the project that project.lua holds, and changes it through its functions.

local ecs = require("ecs")
local project = require("project")
local console = require("console")
local nodeview = require("nodeview")
local files = require("files")
local viewer = require("viewer")
local shared = require("shared")

require("hierarchy")
require("inspector")
require("tools")
require("settings")
require("history")

-- What the project says shows in the console.
ecs.event.subscribe("onlr.said", function(_, text)
  console.add(text, "info")
end)

-- Undo, redo and save, and the game's keys, act on the whole project, so the preset binds them for the whole editor (DESIGN 13.1).
ecs.key.bind("onlr.hierarchy", "Delete", "onlr.deleteChosen")
ecs.key.bind("onlr.hierarchy", "Ctrl+D", "onlr.duplicateChosen")
ecs.key.bind("onlr.hierarchy", "H", "onlr.hideChosen")
ecs.key.bind("onlr.hierarchy", "Escape", "onlr.cancelPick")
ecs.key.bind("onlr.inspector", "Escape", "onlr.cancelPick")
ecs.key.bind("onlr.hierarchy", "L", "onlr.lockChosen")
ecs.key.bind("onlr.hierarchy", "Shift+A", "onlr.selectWithChildren")
-- the tools' keys work in the Transform bar that shows them, as in the node view
for key, name in pairs({ W = "onlr.toolMove", E = "onlr.toolTurn", R = "onlr.toolScale", T = "onlr.toolRect", Y = "onlr.toolShape" }) do
  ecs.key.bind("onlr.transform", key, name)
end

-- The files panel shows the project's folder, and the editor says what its files are (DESIGN 13.7).
local function showFolder()
  files.setFolder(project.folder())
end

files.setHandlers({
  -- A click on a file shows it without opening it: in the asset viewer when one is open, and in the inspector.
  choose = function(path)
    viewer.show(project.folder() .. path)
    shared.chooseFile(path)
  end,
  -- A double click opens it: a node file in a node view, a script in the user's code editor, and any other file in the asset viewer.
  open = function(path)
    if path:match("^nodes/.+%.lua$") then
      nodeview.openFile(path)
    elseif path:match("%.lua$") then
      console.open(path, 1)
    else
      viewer.open(project.folder() .. path)
    end
  end,
  kinds = {
    { label = "Node file", make = function(path)
      path = path:gsub("%.lua$", "") .. ".lua"
      if not path:match("^nodes/") then
        path = "nodes/" .. path:match("[^/]*$")
      end
      local ok, message = project.newNodeFile(path)
      if ok then
        nodeview.openFile(path)
      end
      return ok, message
    end },
    { label = "Script", make = function(path)
      path = path:gsub("%.lua$", "") .. ".lua"
      if not path:match("^components/") then
        path = "components/" .. path:match("[^/]*$")
      end
      return project.newScript(path)
    end },
  },
  -- The grid's icons tell a node file and a component's script from other Lua files; images show as small pictures.
  icon = function(path)
    if path:match("^nodes/.+%.lua$") then
      return { label = "NODE", color = "accent" }
    elseif path:match("^components/.+%.lua$") then
      return { label = "LUA", color = "#98c379" }
    end
  end,
  rename = project.renameFile,
  delete = project.deleteFile,
  deleteNote = function(path)
    local users = project.usersOf(path)
    if #users > 0 then
      return "These files name it: " .. table.concat(users, ", ") .. "."
    end
  end,
})

-- Unlocked, the files panel follows what is chosen, as Unity's Project window does: the node file of the node view that has the
-- focus, or the base of a chosen instance (DESIGN 13.7).
ecs.event.subscribe("onlr.chosen", function(_, chosen)
  if not chosen.file then
    return
  end
  local path = chosen.file
  if #chosen.paths == 1 and project.file(chosen.file) then
    local node = project.tree(chosen.file).index[chosen.paths[1]]
    path = node and node.instanceOf or path
  end
  files.reveal(path)
end)

ecs.event.subscribe("onlr.opened", showFolder)
ecs.event.subscribe("onlr.closed", showFolder)
ecs.event.subscribe("onlr.disk", function(_, value)
  if value.kind == "asset" then
    viewer.reload(project.folder() .. value.path)
  end
end)
showFolder()
