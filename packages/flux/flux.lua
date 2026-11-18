---@meta flux

-- The library's definitions, named as the package. A code editor reads them, and the game never does.
-- They are written with the package, since flux ships none.

---A tween: numbers of a table that move from their values to others. Its functions return it, so they chain:
---tweens:to(node, 1, { posX = 100 }):ease("linear"):delay(0.5):oncomplete(done)
---@class flux.Tween
local Tween = {}

---The way it moves: "linear", or quad, cubic, quart, quint, expo, sine, circ, back or elastic, each with in, out or
---inout after it, such as "quadout", the default.
---@param name string
---@return flux.Tween
function Tween:ease(name) end

---Waits this many seconds before it starts.
---@param seconds number
---@return flux.Tween
function Tween:delay(seconds) end

---@param fn function called when it starts, after its delay
---@return flux.Tween
function Tween:onstart(fn) end

---@param fn function called each frame that it moves
---@return flux.Tween
function Tween:onupdate(fn) end

---@param fn function called when it ends
---@return flux.Tween
function Tween:oncomplete(fn) end

---A tween that starts when this one ends: of the same table with two values, or of another with three.
---@overload fun(self: flux.Tween, time: number, vars: table<any, number>): flux.Tween
---@param obj table
---@param time number
---@param vars table<any, number>
---@return flux.Tween
function Tween:after(obj, time, vars) end

---Ends it where it is, without calling oncomplete.
function Tween:stop() end

---A group of tweens, which moves on when it is updated.
---@class flux.Group
local Group = {}

---Moves the numbers of obj named in vars to their values in vars, in time seconds. A tween of the same numbers of
---the same table that runs already stops moving them.
---@param obj table
---@param time number
---@param vars table<any, number>
---@return flux.Tween
function Group:to(obj, time, vars) end

---@param dt number
function Group:update(dt) end

---Puts a tween into the group. A group that held it still holds it, and moves it too.
---@param tween flux.Tween
---@return flux.Tween
function Group:add(tween) end

---@class flux : flux.Group
---@field easing table<string, fun(p: number): number> the ways of moving, by name; a game may add its own
local flux = {}

---A group of its own, which moves on only when it is updated.
---@return flux.Group
function flux.group() end

return flux
