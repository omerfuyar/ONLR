-- The physics package's sample: a ball, a crate, a triangle and a welded lid fall onto the ground, and a pendulum, a
-- weight on a rope and a ball on a stick hang from static bodies. The crate is one body of two boxes, each on a
-- node of its own under the body's node. The root has the world; a body would add one if it had none.
---@type onlr.NodeFile
return {
  format = 1,
  id = "ph0r00",
  name = "Level",
  components = {
    physics = {
      world = {},
    },
  },
  children = {
    {
      id = "gr0und",
      name = "Ground",
      posX = 160,
      posY = 220,
      components = {
        physics = {
          body = {
            type = "static",
          },
          shape = {
            box = {
              height = 20,
              width = 300,
            },
          },
        },
      },
    },
    {
      id = "ba11ab",
      name = "Ball",
      posX = 80,
      posY = 50,
      components = {
        physics = {
          body = {},
          shape = {
            circle = {
              radius = 10,
            },
          },
        },
        probe = {},
      },
    },
    {
      id = "cr8te0",
      name = "Crate",
      posX = 220,
      posY = 50,
      components = {
        physics = {
          body = {
            fixedRotation = true,
          },
        },
        probe = {},
      },
      children = {
        {
          id = "cr8lft",
          name = "Left",
          posX = -10,
          components = {
            physics = {
              shape = {
                box = {
                  height = 20,
                  width = 10,
                },
              },
            },
          },
        },
        {
          id = "cr8rgt",
          name = "Right",
          posX = 10,
          components = {
            physics = {
              shape = {
                box = {
                  height = 20,
                  width = 10,
                },
              },
            },
          },
        },
      },
    },
    {
      id = "tr1ang",
      name = "Triangle",
      posX = 150,
      posY = 50,
      components = {
        physics = {
          body = {
            fixedRotation = true,
          },
          shape = {
            polygon = {
              points = {
                {
                  x = -15,
                  y = 10,
                },
                {
                  x = 15,
                  y = 10,
                },
                {
                  x = 0,
                  y = -10,
                },
              },
            },
          },
        },
      },
    },
    {
      id = "n4il00",
      name = "Nail",
      posX = 290,
      posY = 20,
      components = {
        physics = {
          body = {
            type = "static",
          },
          joint = {
            hinge = {
              other = "b0b000",
            },
          },
        },
      },
    },
    {
      id = "b0b000",
      name = "Bob",
      posX = 250,
      posY = 20,
      components = {
        physics = {
          body = {},
          shape = {
            circle = {
              radius = 5,
            },
          },
        },
      },
    },
    {
      id = "h00k00",
      name = "Hook",
      posX = 20,
      posY = 20,
      components = {
        physics = {
          body = {
            type = "static",
          },
          joint = {
            rope = {
              length = 30,
              other = "w8ight",
            },
          },
        },
      },
    },
    {
      id = "w8ight",
      name = "Weight",
      posX = 20,
      posY = 40,
      components = {
        physics = {
          body = {},
          shape = {
            circle = {
              radius = 5,
            },
          },
        },
      },
    },
    {
      id = "p0st00",
      name = "Post",
      posX = 300,
      posY = 150,
      components = {
        physics = {
          body = {
            type = "static",
          },
          joint = {
            distance = {
              other = "sw1ng0",
            },
          },
        },
      },
    },
    {
      id = "sw1ng0",
      name = "Swing",
      posX = 300,
      posY = 120,
      components = {
        physics = {
          body = {},
          shape = {
            circle = {
              radius = 5,
            },
          },
        },
      },
    },
    {
      id = "l1d000",
      name = "Lid",
      posX = 220,
      posY = 35,
      components = {
        physics = {
          body = {},
          joint = {
            weld = {
              other = "cr8te0",
            },
          },
          shape = {
            box = {
              height = 10,
              width = 10,
            },
          },
        },
      },
    },
  },
}
