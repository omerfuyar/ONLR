-- The push package's sample: a red square at the game's top left corner and a blue one at its bottom right, in the
-- game's own pixels, 320 by 180, which the screen on the top node scales to the window of 640 by 360.
---@type onlr.NodeFile
return {
  format = 1,
  id = "scr000",
  name = "Start",
  children = {
    {
      id = "red000",
      name = "Red",
      components = {
        onlr = {
          shape = {
            color = { 1, 0, 0, 1 },
            height = 10,
            width = 10,
          },
        },
      },
    },
    {
      id = "b1ue00",
      name = "Blue",
      posX = 310,
      posY = 170,
      components = {
        onlr = {
          shape = {
            color = { 0, 0, 1, 1 },
            height = 10,
            width = 10,
          },
        },
      },
    },
  },
}
