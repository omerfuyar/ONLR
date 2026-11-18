-- SUIT: a button, a checkbox, a slider and a text field, which tell their nodes, and a script that shows it.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m13",
  name = "Interface",
  components = {
    room = {
      about = "suit's widgets on nodes: each tells its node of a click or a change, and relay passes it to the shown node.",
      title = "An interface inside the game (SUIT)",
    },
  },
  children = {
    {
      id = "sh0wn3",
      name = "Shown",
      posX = 460,
      posY = 200,
      components = {
        onlr = {
          shape = { color = { 0.3, 0.6, 0.95, 1 }, kind = "circle", radius = 30 },
          text = { align = "center", text = "Type below", width = 200 },
        },
        widgets = { shape = "sh0wn3", text = "sh0wn3" },
      },
    },
    {
      id = "s1ze13",
      name = "Size",
      posX = 60,
      posY = 80,
      components = {
        relay = { call = "grow", to = "sh0wn3" },
        suit = {
          slider = { max = 80, min = 5, value = 30, width = 200, height = 20 },
        },
      },
    },
    {
      id = "v1s113",
      name = "Visible",
      posX = 60,
      posY = 120,
      components = {
        relay = { call = "show", to = "sh0wn3" },
        suit = {
          checkbox = { checked = true, height = 24, text = "Show the circle", width = 200 },
        },
      },
    },
    {
      id = "f1eld3",
      name = "Field",
      posX = 60,
      posY = 160,
      components = {
        relay = { call = "say", to = "sh0wn3" },
        suit = {
          input = { height = 26, text = "Hello", width = 200 },
        },
      },
    },
    {
      id = "b4tt13",
      name = "Button",
      posX = 60,
      posY = 200,
      components = {
        relay = { call = "say", to = "sh0wn3" },
        suit = {
          button = { height = 28, text = "Say nothing", width = 200 },
        },
      },
    },
  },
}
