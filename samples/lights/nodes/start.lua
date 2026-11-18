-- The shadows package's sample: a white ground lit by one lamp in the dark, with a wall that casts a shadow, all
-- under a camera that shows the world as it is.
---@type onlr.NodeFile
return {
  format = 1,
  id = "l1ght0",
  name = "Start",
  children = {
    {
      id = "v1ew00",
      name = "View",
      components = {
        onlr = {
          camera = { view = { posX = 80, posY = 60 } },
        },
      },
      children = {
        {
          id = "w0rld0",
          name = "Lit",
          components = {
            shadows = { world = {} },
          },
          children = {
            {
              id = "gr0und",
              name = "Ground",
              posX = -300,
              posY = -300,
              components = {
                onlr = {
                  shape = { height = 700, width = 700 },
                },
              },
            },
            {
              id = "l4mp00",
              name = "Lamp",
              posX = 30,
              posY = 30,
              components = {
                shadows = {
                  light = { blur = false, radius = 120 },
                },
              },
            },
            {
              id = "w4ll00",
              name = "Wall",
              posX = 45,
              posY = 25,
              components = {
                shadows = {
                  shape = {
                    box = { height = 10, width = 5 },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
}
