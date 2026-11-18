-- bump: boxes that collide. The player slides along walls, and takes the coins it touches.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m05",
  name = "Collision",
  components = {
    bump = {
      world = {},
    },
    room = {
      about = "bump.world on the room, bump.body on each box. Arrows move; walls stop the player, coins are taken.",
      title = "Collision of boxes (bump)",
    },
  },
  children = {
    {
      id = "p1ay05",
      name = "Player",
      posX = 80,
      posY = 200,
      components = {
        arrows = {},
        bump = {
          body = { height = 48 },
        },
        onlr = {
          sprite = { image = "images/player.png" },
        },
      },
    },
    {
      id = "w4ll51",
      name = "Wall",
      posX = 200,
      posY = 100,
      components = {
        bump = {
          body = { height = 200, width = 24 },
        },
        onlr = {
          shape = { color = { 0.5, 0.5, 0.6, 1 }, height = 200, width = 24 },
        },
      },
    },
    {
      id = "w4ll52",
      name = "Floor",
      posX = 200,
      posY = 300,
      components = {
        bump = {
          body = { height = 24, width = 360 },
        },
        onlr = {
          shape = { color = { 0.5, 0.5, 0.6, 1 }, height = 24, width = 360 },
        },
      },
    },
    {
      id = "c01n51",
      name = "Coin",
      posX = 320,
      posY = 200,
      components = {
        bump = {
          body = { height = 16, solid = false, width = 16 },
        },
        onlr = {
          sprite = { image = "images/coin.png" },
        },
        pickup = {},
      },
    },
    {
      id = "c01n52",
      name = "Coin 2",
      posX = 420,
      posY = 140,
      components = {
        bump = {
          body = { height = 16, solid = false, width = 16 },
        },
        onlr = {
          sprite = { image = "images/coin.png" },
        },
        pickup = {},
      },
    },
  },
}
