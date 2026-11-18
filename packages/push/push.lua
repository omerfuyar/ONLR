---@meta push

-- The library's definitions, named as the package. A code editor reads them, and the game never does.
-- They are written with the package, since push ships none. push is one table for the whole game, which push.screen
-- sets up; a script reaches it through the component, or with require("push").

---@class push
---@field package _canvas boolean? whether setupScreen was given canvas, which push.screen reads
local push = {}

---Sets the game's size and the window's, and the window's mode.
---@param gameWidth number
---@param gameHeight number
---@param windowWidth number
---@param windowHeight number
---@param settings? {fullscreen?: boolean, resizable?: boolean, highdpi?: boolean, pixelperfect?: boolean, stretched?: boolean, canvas?: boolean, stencil?: boolean}
---@return push
function push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, settings) end

---Starts drawing the game: into its canvas, or scaled into the window without one.
function push:start() end

---Ends it, and draws the canvas into the window, scaled.
---@param shader? love.Shader|love.Shader[]
function push:finish(shader) end

---Takes the window's new size.
---@param width number
---@param height number
function push:resize(width, height) end

---The place in the game of a place in the window, or nil for an axis outside the game.
---@param x number
---@param y number
---@return number? x, number? y
function push:toGame(x, y) end

---The place in the window of a place in the game.
---@param x number
---@param y number
---@return number x, number y
function push:toReal(x, y) end

---@param r number|number[]
---@param g? number
---@param b? number
function push:setBorderColor(r, g, b) end

---Shaders that the scaled game is drawn through, at the window's size.
---@param shader love.Shader|love.Shader[]
function push:setShader(shader) end

---@return number
function push:getWidth() end

---@return number
function push:getHeight() end

---@return number width, number height
function push:getDimensions() end

return push
