---@type onlr.NodeFile
return {
  format = 1,
  id = "l3v1q0",
  name = "Level",
  children = {
    {
      id = "pl4y3r",
      name = "Player",
    },
    {
      id = "n4q8wm",
      instance = {
        base = "nodes/coin.lua",
        changes = {
          ["c0in7x"] = {
            posX = 400,
            posY = 540,
          },
        },
      },
    },
    {
      id = "t1r6bz",
      instance = {
        base = "nodes/coin.lua",
        changes = {
          ["c0in7x"] = {
            name = "Changed coin",
            posX = 700,
            z = 3,
            components = {
              coin = {
                box = {
                  height = 32,
                },
                owner = "pl4y3r",
                worth = 5,
              },
              spin = {
                speed = 2,
              },
            },
            children = {
              {
                id = "f7ag2e",
                name = "Flag",
                posY = -24,
              },
            },
          },
          ["g1nt4k"] = {
            active = false,
          },
        },
      },
    },
    {
      id = "v4r14n",
      instance = {
        base = "nodes/bigcoin.lua",
        changes = {
          ["b1gc0n"] = {
            posX = 50,
          },
          ["b1gc0n/g1nt4k"] = {
            name = "Big glint",
          },
        },
      },
    },
    {
      id = "ch3571",
      instance = {
        base = "nodes/chest.lua",
        changes = {
          ["ch3st9"] = {
            posY = 7,
          },
          ["ch3st9/g1nt4k"] = {
            posX = 2,
            posY = 3,
          },
        },
      },
    },
    {
      id = "w4tch3",
      name = "Watcher",
      components = {
        watcher = {
          coin = "t1r6bz",
          glint = "t1r6bz/g1nt4k",
          inner = "ch3571/ch3st9",
        },
      },
    },
  },
}
