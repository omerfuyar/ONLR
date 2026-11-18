---@meta baton

-- The library's definitions, named as the package. A code editor reads them, and the game never does.
-- They are written with the package, since baton ships none: what a script reaches through baton.input's getPlayer().

---The controls of one player: each a name bound to sources such as "key:left", and pairs of four controls.
---@class baton.Player
---@field config {controls: table<string, string[]>, pairs: table<string, string[]>, joystick: love.Joystick?, deadzone: number, squareDeadzone: boolean}
local Player = {}

---Reads the sources, and works out which controls are down, pressed and released since the last update.
function Player:update() end

---A control's value from 0 to 1, or a pair's x and y from -1 to 1, after the deadzone.
---@param name string
---@return number x, number? y
function Player:get(name) end

---As get, before the deadzone.
---@param name string
---@return number x, number? y
function Player:getRaw(name) end

---@param name string
---@return boolean
function Player:down(name) end

---Whether it went down at the last update.
---@param name string
---@return boolean
function Player:pressed(name) end

---Whether it went up at the last update.
---@param name string
---@return boolean
function Player:released(name) end

---The device used last: "kbm" for the keyboard and the mouse, "joy" for the joystick, or "none".
---@return "kbm"|"joy"|"none"
function Player:getActiveDevice() end

---@class baton
local baton = {}

---@param config {controls: table<string, string[]>, pairs?: table<string, string[]>, joystick?: love.Joystick, deadzone?: number, squareDeadzone?: boolean}
---@return baton.Player
function baton.new(config) end

return baton
