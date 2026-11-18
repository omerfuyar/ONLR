-- The component type audio.source: a sound of LÖVE's at its node, decoded whole when it loads, for short sounds
-- such as a jump or a coin. It plays, loops and pauses with its node, and may play from the node's place.
-- audio.music is the same, streamed. Their code is the package's player.lua.
local player = require("audio.player")

---@class audio.source : audio.player
local Source = {}

player.declare(Source, "audio.source", false)

return Source
