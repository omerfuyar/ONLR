-- onlr.shader: nodes drawn through GLSL files, each draw on its own, or the nodes as one picture.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m16",
  name = "Shaders",
  components = {
    room = {
      about = "onlr.shader draws a node and its children through a GLSL file, with the values that the inspector gives. Flash and Gray shade each draw; Wave bends its banner as one picture, then a second pass grays it. A GLSL file's notes give each value its range and start.",
      title = "Shaders (onlr.shader)",
    },
  },
  children = {
    {
      id = "sh01x0",
      name = "Flash",
      posX = 90,
      posY = 200,
      sclX = 2,
      sclY = 2,
      components = {
        onlr = {
          shader = { passes = { { shader = "effects/flash.glsl" } } },
          sprite = { image = "images/player.png", origin = { x = 16, y = 24 } },
        },
      },
    },
    {
      id = "sh02x0",
      name = "Gray",
      posX = 210,
      posY = 200,
      components = {
        onlr = {
          paint = { color = { 0.9, 0.3, 0.3, 1 } },
          shader = { passes = { { shader = "effects/gray.glsl", values = { amount = 1 } } } },
          shape = { kind = "circle", radius = 40 },
        },
      },
    },
    {
      id = "sh03x0",
      name = "Wave",
      posX = 330,
      posY = 140,
      components = {
        onlr = {
          shader = { covers = "picture", passes = { { shader = "effects/wave.glsl" }, { shader = "effects/gray.glsl", values = { amount = 0.7 } } } },
        },
      },
      children = {
        {
          id = "sh04x0",
          name = "Banner",
          components = {
            onlr = {
              paint = { color = { 0.3, 0.6, 0.95, 1 } },
              shape = { height = 120, width = 260 },
            },
          },
        },
        {
          id = "sh05x0",
          name = "Coin",
          posX = 130,
          posY = 60,
          sclX = 4,
          sclY = 4,
          components = {
            onlr = {
              sprite = { image = "images/coin.png", origin = { x = 8, y = 8 } },
            },
          },
        },
      },
    },
  },
}
