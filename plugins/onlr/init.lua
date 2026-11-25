-- ONLR's editor plugin (DESIGN 13.1). Each part is a file of its own: project.lua holds the open project, nodeview.lua
-- the node view and Play, runners.lua and link.lua the runners and the link, panels.lua the other panels, and export.lua
-- export. runner/ holds the runner's files, which the engine loads when the editor starts LÖVE (DESIGN 12.1).

local ecs = require("ecs")

-- The plugin's functions, onlr.*, are those of its parts, which each part returns.
local functions = {}
for _, part in ipairs({ "project", "nodeview", "export", "search", "settings" }) do
  for name, entry in pairs(require(part).functions) do
    assert(functions[name] == nil, "two parts have the function " .. name)
    functions[name] = entry
  end
end
ecs.service.register(functions)

require("panels")
