---@meta anim8

-- The library's definitions, named as the package. A code editor reads them, and the game never does.
-- They are written with the package, since anim8 ships none: what a script reaches through anim8.animation's get().

---The frames of a sprite sheet, cut into a grid of cells of one size.
---@class anim8.Grid
---@field frameWidth integer
---@field frameHeight integer
---@field width integer the number of columns
---@field height integer the number of rows
local Grid = {}

---The quads of the frames, by pairs of a column and a row, each a number or a range such as "1-4".
---grid:getFrames("1-4", 1) gives the first row's four frames.
---@param ... integer|string
---@return love.Quad[]
function Grid:getFrames(...) end

---A list of frames, each shown for its duration.
---@class anim8.Animation
---@field frames love.Quad[]
---@field durations number[] each frame's, in seconds
---@field totalDuration number
---@field timer number the seconds since the animation's start, or its last loop
---@field position integer the frame shown
---@field status "playing"|"paused"
---@field flippedH boolean
---@field flippedV boolean
local Animation = {}

---Moves the timer on, shows the frame that the time reaches, and calls onLoop when the end is passed.
---@param dt number
function Animation:update(dt) end

---Shows a frame, from 1, and puts the timer at its start.
---@param position integer
function Animation:gotoFrame(position) end

function Animation:pause() end

function Animation:resume() end

---Shows the last frame, and pauses.
function Animation:pauseAtEnd() end

---Shows the first frame, and pauses.
function Animation:pauseAtStart() end

---The frame's width and height.
---@return integer width, integer height
function Animation:getDimensions() end

---@class anim8
local anim8 = {}

---Cuts an image of imageWidth by imageHeight into frames: left and top are where the first frame starts, and border is
---the space between frames.
---@param frameWidth integer
---@param frameHeight integer
---@param imageWidth integer
---@param imageHeight integer
---@param left? integer
---@param top? integer
---@param border? integer
---@return anim8.Grid
function anim8.newGrid(frameWidth, frameHeight, imageWidth, imageHeight, left, top, border) end

---Makes an animation of frames, each shown for durations seconds, or for its own: { ["1-2"] = 0.1, [3] = 0.5 }.
---onLoop is called each time the animation passes its end: a function, or the name of a method such as "pauseAtEnd".
---@param frames love.Quad[]
---@param durations number|table<integer|string, number>
---@param onLoop? fun(animation: anim8.Animation, loops: integer)|string
---@return anim8.Animation
function anim8.newAnimation(frames, durations, onLoop) end

return anim8
