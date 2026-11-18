---@meta suit

-- The library's definitions, named as the package. A code editor reads them, and the game never does.
-- They are written with the package, since SUIT ships none: what a script reaches through a widget's get(), and the
-- theme that every widget draws with.

---The colours of a widget in one state: its box, and its text or mark.
---@class suit.Colors
---@field bg number[]
---@field fg number[]

---How the widgets look. A script changes it for all of them: suit.theme.color.hovered.bg = { 1, 0, 0 }.
---@class suit.Theme
---@field cornerRadius number
---@field color {normal: suit.Colors, hovered: suit.Colors, active: suit.Colors}
---@field Button fun(text: string, opt: table, x: number, y: number, w: number, h: number)
---@field Label fun(text: string, opt: table, x: number, y: number, w: number, h: number)
---@field Checkbox fun(checkbox: table, opt: table, x: number, y: number, w: number, h: number)
---@field Slider fun(fraction: number, opt: table, x: number, y: number, w: number, h: number)
---@field Input fun(input: table, opt: table, x: number, y: number, w: number, h: number)
local Theme = {}

---A SUIT, which keeps the pointer and the state of the widgets.
---@class suit.Core
---@field theme suit.Theme
---@field hovered any the id of the widget under the pointer
---@field active any the id of the widget that the pointer holds
---@field keyboardFocus any the id of the widget that the keyboard types into
---@field draw_queue {n: integer, [integer]: fun()} what SUIT draws at its draw
local Core = {}

---@param x number
---@param y number
---@param down? boolean whether the mouse's button is down
function Core:updateMouse(x, y, down) end

---Ends a frame: reads the mouse's button and forgets the keys. A game that uses SUIT alone does it in suit.draw.
function Core:enterFrame() end

---@param id any
---@return "normal"|"hovered"|"active"|"hit"
function Core:getStateName(id) end

---@param id any
---@return boolean
function Core:hasKeyboardFocus(id) end

---@param id any
---@return boolean
function Core:isActive(id) end

---@param key string
function Core:keypressed(key) end

---@param text string
function Core:textinput(text) end

---@param text string
---@param start number
---@param length number
function Core:textedited(text, start, length) end

---Each widget takes its options, then its place and size, and answers what happened this frame.
---@return {id: any, hit: boolean, hovered: boolean, entered: boolean, left: boolean, changed?: boolean, submitted?: boolean}
function Core:Button(text, opt, x, y, w, h) end
---@return {id: any, hit: boolean, hovered: boolean, entered: boolean, left: boolean}
function Core:Label(text, opt, x, y, w, h) end
---@return {id: any, hit: boolean, hovered: boolean, entered: boolean, left: boolean}
function Core:Checkbox(checkbox, opt, x, y, w, h) end
---@return {id: any, hit: boolean, hovered: boolean, entered: boolean, left: boolean, changed: boolean}
function Core:Slider(info, opt, x, y, w, h) end
---@return {id: any, hit: boolean, hovered: boolean, entered: boolean, left: boolean, submitted: boolean}
function Core:Input(input, opt, x, y, w, h) end
---@return {id: any, hit: boolean, hovered: boolean, entered: boolean, left: boolean}
function Core:ImageButton(normal, opt, x, y) end

---@class suit
---@field theme suit.Theme
---@field new fun(theme?: suit.Theme): suit.Core
local suit = {}

return suit
