-- moonshine: the room is drawn through screen effects, which checkboxes turn on and off.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m14",
  name = "Effects",
  components = {
    moonshine = {
      chain = {
        order = { "pixelate", "crt", "scanlines", "vignette" },
      },
      effect = {
        crt = {},
        pixelate = { size = { x = 3, y = 3 } },
        scanlines = { opacity = 0.3 },
        vignette = {},
      },
    },
    room = {
      about = "moonshine.chain draws the room through its effects, in the chain's order. Each checkbox turns one on or off.",
      title = "Screen effects (moonshine)",
    },
  },
  children = {
    {
      id = "0rb1t4",
      name = "Orbit",
      posX = 460,
      posY = 210,
      components = {
        onlr = {
          paint = { color = { 0.95, 0.75, 0.3, 1 } },
          shape = { kind = "circle", radius = 30 },
        },
        spin = {},
      },
      children = {
        {
          id = "m00n14",
          name = "Moon",
          posX = 90,
          components = {
            onlr = {
              sprite = { image = "images/coin.png", origin = { x = 8, y = 8 } },
            },
          },
        },
      },
    },
    {
      id = "fx0114",
      name = "Pixelate",
      posX = 60,
      posY = 80,
      components = {
        effect = { name = "pixelate" },
        suit = { checkbox = { checked = true, height = 24, text = "pixelate", width = 160 } },
      },
    },
    {
      id = "fx0214",
      name = "CRT",
      posX = 60,
      posY = 116,
      components = {
        effect = { name = "crt" },
        suit = { checkbox = { checked = true, height = 24, text = "crt", width = 160 } },
      },
    },
    {
      id = "fx0314",
      name = "Scanlines",
      posX = 60,
      posY = 152,
      components = {
        effect = { name = "scanlines" },
        suit = { checkbox = { checked = true, height = 24, text = "scanlines", width = 160 } },
      },
    },
    {
      id = "fx0414",
      name = "Vignette",
      posX = 60,
      posY = 188,
      components = {
        effect = { name = "vignette" },
        suit = { checkbox = { checked = true, height = 24, text = "vignette", width = 160 } },
      },
    },
  },
}
