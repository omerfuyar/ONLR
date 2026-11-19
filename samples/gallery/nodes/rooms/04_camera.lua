-- A camera and its helpers: it follows the player, stays inside the level's edges, and shakes.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m04",
  name = "Camera",
  components = {
    room = {
      about = "Arrows move. The camera follows with a deadzone, stops at the level's edges, and Space shakes it.",
      title = "Camera, follow, limits and shake",
    },
  },
  children = {
    {
      id = "w0rld4",
      name = "World",
      components = {
        onlr = {
          camera = {
            follow = { deadzone = { x = 60, y = 40 }, target = "p1ay04" },
            limits = { height = 720, width = 1280 },
            shake = {},
            view = { height = 360, posX = 320, posY = 180, width = 640 },
          },
        },
        shaker = {},
      },
      children = {
        {
          id = "fl00r4",
          name = "Level",
          components = {
            onlr = {
              paint = { color = { 0.16, 0.2, 0.26, 1 } },
              shape = { height = 720, width = 1280 },
            },
          },
        },
        {
          id = "p1ll41",
          name = "Pillar",
          posX = 300,
          posY = 200,
          components = {
            onlr = {
              paint = { color = { 0.5, 0.4, 0.7, 1 } },
              shape = { height = 200, width = 40 },
            },
          },
        },
        {
          id = "p1ll42",
          name = "Pillar 2",
          posX = 800,
          posY = 400,
          components = {
            onlr = {
              paint = { color = { 0.3, 0.6, 0.6, 1 } },
              shape = { height = 160, width = 160 },
            },
          },
        },
        {
          id = "p1ay04",
          name = "Player",
          posX = 320,
          posY = 400,
          components = {
            arrows = { speed = 240 },
            onlr = {
              sprite = { image = "images/player.png", origin = { x = 16, y = 24 } },
            },
          },
        },
      },
    },
  },
}
