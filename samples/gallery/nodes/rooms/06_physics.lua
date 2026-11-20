-- love.physics: crates that fall and bounce, a click drops another, a pendulum on a hinge, and a cart whose wheels' joints
-- spring and drive it.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m06",
  name = "Physics",
  components = {
    physics = {
      world = {},
    },
    room = {
      about = "physics.world, bodies, shapes, a hinge, and a cart whose wheel joints spring and drive. A click drops a crate.",
      title = "Physics (love.physics)",
    },
    spawner = {
      file = "nodes/parts/crate.lua",
    },
  },
  children = {
    {
      id = "gr0nd6",
      name = "Ground",
      posX = 40,
      posY = 320,
      components = {
        onlr = {
          paint = {
            color = {
              0.4,
              0.45,
              0.5,
              1,
            },
          },
          shape = {
            height = 20,
            width = 560,
          },
        },
        physics = {
          body = {
            type = "static",
          },
          fixture = {},
        },
      },
    },
    {
      id = "r4mp06",
      name = "Ramp",
      posX = 120,
      posY = 220,
      rot = 0.4,
      components = {
        onlr = {
          paint = {
            color = {
              0.4,
              0.45,
              0.5,
              1,
            },
          },
          shape = {
            height = 12,
            width = 180,
          },
        },
        physics = {
          body = {
            type = "static",
          },
          fixture = {},
        },
      },
    },
    {
      id = "cr4t61",
      instance = {
        base = "nodes/parts/crate.lua",
        changes = {
          ["cr4t00"] = {
            posX = 150,
            posY = 80,
          },
        },
      },
    },
    {
      id = "cr4t62",
      instance = {
        base = "nodes/parts/crate.lua",
        changes = {
          ["cr4t00"] = {
            posX = 300,
            posY = 60,
            rot = 0.5,
          },
        },
      },
    },
    {
      id = "c4rt06",
      name = "Cart",
      posX = 100,
      posY = 280,
      components = {
        onlr = {
          paint = {
            color = { 0.35, 0.7, 0.45, 1 },
          },
          shape = {
            height = 14,
            origin = { x = 30, y = 7 },
            width = 60,
          },
        },
        physics = {
          body = {},
          fixture = {},
        },
      },
      -- each axle holds a wheel to the cart, on a spring along the cart's own down, and its motor turns the wheel
      children = {
        {
          id = "4x1e06",
          name = "Back axle",
          posX = -22,
          posY = 16,
          components = {
            physics = {
              joint = {
                axis = { x = 0, y = 1 },
                kind = "wheel",
                motor = true,
                motorSpeed = 4,
                motorTorque = 3000,
                other = "wh1l06",
              },
            },
          },
        },
        {
          id = "4x2e06",
          name = "Front axle",
          posX = 22,
          posY = 16,
          components = {
            physics = {
              joint = {
                axis = { x = 0, y = 1 },
                kind = "wheel",
                motor = true,
                motorSpeed = 4,
                motorTorque = 3000,
                other = "wh2l06",
              },
            },
          },
        },
      },
    },
    {
      id = "wh1l06",
      name = "Back wheel",
      posX = 78,
      posY = 296,
      components = {
        onlr = {
          paint = {
            color = { 0.85, 0.85, 0.9, 1 },
          },
          shape = {
            kind = "circle",
            radius = 10,
          },
        },
        physics = {
          body = {},
          fixture = {
            friction = 1,
          },
        },
      },
    },
    {
      id = "wh2l06",
      name = "Front wheel",
      posX = 122,
      posY = 296,
      components = {
        onlr = {
          paint = {
            color = { 0.85, 0.85, 0.9, 1 },
          },
          shape = {
            kind = "circle",
            radius = 10,
          },
        },
        physics = {
          body = {},
          fixture = {
            friction = 1,
          },
        },
      },
    },
    {
      id = "p1v0t6",
      name = "Pivot",
      posX = 480,
      posY = 80,
      components = {
        onlr = {
          paint = {},
          shape = {
            kind = "circle",
            radius = 4,
          },
        },
        physics = {
          body = {
            type = "static",
          },
          joint = {
            other = "b0b006",
          },
        },
      },
    },
    {
      id = "b0b006",
      name = "Bob",
      posX = 560,
      posY = 80,
      components = {
        onlr = {
          paint = {
            color = {
              0.95,
              0.6,
              0.2,
              1,
            },
          },
          shape = {
            kind = "circle",
            radius = 14,
          },
        },
        physics = {
          body = {},
          fixture = {},
        },
      },
    },
  },
}
