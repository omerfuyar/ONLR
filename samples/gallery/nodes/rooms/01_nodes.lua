-- Nodes and the engine's components: a sprite, a text and shapes, and a node that turns with its children.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m01",
  name = "Nodes",
  components = {
    room = {
      about = "A node has a place and components: a sprite, a text, shapes. Children move and turn with their parent.",
      title = "Nodes and drawing",
    },
  },
  children = {
    {
      id = "s1gn00",
      name = "Sign",
      posX = 40,
      posY = 70,
      components = {
        onlr = {
          text = { color = { 0.6, 0.85, 1, 1 }, text = "onlr.text, onlr.sprite and onlr.shape", width = 400 },
        },
      },
    },
    {
      id = "c01ns0",
      name = "Sprite",
      posX = 60,
      posY = 120,
      sclX = 3,
      sclY = 3,
      components = {
        onlr = {
          sprite = { image = "images/coin.png", origin = { x = 8, y = 8 } },
        },
      },
    },
    {
      id = "b0x000",
      name = "Box",
      posX = 110,
      posY = 100,
      components = {
        onlr = {
          paint = { color = { 0.9, 0.3, 0.35, 1 } },
          shape = { height = 40, width = 60 },
        },
      },
    },
    {
      id = "r1ng00",
      name = "Ring",
      posX = 230,
      posY = 120,
      components = {
        onlr = {
          paint = { color = { 0.4, 0.9, 0.5, 1 }, lineWidth = 4, mode = "line" },
          shape = { kind = "circle", radius = 22 },
        },
      },
    },
    {
      id = "p0ly00",
      name = "Star",
      posX = 300,
      posY = 120,
      components = {
        onlr = {
          paint = {
            color = { 1, 0.85, 0.3, 1 },
          },
          shape = {
            kind = "polygon",
            points = { { x = 0, y = -24 }, { x = 20, y = 16 }, { x = -20, y = 16 } },
          },
        },
      },
    },
    {
      id = "0rb1t0",
      name = "Orbit",
      posX = 460,
      posY = 220,
      components = {
        onlr = {
          paint = { color = { 0.95, 0.75, 0.3, 1 } },
          shape = { kind = "circle", radius = 18 },
        },
        spin = {},
      },
      children = {
        {
          id = "m00n01",
          name = "Moon",
          posX = 70,
          components = {
            onlr = {
              paint = { color = { 0.6, 0.7, 1, 1 } },
              shape = { kind = "circle", radius = 8 },
            },
            spin = { speed = -4 },
          },
          children = {
            {
              id = "m00n02",
              name = "Pebble",
              posX = 18,
              components = {
                onlr = {
                  paint = {},
                  shape = { kind = "circle", radius = 3 },
                },
              },
            },
          },
        },
      },
    },
    {
      id = "l1ne00",
      name = "Line",
      posX = 40,
      posY = 300,
      components = {
        onlr = {
          paint = {
            color = { 0.7, 0.7, 0.75, 1 },
            lineWidth = 2,
          },
          shape = {
            kind = "line",
            points = { { x = 0, y = 0 }, { x = 100, y = -40 }, { x = 200, y = 0 }, { x = 300, y = -40 } },
          },
        },
      },
    },
  },
}
