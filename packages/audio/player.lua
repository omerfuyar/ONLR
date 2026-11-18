-- What audio.source and audio.music share: they differ only in how LÖVE loads the file, decoded whole or streamed.
-- player.declare gives a type the properties and the functions.
local onlr = require("onlr")

local player = {}

---@class audio.player : onlr.Component
---@field sound love.Source?
---@field autoPlay boolean
---@field looping boolean
---@field volume number
---@field pitch number
---@field positional boolean
---@field attenuation {reference: number, max: number}
---@field rolloff number
---@field private copies love.Source[]? what playNew plays, until each ends
---@field private held love.Source[]? what disable paused, which enable plays on
---@field private playing boolean? play was called and the sound has not ended or stopped since
---@field private started boolean? it has been enabled once, so autoPlay is done
---@field private applied table? the values last given to LÖVE
local Player = {}

-- What the component is, for its errors.
local function where(self)
  return ("%s on %s"):format(self._type, self.node.name)
end

-- Gives a source the properties that a script may change while it plays.
---@param self audio.player
local function settle(self, source)
  source:setVolume(self.volume)
  source:setPitch(self.pitch)
  if self.positional then
    source:setAttenuationDistances(self.attenuation.reference, self.attenuation.max)
    source:setRolloff(self.rolloff)
  end
end

-- Puts a positional source at its node's place in the world.
local function place(self, source)
  local x, y = self.node:toWorld(0, 0)
  source:setPosition(x, y, 0)
end

function Player:load()
  self.copies = {}
  local source = self.sound
  if not source then
    return
  end
  if source:getChannelCount() > 1 then
    if self.positional then
      error(("%s: a sound with a place has one channel, and this one has %d. Save it as mono"):format(where(self), source:getChannelCount()), 0)
    end
  else
    -- A mono sound without a place plays at the listener, as a stereo one does, wherever the listener is.
    source:setRelative(not self.positional)
    if self.positional then
      place(self, source)
    else
      source:setPosition(0, 0, 0)
    end
  end
  source:setLooping(self.looping)
  settle(self, source)
  self.applied = {
    volume = self.volume,
    pitch = self.pitch,
    looping = self.looping,
    reference = self.attenuation.reference,
    max = self.attenuation.max,
    rolloff = self.rolloff,
  }
end

function Player:enable()
  if not self.sound then
    return
  end
  if not self.started then
    self.started = true
    if self.autoPlay then
      self:play()
    end
    return
  end
  for _, source in ipairs(self.held or {}) do
    source:play()
  end
  self.held = nil
end

-- A node turned off pauses its sounds, and they play on when it is on again.
function Player:disable()
  if not self.sound then
    return
  end
  local held = {}
  for _, source in ipairs({ self.sound, unpack(self.copies) }) do
    if source:isPlaying() then
      source:pause()
      held[#held + 1] = source
    end
  end
  self.held = held
end

function Player:destroy()
  if self.sound then
    self:stop()
  end
end

-- Gives LÖVE what a script or a tween changed, follows the node, and tells the node when the sound ended.
function Player:update()
  local source, a = self.sound, self.applied
  if not source or not a then
    return
  end
  if a.volume ~= self.volume or a.pitch ~= self.pitch or a.reference ~= self.attenuation.reference
    or a.max ~= self.attenuation.max or a.rolloff ~= self.rolloff then
    settle(self, source)
    a.volume, a.pitch, a.rolloff = self.volume, self.pitch, self.rolloff
    a.reference, a.max = self.attenuation.reference, self.attenuation.max
  end
  if a.looping ~= self.looping then
    source:setLooping(self.looping)
    a.looping = self.looping
  end
  for i = #self.copies, 1, -1 do
    if not self.copies[i]:isPlaying() then
      table.remove(self.copies, i)
    end
  end
  if self.positional then
    place(self, source)
    for _, copy in ipairs(self.copies) do
      place(self, copy)
    end
  end
  if self.playing and not source:isPlaying() and source:tell() == 0 then
    self.playing = false
    self.node:send("soundEnd")
  end
end

-- In the node view, a speaker at the node, and for a sound with a place, the circles where it starts to fade and
-- where it fades no more.
function Player:drawEditor(chosen)
  love.graphics.setColor(1, 0.85, 0.4, chosen and 1 or 0.7)
  love.graphics.polygon("fill", -6, -3, -2, -3, 3, -7, 3, 7, -2, 3, -6, 3)
  if chosen and self.positional then
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", 0, 0, self.attenuation.reference)
    love.graphics.setColor(1, 0.85, 0.4, 0.4)
    love.graphics.circle("line", 0, 0, self.attenuation.max)
  end
end

function Player:bounds()
  return -8, -8, 16, 16
end

-- Not called by the engine: scripts call these. They are LÖVE's own, on the source.

-- Plays the sound: from its start when it is stopped, or on from where pause left it. A sound that plays already
-- plays on; playNew plays it over itself. Its node is told soundEnd() when it plays to its end, and not at stop.
function Player:play()
  local source = assert(self.sound, where(self) .. ": no sound")
  self.playing = true
  source:play()
end

-- Plays a new copy of the sound, with its values, over the copies that play already, as shots and steps do.
-- It plays to its end, follows the node with a place, and stop stops it. Returns LÖVE's source of the copy.
---@return love.Source
function Player:playNew()
  local copy = assert(self.sound, where(self) .. ": no sound"):clone()
  copy:seek(0)
  copy:setLooping(false)
  copy:play()
  self.copies[#self.copies + 1] = copy
  return copy
end

-- Stops the sound and its copies, and goes back to its start. Its node is not told soundEnd.
function Player:stop()
  self.playing = false
  self.held = nil
  if self.sound then
    self.sound:stop()
  end
  for _, copy in ipairs(self.copies) do
    copy:stop()
  end
  self.copies = {}
end

-- Pauses the sound where it is, and play plays on from there. The copies play on.
function Player:pause()
  if self.sound then
    self.sound:pause()
  end
end

---@return boolean
function Player:isPlaying()
  return self.sound ~= nil and self.sound:isPlaying()
end

-- Goes to a time of the sound, in seconds.
---@param seconds number
function Player:seek(seconds)
  assert(self.sound, where(self) .. ": no sound"):seek(seconds)
end

-- The time of the sound where it plays, in seconds.
---@return number
function Player:tell()
  return self.sound and self.sound:tell() or 0
end

-- The sound's length, in seconds.
---@return number
function Player:getDuration()
  return self.sound and self.sound:getDuration() or 0
end

-- LÖVE's source, for what the component does not do, such as setFilter or setEffect.
---@return love.Source?
function Player:get()
  return self.sound
end

-- Gives a type the properties and the functions. stream: LÖVE streams the file, as music needs.
---@param Type table
---@param name string the type's name, for its errors
---@param stream boolean
function player.declare(Type, name, stream)
  Type._type = name
  Type.sound = onlr.property.sound({
    stream = stream,
    description = stream and "A sound file, which LÖVE streams as it plays, as music needs" or "A sound file, which LÖVE decodes whole when it loads, as short sounds need",
  })
  Type.autoPlay = onlr.property.bool(stream, { description = "It plays from its start. Without, a script calls play" })
  Type.looping = onlr.property.bool(stream, { description = "It plays again from the start when it ends" })
  Type.volume = onlr.property.number(1, { min = 0, max = 1 })
  Type.pitch = onlr.property.number(1, { min = 0.01, description = "1 is as the file is; 2 is an octave higher, and faster" })
  Type.positional = onlr.property.bool(false, {
    heading = "Place",
    description = "It plays from its node's place, louder near the audio.listener and from its side. The file must be mono",
  })
  Type.attenuation = onlr.property.group({
    reference = onlr.property.number(100, { min = 0 }),
    max = onlr.property.number(1000, { min = 0 }),
  }, { description = "In pixels: nearer than reference it is at its volume; farther, it fades, until max. As setAttenuationDistances" })
  Type.rolloff = onlr.property.number(1, { min = 0, description = "How fast it fades with distance. 0 does not fade" })
  for key, value in pairs(Player) do
    Type[key] = value
  end
end

return player
