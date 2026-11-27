-- The shaders sample (DESIGN 6.7, 10): squares side by side, each drawn through a shader as its node says. Every square is
-- white without one. The window has no camera, so a node's place is the window's pixels.
---@type onlr.NodeFile
return {
  format = 1,
  id = "st4rt0",
  name = "Start",
  children = {
    {
      id = "t1nt00",
      name = "Tinted",
      components = {
        onlr = {
          shader = {
            passes = { { shader = "effects/tint.glsl", values = { amount = 1, tint = { 1, 0, 0, 1 } } } },
          },
        },
      },
      children = {
        {
          id = "sq0001",
          name = "Red square",
          posX = 10,
          posY = 10,
          components = {
            onlr = {
              paint = {},
              shape = {
                height = 16,
                width = 16,
              },
            },
          },
        },
      },
    },
    {
      id = "t1nt02",
      name = "Tinted again",
      components = {
        onlr = {
          shader = {
            passes = { { shader = "effects/tint.glsl", values = { amount = 1, tint = { 0, 1, 0, 1 } } } },
          },
        },
      },
      children = {
        {
          id = "sq0002",
          name = "Green square",
          posX = 40,
          posY = 10,
          components = {
            onlr = {
              paint = {},
              shape = {
                height = 16,
                width = 16,
              },
            },
          },
        },
      },
    },
    {
      id = "d3f4ul",
      name = "Defaulted",
      components = {
        onlr = {
          shader = {
            passes = { { shader = "effects/tint.glsl" } },
          },
        },
      },
      children = {
        {
          id = "sq0d3f",
          name = "Defaulted square",
          posX = 70,
          posY = 10,
          components = {
            onlr = {
              paint = {},
              shape = {
                height = 16,
                width = 16,
              },
            },
          },
        },
      },
    },
    {
      id = "st4ck0",
      name = "Stacked",
      components = {
        onlr = {
          shader = {
            passes = {
              { shader = "effects/tint.glsl", values = { amount = 1, tint = { 1, 0, 0, 1 } } },
              { shader = "effects/shift.glsl", values = { shift = 10 } },
            },
          },
        },
      },
      children = {
        {
          id = "sqst4k",
          name = "Stacked square",
          posX = 10,
          posY = 50,
          components = {
            onlr = {
              paint = {},
              shape = {
                height = 8,
                width = 8,
              },
            },
          },
        },
      },
    },
    {
      id = "thr330",
      name = "Three passes",
      components = {
        onlr = {
          shader = {
            covers = "picture",
            passes = {
              { shader = "effects/tint.glsl", values = { amount = 1, tint = { 0, 1, 0, 1 } } },
              { shader = "effects/shift.glsl", values = { shift = 10 } },
              { shader = "effects/shift.glsl", values = { shift = 10 } },
            },
          },
        },
      },
      children = {
        {
          id = "sqthr3",
          name = "Three square",
          posX = 100,
          posY = 50,
          components = {
            onlr = {
              paint = {},
              shape = {
                height = 8,
                width = 8,
              },
            },
          },
        },
      },
    },
    {
      id = "m0ved0",
      name = "Moved",
      components = {
        onlr = {
          shader = {
            covers = "picture",
            passes = { { shader = "effects/shift.glsl", values = { shift = 10 } } },
          },
        },
      },
      children = {
        {
          id = "sq0003",
          name = "Moved square",
          posX = 100,
          posY = 10,
          components = {
            onlr = {
              paint = {},
              shape = {
                height = 8,
                width = 8,
              },
            },
          },
        },
      },
    },
    {
      id = "c10ck0",
      name = "Clock",
      components = {
        onlr = {
          shader = {
            passes = { { shader = "effects/clock.glsl", values = {} } },
          },
        },
      },
      children = {
        {
          id = "sq0004",
          name = "Clock square",
          posX = 150,
          posY = 10,
          components = {
            onlr = {
              paint = {},
              shape = {
                height = 16,
                width = 16,
              },
            },
          },
        },
      },
    },
    {
      id = "m4sk00",
      name = "Masked",
      components = {
        onlr = {
          shader = {
            passes = { { shader = "effects/mask.glsl", values = { pattern = "images/blue.png" } } },
          },
        },
      },
      children = {
        {
          id = "sq0006",
          name = "Blue square",
          posX = 230,
          posY = 10,
          components = {
            onlr = {
              paint = {},
              shape = {
                height = 16,
                width = 16,
              },
            },
          },
        },
      },
    },
    {
      id = "f0rg0t",
      name = "Forgetful",
      posX = 190,
      posY = 10,
      components = {
        forget = {
          shader = "effects/tint.glsl",
        },
      },
    },
    {
      id = "sq0005",
      name = "After",
      posX = 205,
      posY = 10,
      components = {
        onlr = {
          paint = {},
          shape = {
            height = 16,
            width = 16,
          },
        },
      },
    },
  },
}
