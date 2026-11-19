-- The camera helpers' sample: a world of 400 by 200 under a camera that follows the player, keeps inside the world,
-- and shakes. The window is 160 by 120.
---@type onlr.NodeFile
return {
  format = 1,
  id = "cam000",
  name = "Start",
  children = {
    {
      id = "w0rld0",
      name = "World",
      components = {
        onlr = {
          camera = {
            follow = {
              target = "p1ayer",
            },
            limits = {
              height = 200,
              width = 400,
            },
            shake = {},
            view = {},
          },
        },
      },
      children = {
        {
          id = "p1ayer",
          name = "Player",
          posX = 50,
          posY = 50,
          components = {
            onlr = {
              paint = {},
              shape = {
                height = 8,
                width = 8,
              },
            },
          },
        },
      },
    },
  },
}
