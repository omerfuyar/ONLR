-- LÖVE's sound: buttons that play sounds, music that a checkbox pauses, and a hum that moves from ear to ear.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m12",
  name = "Sound",
  components = {
    room = {
      about = "audio.source, audio.music and audio.listener. The hum slides past the listener, from the left to the right.",
      title = "Sound (love.audio)",
    },
  },
  children = {
    {
      id = "e4rs12",
      name = "Ears",
      posX = 320,
      posY = 260,
      components = {
        audio = {
          listener = { distanceModel = "linearclamped" },
        },
        onlr = {
          paint = { color = { 0.6, 0.85, 1, 1 }, mode = "line" },
          shape = { kind = "circle", radius = 14 },
        },
      },
    },
    {
      id = "b33p12",
      name = "Beep",
      posX = 60,
      posY = 80,
      components = {
        audio = {
          source = { sound = "sounds/beep.wav" },
        },
        player = { sound = "b33p12" },
        suit = {
          button = { height = 28, text = "Play a beep", width = 140 },
        },
      },
    },
    {
      id = "mus1c2",
      name = "Music",
      components = {
        audio = {
          music = { sound = "sounds/song.wav", volume = 0.3 },
        },
      },
    },
    {
      id = "sw1tc2",
      name = "Music on",
      posX = 60,
      posY = 130,
      components = {
        suit = {
          checkbox = { checked = true, height = 28, text = "Music", width = 140 },
        },
        switch = { target = "mus1c2" },
      },
    },
    {
      id = "h0m012",
      name = "Hum",
      posX = 120,
      posY = 260,
      components = {
        audio = {
          source = {
            attenuation = { max = 500, reference = 60 },
            autoPlay = true,
            looping = true,
            positional = true,
            sound = "sounds/hum.wav",
            volume = 0.6,
          },
        },
        bouncer = { time = 3, to = { x = 400, y = 0 } },
        onlr = {
          paint = { color = { 1, 0.85, 0.4, 1 } },
          shape = { kind = "circle", radius = 10 },
        },
      },
    },
  },
}
