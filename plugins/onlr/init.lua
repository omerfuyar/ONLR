-- ONLR's editor plugin (DESIGN 13.1). Each part is a file of its own: project.lua holds the open project, nodeview.lua
-- the node view and Play, players.lua and link.lua the players and the link, panels.lua the other panels, and export.lua
-- export. player/ holds the player's files, which the engine loads when the editor starts LÖVE (DESIGN 12.1).

local ecs = require("ecs")

-- The plugin's functions, onlr.*, are those of its parts, which each part returns.
local functions = {}
for _, part in ipairs({ "project", "nodeview", "export" }) do
  for name, entry in pairs(require(part).functions) do
    assert(functions[name] == nil, "two parts have the function " .. name)
    functions[name] = entry
  end
end
ecs.service.register(functions)

require("panels")
