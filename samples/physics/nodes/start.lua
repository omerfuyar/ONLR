-- The physics package's sample: a ball and a crate fall onto the ground. The crate is one body of two boxes, each on a
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
          box = {
            height = 20,
            width = 300,
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
          circle = {
            radius = 10,
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
              box = {
                height = 20,
                width = 10,
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
}
