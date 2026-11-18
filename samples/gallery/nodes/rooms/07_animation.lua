-- anim8: balls of one sprite sheet that roll, and jump at a click.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m07",
  name = "Animation",
  components = {
    room = {
      about = "anim8.animation sets its sprite's quad from a sheet's frames. A click plays jump once, then roll again.",
      title = "Animation of a sprite sheet (anim8)",
    },
  },
  children = {
    {
      id = "r0ll71",
      name = "Ball",
      posX = 200,
      posY = 200,
      sclX = 4,
      sclY = 4,
      components = {
        anim8 = {
          animation = {
            animations = {
              { columns = "1-4", duration = 0.1, loop = true, name = "roll", rows = "1" },
              { columns = "1-3", duration = 0.12, loop = false, name = "jump", rows = "2" },
            },
            frameHeight = 16,
            frameWidth = 16,
          },
        },
        jumper = {},
        onlr = {
          sprite = { image = "images/sheet.png", origin = { x = 8, y = 8 } },
        },
      },
    },
    {
      id = "r0ll72",
      name = "Slow ball",
      posX = 400,
      posY = 200,
      sclX = 4,
      sclY = 4,
      components = {
        anim8 = {
          animation = {
            animations = {
              { columns = "1-4", duration = 0.3, loop = true, name = "roll", rows = "1" },
              { columns = "1-3", duration = 0.3, loop = false, name = "jump", rows = "2" },
            },
            frameHeight = 16,
            frameWidth = 16,
          },
        },
        jumper = {},
        onlr = {
          sprite = { color = { 0.6, 0.8, 1, 1 }, image = "images/sheet.png", origin = { x = 8, y = 8 } },
        },
      },
    },
  },
}
