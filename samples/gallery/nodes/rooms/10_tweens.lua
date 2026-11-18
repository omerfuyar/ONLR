-- flux and tick: boxes that slide with eases, and change colour by a timer.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m10",
  name = "Tweens",
  components = {
    room = {
      about = "flux.tweens slides each box, with an ease of its own; tick.timers gives it a new colour now and then.",
      title = "Tweens and timers (flux, tick)",
    },
  },
  children = {
    {
      id = "tw01x0",
      name = "Linear",
      posX = 80,
      posY = 80,
      components = {
        bouncer = { ease = "linear" },
        onlr = { shape = { height = 30, width = 30 } },
      },
    },
    {
      id = "tw02x0",
      name = "Quad",
      posX = 80,
      posY = 140,
      components = {
        bouncer = {},
        onlr = { shape = { height = 30, width = 30 } },
      },
    },
    {
      id = "tw03x0",
      name = "Back",
      posX = 80,
      posY = 200,
      components = {
        bouncer = { ease = "backinout" },
        onlr = { shape = { height = 30, width = 30 } },
      },
    },
    {
      id = "tw04x0",
      name = "Elastic",
      posX = 80,
      posY = 260,
      components = {
        bouncer = { ease = "elasticout" },
        onlr = { shape = { height = 30, width = 30 } },
      },
    },
    {
      id = "tw05x0",
      name = "Expo",
      posX = 540,
      posY = 80,
      components = {
        bouncer = { ease = "expoout", to = { x = 0, y = 240 } },
        onlr = { shape = { height = 30, kind = "circle", radius = 15, width = 30 } },
      },
    },
  },
}
