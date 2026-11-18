-- The suit package's sample: a menu of a button, a checkbox, a slider and a text field at the window's pixels, and a
-- coin that is a button in a world that a camera shows twice as large.
---@type onlr.NodeFile
return {
  format = 1,
  id = "u10000",
  name = "Start",
  children = {
    {
      id = "p1ay00",
      name = "Play",
      posX = 10,
      posY = 10,
      components = {
        probe = {},
        suit = {
          button = { height = 20, text = "Play", width = 60 },
        },
      },
    },
    {
      id = "s0und0",
      name = "Sound",
      posX = 10,
      posY = 40,
      components = {
        probe = {},
        suit = {
          checkbox = { checked = true, height = 20, text = "Sound", width = 80 },
        },
      },
    },
    {
      id = "v0lume",
      name = "Volume",
      posX = 10,
      posY = 70,
      components = {
        probe = {},
        suit = {
          slider = { value = 0.5, width = 100, height = 16 },
        },
      },
    },
    {
      id = "n4me00",
      name = "Name",
      posX = 10,
      posY = 95,
      components = {
        probe = {},
        suit = {
          input = { text = "ab", width = 100, height = 20 },
        },
      },
    },
    {
      id = "w0rld0",
      name = "World",
      components = {
        onlr = {
          camera = { view = { posX = 0, posY = 0, zoom = 2 } },
        },
      },
      children = {
        {
          id = "c01n00",
          name = "Coin",
          posX = 30,
          posY = 10,
          components = {
            probe = {},
            suit = {
              imagebutton = { image = "images/coin.png" },
            },
          },
        },
      },
    },
  },
}
