-- baton: controls named by the game, which keys and a gamepad move.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m11",
  name = "Input",
  components = {
    room = {
      about = "baton.input names controls: move is the arrows, WASD or a stick; jump is Space or a gamepad's A.",
      title = "Input actions (baton)",
    },
  },
  children = {
    {
      id = "p1ay11",
      name = "Player",
      posX = 320,
      posY = 200,
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
        onlr = {
          sprite = { image = "images/player.png", origin = { x = 16, y = 24 } },
        },
        walker = {},
      },
    },
  },
}
