-- Tells the editor's test that the game played: it writes a file into the project's folder, where the editor started LÖVE.
---@class marker : onlr.Component
local Marker = {}

function Marker:load()
  local file = io.open("played.txt", "w")
  if file then
    file:write(self.node.name)
    file:close()
  end
end

return Marker
