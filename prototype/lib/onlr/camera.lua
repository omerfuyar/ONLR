-- The component type onlr.camera: the view of the tree. In this prototype, only its properties.
-- Its node's place is what the window's centre shows, turned as the node is. The node's scale is not
-- used, so a camera under a scaled node does not zoom: zoom does.
local onlr = require("onlr")

---@class onlr.camera : onlr.Component
local Camera = {}

Camera.zoom = onlr.property.number(1, { min = 0.01, description = "2 shows the tree twice as large" })

-- In the game it draws nothing: the tree draws through its first camera that runs.
-- In the node view, the frame of what it shows.
function Camera:drawEditor(chosen) end
function Camera:bounds() end

return Camera
