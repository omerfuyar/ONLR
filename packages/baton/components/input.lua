-- The component type baton.input: the controls of a player, as a baton player. A control is a name, such as "jump",
-- bound to sources: keys, mouse buttons and a joystick's buttons, axes and hats. A pair is four controls read as one
-- stick, such as "move". Scripts ask for the control, not for the key, so a game's keys are set in one place, and
-- a gamepad works as the keyboard does.
local onlr = require("onlr")
local baton = require("baton")

---@class baton.input : onlr.Component
---@field private player baton.Player?
local Input = {}

Input.controls = onlr.property.list(onlr.property.group({
  name = onlr.property.string("jump"),
  sources = onlr.property.string("key:space", {
    description = "Sources, apart by commas: key:left, sc:a (where a is on the keyboard), mouse:1, button:a or button:3, axis:leftx- or axis:2+, hat:1u",
  }),
}), { description = "Each a name that scripts ask for, and the sources that move it" })
Input.pairs = onlr.property.list(onlr.property.group({
  name = onlr.property.string("move"),
  left = onlr.property.string("left"),
  right = onlr.property.string("right"),
  up = onlr.property.string("up"),
  down = onlr.property.string("down"),
}), { description = "Four controls read as one stick: get gives its x and y from -1 to 1" })
Input.deadzone = onlr.property.number(0.5, { min = 0, max = 1, description = "How far a stick moves before it counts" })
Input.squareDeadzone = onlr.property.bool(false, { description = "The deadzone of a pair is a square, for each axis apart, not a circle" })
Input.joystick = onlr.property.integer(1, {
  min = 0,
  description = "Which joystick is this player's, by the order they were connected: 1 is the first. 0 reads none",
})

local KINDS = { key = true, sc = true, mouse = true, axis = true, button = true, hat = true }

-- The config that baton takes, from the properties, checked as baton does not check it.
---@param self baton.input
local function config(self)
  local controls, axes = {}, {}
  for _, c in ipairs(self.controls) do
    local sources = {}
    for source in c.sources:gmatch("[^,%s]+") do
      local kind = source:match("^(.-):.")
      if not KINDS[kind] then
        error(("baton.input: the control %s has a source %s, which is not key:, sc:, mouse:, axis:, button: or hat:"):format(c.name, source), 0)
      end
      sources[#sources + 1] = source
    end
    controls[c.name] = sources
  end
  for _, p in ipairs(self.pairs) do
    for _, side in ipairs({ "left", "right", "up", "down" }) do
      if not controls[p[side]] then
        error(("baton.input: the pair %s names %s for %s, which is no control"):format(p.name, p[side], side), 0)
      end
    end
    axes[p.name] = { p.left, p.right, p.up, p.down }
  end
  return { controls = controls, pairs = axes, deadzone = self.deadzone, squareDeadzone = self.squareDeadzone }
end

-- The joystick that the property names, when it is connected.
local function joystickOf(index)
  if index < 1 or not love.joystick then
    return nil
  end
  return love.joystick.getJoysticks()[index]
end

function Input:load()
  local c = config(self)
  c.joystick = joystickOf(self.joystick)
  self.player = baton.new(c)
end

-- Reads the controls once each frame. A script that reads them in its update gets this frame's, when the input
-- updates before it: on the script's node, where needs puts it first (6.6), or on a node above.
function Input:update()
  self.player:update()
end

-- LÖVE's events: a joystick that is connected or taken out changes which one is this player's.
function Input:joystickadded()
  self.player.config.joystick = joystickOf(self.joystick)
end

function Input:joystickremoved()
  self.player.config.joystick = joystickOf(self.joystick)
end

-- Not called by the engine: scripts call these.

-- Binds the controls again from the properties, after a script changed them, as a game's menu of keys does:
-- input.controls[1].sources = "key:j"; input:apply(). The controls start up again, as at the start.
function Input:apply()
  self:load()
end

-- The rest are baton's own, on the player.

-- A control's value from 0 to 1, or a pair's x and y from -1 to 1.
---@param name string
---@return number x, number? y
function Input:get(name)
  return self.player:get(name)
end

-- As get, without the deadzone.
---@param name string
---@return number x, number? y
function Input:getRaw(name)
  return self.player:getRaw(name)
end

-- Whether a control or a pair is held.
---@param name string
---@return boolean
function Input:down(name)
  return self.player:down(name)
end

-- Whether it went down this frame.
---@param name string
---@return boolean
function Input:pressed(name)
  return self.player:pressed(name)
end

-- Whether it went up this frame.
---@param name string
---@return boolean
function Input:released(name)
  return self.player:released(name)
end

-- "kbm" when the keyboard or the mouse was used last, "joy" for the joystick, or "none": a game shows
-- "press Enter" or "press A" by it.
---@return "kbm"|"joy"|"none"
function Input:getActiveDevice()
  return self.player:getActiveDevice()
end

-- The joystick that is this player's, or nil.
---@return love.Joystick?
function Input:getJoystick()
  return self.player.config.joystick
end

-- baton's player, for what the component does not do.
---@return baton.Player
function Input:getPlayer()
  return self.player
end

return Input
