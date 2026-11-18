-- The particles package's sample: a fountain that sprays upwards and falls, in the world; a burst that a script
-- emits at once; a puff that emits for half a second; and a ring of sparks that turns with its node.
---@type onlr.NodeFile
return {
  format = 1,
  id = "pa0r00",
  name = "Start",
  children = {
    {
      id = "f0unt0",
      name = "Fountain",
      posX = 40,
      posY = 100,
      components = {
        particles = {
          emitter = {
            colors = {
              { 0.4, 0.7, 1, 1 },
              { 0.4, 0.7, 1, 0 },
            },
            direction = -1.5708,
            emissionRate = 60,
            linearAcceleration = {
              max = { x = 0, y = 200 },
              min = { x = 0, y = 200 },
            },
            sizes = { 1, 0.5 },
            speed = { max = 120, min = 80 },
            spread = 0.4,
          },
        },
        probe = {},
      },
    },
    {
      id = "bur5t0",
      name = "Burst",
      posX = 80,
      posY = 60,
      components = {
        particles = {
          emitter = {
            autoStart = false,
            colors = {
              { 1, 0.8, 0.2, 1 },
              { 1, 0.2, 0.1, 0 },
            },
            particleLifetime = { max = 0.5, min = 0.5 },
            speed = { max = 100, min = 40 },
            spread = 6.2832,
          },
        },
        probe = {},
      },
    },
    {
      id = "pu7f00",
      name = "Puff",
      posX = 120,
      posY = 60,
      components = {
        particles = {
          emitter = {
            emissionArea = {
              distribution = "ellipse",
              dx = 10,
              dy = 6,
            },
            emitterLifetime = 0.5,
            particleLifetime = { max = 0.25, min = 0.25 },
          },
        },
        probe = {},
      },
    },
    {
      id = "r1ng00",
      name = "Ring",
      posX = 140,
      posY = 100,
      components = {
        particles = {
          emitter = {
            emissionArea = {
              distribution = "borderellipse",
              directionRelativeToCenter = true,
              dx = 12,
              dy = 12,
            },
            space = "local",
            speed = { max = 10, min = 10 },
          },
        },
      },
    },
  },
}
