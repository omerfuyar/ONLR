-- The panels of ONLR's own, apart from the node view (DESIGN 13.1): the nodes panel, the inspector, the tools
-- and the project settings. Each shows the project that project.lua holds, and changes it through its functions.

local ecs = require("ecs")
local project = require("project")
local console = require("console")
local player = require("nodeview")
local files = require("files")
local viewer = require("viewer")
local shared = require("shared")

require("nodes")
require("inspector")
require("tools")
require("settings")

-- What the project says shows in the console.
ecs.event.subscribe("onlr.said", function(_, text)
  console.add(text, "info")
end)

for _, panel in ipairs({ "onlr.nodes", "onlr.inspector", "onlr.tools", "onlr.settings" }) do
  for key, name in pairs({ ["Ctrl+Z"] = "onlr.undo", ["Ctrl+Y"] = "onlr.redo", ["Ctrl+S"] = "onlr.save" }) do
    ecs.key.bind(panel, key, name)
  end
end
ecs.key.bind("onlr.nodes", "Delete", "onlr.deleteChosen")
ecs.key.bind("onlr.nodes", "Ctrl+D", "onlr.duplicateChosen")

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
      player.openFile(path)
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
        player.openFile(path)
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
  rename = project.renameFile,
  delete = project.deleteFile,
  deleteNote = function(path)
    local users = project.usersOf(path)
    if #users > 0 then
      return "These files name it: " .. table.concat(users, ", ") .. "."
    end
  end,
})

ecs.event.subscribe("onlr.opened", showFolder)
ecs.event.subscribe("onlr.closed", showFolder)
ecs.event.subscribe("onlr.disk", function(_, value)
  if value.kind == "asset" then
    viewer.reload(project.folder() .. value.path)
  end
end)
showFolder()
