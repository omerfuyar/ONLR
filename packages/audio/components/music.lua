-- The component type audio.music: a sound of LÖVE's at its node that LÖVE streams as it plays, for music and other
-- long sounds. It plays and loops from its start by default. audio.source is the same, decoded whole.
local player = require("audio.player")

---@class audio.music : audio.player
local Music = {}

player.declare(Music, "audio.music", true)

return Music
