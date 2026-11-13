---@type onlr.NodeFile
return {
  format = 1,
  id = "st4rt0",
  name = "Start",
  children = {
    {
      id = "w0r1dn",
      name = "World",
      components = {
        onlr = {
          camera = {},
        },
      },
      children = {
        {
          id = "r3d000",
          name = "Red",
          components = {
            onlr = {
              sprite = {
                image = "images/red.png",
              },
            },
          },
        },
        {
          id = "gr33n0",
          name = "Green",
          posX = 20,
          z = 5,
          components = {
            onlr = {
              shape = {
                color = { 0, 1, 0, 1 },
                height = 8,
                width = 8,
              },
            },
          },
        },
        {
          id = "b1u300",
          name = "Blue",
          posX = 20,
          z = 1,
          components = {
            onlr = {
              shape = {
                color = { 0, 0, 1, 1 },
                height = 8,
                width = 8,
              },
            },
          },
        },
      },
    },
    {
      id = "hud000",
      name = "Hud",
      components = {
        onlr = {
          shape = {
            height = 4,
            width = 4,
          },
        },
      },
    },
    {
      id = "sh1ft0",
      name = "Shifted",
      components = {
        shift = {},
      },
      children = {
        {
          id = "y3110w",
          name = "Yellow",
          posX = 300,
          z = 100,
          components = {
            onlr = {
              shape = {
                color = { 1, 1, 0, 1 },
                height = 8,
                width = 8,
              },
            },
          },
        },
      },
    },
    {
      id = "0v3r00",
      name = "Over",
      posX = 304,
      posY = 100,
      z = 1,
      components = {
        onlr = {
          shape = {
            color = { 1, 0, 1, 1 },
            height = 8,
            width = 4,
          },
        },
      },
    },
    {
      id = "t3xt00",
      name = "Text",
      posX = 100,
      posY = 200,
      components = {
        onlr = {
          text = {
            text = "Hi\nthere",
          },
        },
      },
    },
    {
      id = "c1rc13",
      name = "Circle",
      posX = 40,
      posY = 200,
      components = {
        onlr = {
          shape = {
            kind = "circle",
            radius = 6,
          },
        },
      },
    },
    {
      id = "p01y00",
      name = "Polygon",
      posX = 250,
      posY = 200,
      components = {
        onlr = {
          shape = {
            kind = "polygon",
            points = {
              { x = 0, y = 0 },
              { x = 10, y = 0 },
              { x = 10, y = 10 },
              { x = 0, y = 10 },
            },
          },
        },
      },
    },
  },
}
