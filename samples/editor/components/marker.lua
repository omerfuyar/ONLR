-- Tells the editor's test that the game played: it writes files into the project's folder, where the editor started LÖVE: the
-- node's name, and the size of the window.
---@class marker : onlr.Component
local Marker = {}

function Marker:load()
  local file = io.open("played.txt", "w")
  if file then
    file:write(self.node.name)
    file:close()
  end
  file = io.open("window.txt", "w")
  if file then
    file:write(("%dx%d"):format(love.graphics.getDimensions()))
    file:close()
  end
end

return Marker
