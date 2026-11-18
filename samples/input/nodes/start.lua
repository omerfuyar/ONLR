-- The baton package's sample: a player that walks with the arrows, WASD or a gamepad's stick, and jumps with space or
-- the gamepad's A.
---@type onlr.NodeFile
return {
  format = 1,
  id = "inp000",
  name = "Start",
  children = {
    {
      id = "p1ayer",
      name = "Player",
      posX = 80,
      posY = 60,
      components = {
        baton = {
          input = {
            controls = {
              { name = "left", sources = "key:left, key:a, axis:leftx-, button:dpleft" },
              { name = "right", sources = "key:right, key:d, axis:leftx+, button:dpright" },
              { name = "up", sources = "key:up, key:w, axis:lefty-, button:dpup" },
              { name = "down", sources = "key:down, key:s, axis:lefty+, button:dpdown" },
              { name = "jump", sources = "key:space, button:a" },
            },
            pairs = {
              { name = "move" },
            },
          },
        },
        walker = {},
      },
    },
  },
}
