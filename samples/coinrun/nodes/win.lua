-- The node file that the last coin loads as the root: the level ends, and the top node's music plays on.
---@type onlr.NodeFile
return {
  format = 1,
  id = "w1nn3r",
  name = "Win",
  posX = 560,
  posY = 340,
  components = {
    counter = {
      prefix = "You win! Coins: ",
    },
    onlr = {
      text = {
        font = {
          size = 24,
        },
      },
    },
  },
}
