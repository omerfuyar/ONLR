-- The gallery's top node: its screen draws every room at 640 by 360, scaled to the window, and its bar, over the
-- room, goes from room to room.
---@type onlr.NodeFile
return {
  format = 1,
  id = "t0p000",
  name = "Top",
  components = {
    gallery = {
      about = "b4r0ab",
      title = "b4r0t1",
    },
    push = {
      screen = {
        height = 360,
        width = 640,
      },
    },
  },
  children = {
    {
      id = "b4r000",
      name = "Bar",
      z = 10,
      components = {
        onlr = {
          paint = {
            color = { 0.1, 0.1, 0.13, 0.9 },
          },
          shape = {
            height = 54,
            width = 640,
          },
        },
      },
      children = {
        {
          id = "b4r0pv",
          name = "Before",
          posX = 6,
          posY = 14,
          components = {
            step = {
              by = -1,
            },
            suit = {
              button = { height = 24, text = "<", width = 28 },
            },
          },
        },
        {
          id = "b4r0nx",
          name = "After",
          posX = 38,
          posY = 14,
          components = {
            step = {},
            suit = {
              button = { height = 24, text = ">", width = 28 },
            },
          },
        },
        {
          id = "b4r0t1",
          name = "Title",
          posX = 74,
          posY = 4,
          components = {
            suit = {
              label = { height = 18, width = 560 },
            },
          },
        },
        {
          id = "b4r0ab",
          name = "About",
          posX = 74,
          posY = 22,
          components = {
            suit = {
              label = { height = 30, valign = "top", width = 560 },
            },
          },
        },
      },
    },
  },
}
