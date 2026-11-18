---@type onlr.NodeFile
return {
  format = 1,
  id = "st4rt0",
  name = "Start",
  children = {
    {
      id = "f1rst0",
      name = "First",
      components = {
        every = {
          beep = "sounds/beep.wav",
          box = {
            picture = "images/dot.png",
            width = 64,
          },
          count = 7,
          flag = false,
          font = {
            size = 30,
          },
          frames = {
            "images/dot.png",
            "images/dot.png",
          },
          gone = "a value of a property that the type no longer declares",
          next = "nodes/start.lua",
          notes = "notes.txt",
          other = "s3c0nd",
          picture = "images/dot.png",
          points = {
            {
              x = 1,
              y = 2,
            },
          },
          side = "right",
          target = "s3c0nd",
          tint = {
            0,
            0,
            1,
            1,
          },
        },
      },
    },
    {
      id = "s3c0nd",
      name = "Second",
      components = {
        every = {
          beep = "sounds/beep.wav",
        },
      },
    },
  },
}
