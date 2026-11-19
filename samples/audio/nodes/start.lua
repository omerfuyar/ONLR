-- The audio package's sample: the ears at the window's middle; music that streams and loops, a source with stream on; a beep that a script
-- plays; and a hum to the right that plays from its node's place.
---@type onlr.NodeFile
return {
  format = 1,
  id = "au0d00",
  name = "Start",
  children = {
    {
      id = "e4rs00",
      name = "Ears",
      posX = 80,
      posY = 60,
      components = {
        audio = {
          listener = {
            distanceModel = "linearclamped",
            volume = 0.5,
          },
        },
      },
    },
    {
      id = "s0ng00",
      name = "Song",
      components = {
        audio = {
          source = {
            autoPlay = true,
            looping = true,
            sound = { path = "sounds/song.wav", stream = true },
            volume = 0.4,
          },
        },
      },
    },
    {
      id = "b33p00",
      name = "Beep",
      components = {
        audio = {
          source = {
            sound = "sounds/beep.wav",
          },
        },
        probe = {},
      },
    },
    {
      id = "hum000",
      name = "Hum",
      posX = 280,
      posY = 60,
      components = {
        audio = {
          source = {
            attenuation = { max = 400, reference = 50 },
            autoPlay = true,
            looping = true,
            positional = true,
            sound = "sounds/hum.wav",
          },
        },
      },
    },
  },
}
