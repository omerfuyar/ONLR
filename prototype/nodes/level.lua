-- A node file, as the editor writes it: one field on each line, in a fixed order.
-- The user arranges it in the editor and does not edit it by hand.
-- The comments are this prototype's: the editor writes none.
-- A value that equals its default is left out: a node without x is at 0.
---@type onlr.NodeFile
return {
  format = 1,
  -- The file returns one node. Every other node is under it.
  -- The manifest names this file as the start node, so the game loads this node as its root.
  id = "l3v1",
  name = "Level",
  -- What the whole tree has one of is a component of the root, such as the world
  -- that its bodies collide in: no node is made only to hold it.
  components = {
    bump = {
      world = {
        cellSize = 32,
      },
    },
  },
  children = {
    {
      id = "c8m1",
      name = "Camera",
      posX = 640,
      posY = 360,
      components = {
        onlr = {
          camera = {},
        },
      },
    },
    -- One node is the whole player: its body, its script and its picture are components.
    -- A script reads them as self.node.components.bump.body and self.node.components.onlr.sprite.
    {
      id = "k3f9",
      name = "Player",
      posX = 100,
      posY = 500,
      components = {
        -- A pack's component: lib/bump/body.lua.
        bump = {
          body = {
            width = 32,
            height = 48,
          },
        },
        -- One of the engine's own components: lib/onlr/sprite.lua.
        onlr = {
          sprite = {
            image = "images/player.png",
          },
        },
        -- The user's script: components/player.lua. Only the values that differ from its defaults.
        player = {
          speed = 250,
          jump = {
            height = 120,
          },
        },
      },
      children = {
        -- A child has a place of its own: the shadow is 44 pixels under the player.
        -- Its z is added to its parent's. It is lower, so the shadow draws behind the player.
        {
          id = "p7c2",
          name = "Shadow",
          posY = 44,
          z = -1,
          components = {
            onlr = {
              sprite = {
                image = "images/shadow.png",
              },
            },
          },
        },
      },
    },
    {
      id = "g5d0",
      name = "Ground",
      posY = 600,
      components = {
        bump = {
          body = {
            width = 1280,
            height = 120,
          },
        },
        onlr = {
          shape = {
            kind = "rectangle",
            width = 1280,
            height = 120,
            color = {
              0.2,
              0.6,
              0.3,
              1,
            },
          },
        },
      },
    },
    -- An instance: a node made from another node file, its base.
    -- It has an id of its own and instance, which holds all that it is: the base and the changes.
    -- A change is written under the id that the changed node has in the base's file,
    -- and is laid over that node: what it writes replaces the base's, and the rest is the base's.
    -- This one changes the coin's place only. c0in is the coin's first node.
    {
      id = "n4q8",
      instance = {
        base = "nodes/coin.lua",
        changes = {
          c0in = {
            posX = 400,
            posY = 540,
          },
        },
      },
    },
    {
      id = "t1r6",
      instance = {
        base = "nodes/coin.lua",
        changes = {
          -- The coin itself: a new name, a place, twice the size, and worth 5.
          c0in = {
            name = "Big coin",
            posX = 700,
            posY = 540,
            sclX = 2,
            sclY = 2,
            components = {
              coin = {
                worth = 5,
              },
              -- A component that the coin's file does not have: only this coin spins.
              spin = {
                speed = 2,
              },
            },
            -- Nodes of this instance's own, added after the coin's children: only this coin has a flag.
            -- Its id is of this file, the level's.
            children = {
              {
                id = "f7ag",
                name = "Flag",
                posY = -24,
                components = {
                  onlr = {
                    sprite = {
                      image = "images/flag.png",
                    },
                  },
                },
              },
            },
          },
          -- The coin's glint, a node under the coin: this coin turns it off.
          -- Another node of the level names that glint as t1r6/g1nt, and this coin as t1r6.
          g1nt = {
            active = false,
          },
        },
      },
    },
  },
}
