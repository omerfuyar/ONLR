-- love.physics: crates that fall and bounce, a click drops another, and a pendulum on a hinge.
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
      about = "physics.world, bodies, shapes and a hinge. A click drops a crate where the pointer is.",
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
          shape = { color = { 0.4, 0.45, 0.5, 1 }, height = 20, width = 560 },
        },
        physics = {
          body = { type = "static" },
          shape = {
            box = { center = { x = 280, y = 10 }, height = 20, width = 560 },
          },
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
          shape = { color = { 0.4, 0.45, 0.5, 1 }, height = 12, width = 180 },
        },
        physics = {
          body = { type = "static" },
          shape = {
            box = { center = { x = 90, y = 6 }, height = 12, width = 180 },
          },
        },
      },
    },
    {
      id = "cr4t61",
      instance = {
        base = "nodes/parts/crate.lua",
        changes = {
          ["cr4t00"] = { posX = 150, posY = 80 },
        },
      },
    },
    {
      id = "cr4t62",
      instance = {
        base = "nodes/parts/crate.lua",
        changes = {
          ["cr4t00"] = { posX = 300, posY = 60, rot = 0.5 },
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
          shape = { kind = "circle", radius = 4 },
        },
        physics = {
          body = { type = "static" },
          joint = {
            hinge = { other = "b0b006" },
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
          shape = { color = { 0.95, 0.6, 0.2, 1 }, kind = "circle", radius = 14 },
        },
        physics = {
          body = {},
          shape = {
            circle = { radius = 14 },
          },
        },
      },
    },
  },
}
