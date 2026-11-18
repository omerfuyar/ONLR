-- LÖVE's particles: a fountain, a ring that turns with its node, and a burst at each click.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m08",
  name = "Particles",
  components = {
    room = {
      about = "particles.emitter: a fountain in the world, a ring in its node's space. A click makes a burst, which ends itself.",
      title = "Particles",
    },
    spawner = {
      file = "nodes/parts/burst.lua",
    },
  },
  children = {
    {
      id = "f0unt8",
      name = "Fountain",
      posX = 160,
      posY = 320,
      components = {
        particles = {
          emitter = {
            colors = { { 0.4, 0.7, 1, 1 }, { 0.4, 0.7, 1, 0 } },
            direction = -1.5708,
            emissionRate = 120,
            linearAcceleration = { max = { x = 0, y = 300 }, min = { x = 0, y = 300 } },
            particleLifetime = { max = 1.4, min = 1 },
            sizes = { 1.2, 0.4 },
            speed = { max = 260, min = 200 },
            spread = 0.4,
          },
        },
      },
    },
    {
      id = "r1ng08",
      name = "Ring",
      posX = 460,
      posY = 200,
      components = {
        particles = {
          emitter = {
            colors = { { 1, 0.9, 0.4, 1 }, { 1, 0.5, 0.2, 0 } },
            emissionArea = { distribution = "borderellipse", dx = 60, dy = 60 },
            emissionRate = 80,
            particleLifetime = { max = 0.6, min = 0.4 },
            space = "local",
          },
        },
        spin = { speed = 2 },
      },
    },
  },
}
