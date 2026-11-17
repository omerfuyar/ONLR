-- The anim8 package's sample: two balls of one sprite sheet. The first rolls, as its first animation does; the second
-- starts with a jump, named by first, which plays once and stops on its last frame.
---@type onlr.NodeFile
return {
  format = 1,
  id = "an1m00",
  name = "Start",
  children = {
    {
      id = "r0ller",
      name = "Roller",
      posX = 40,
      posY = 60,
      components = {
        anim8 = {
          animation = {
            animations = {
              {
                columns = "1-4",
                duration = 0.1,
                loop = true,
                name = "roll",
                rows = "1",
              },
              {
                columns = "1-3",
                duration = 0.1,
                loop = false,
                name = "jump",
                rows = "2",
              },
            },
            frameHeight = 16,
            frameWidth = 16,
          },
        },
        onlr = {
          sprite = {
            image = "images/sheet.png",
            origin = {
              x = 8,
              y = 8,
            },
          },
        },
        probe = {},
      },
    },
    {
      id = "jump3r",
      name = "Jumper",
      posX = 120,
      posY = 60,
      components = {
        anim8 = {
          animation = {
            animations = {
              {
                columns = "1-4",
                duration = 0.1,
                loop = true,
                name = "roll",
                rows = "1",
              },
              {
                columns = "4-1",
                duration = 0.2,
                loop = false,
                name = "jump",
                rows = "2",
              },
            },
            first = "jump",
            frameHeight = 16,
            frameWidth = 16,
          },
        },
        onlr = {
          sprite = {
            image = "images/sheet.png",
            origin = {
              x = 8,
              y = 8,
            },
          },
        },
        probe = {},
      },
    },
  },
}
