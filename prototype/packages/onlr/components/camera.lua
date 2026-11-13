-- The component type onlr.camera: a view. In this prototype, only its properties.
-- It draws its node and all under it as a group, moved, turned and zoomed so that
-- the middle of its screen, the window by default, shows its point. What is outside its node, such as a score, it does not move.
local onlr = require("onlr")

---@class onlr.camera : onlr.Component
local Camera = {}

-- Its own place, not its node's: the node's place moves the world under it.
-- A script follows the player by setting these in lateUpdate.
Camera.posX = onlr.property.number(0, { description = "The point, in its node's space, that the middle of its screen shows" })
Camera.posY = onlr.property.number(0)
Camera.rot = onlr.property.number(0, { description = "Its angle, clockwise" })
Camera.zoom = onlr.property.number(1, { min = 0.01, description = "2 shows its nodes twice as large" })
-- The size of its screen. 0 is the window's; a game that a library scales names its own size, such as 320 by 180.
Camera.width = onlr.property.number(0, { min = 0 })
Camera.height = onlr.property.number(0, { min = 0 })

-- The engine calls it in place of drawing the group, and gives it draw, which draws the group.
-- In the node view it is not called, so the camera does not move the view.
---@param draw fun()
function Camera:drawTree(draw) end

-- Turns a point of its screen, such as the pointer's, into the point of the world that the camera
-- shows there, in the space of node:toWorld: camera:toWorld(love.mouse.getPosition()).
---@return number x, number y
function Camera:toWorld(x, y) return x, y end

-- Turns a point of the world into the point of its screen where the camera shows it.
---@return number x, number y
function Camera:toScreen(x, y) return x, y end

-- In the node view, the frame of what it shows.
function Camera:drawEditor(chosen) end
function Camera:bounds() end

return Camera
