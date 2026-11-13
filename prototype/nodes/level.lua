-- A node file, as the editor writes it: one field on each line, in a fixed order.
-- A node's fields are in the order of DESIGN.md's table of them; every other table's, by their names.
-- The user arranges it in the editor and does not edit it by hand.
-- The comments are this prototype's: the editor writes none.
-- A value that equals its default is left out: a node without posX is at 0.
---@type onlr.NodeFile
return {
  format = 1,
  -- The file returns one node. Every other node is under it.
  -- The manifest names this file as the start node, so the game loads this node as its root.
  id = "l3v1q0",
  name = "Level",
  -- What the root has one of is a component of the root, such as the world
  -- that its bodies collide in: no node is made only to hold it.
  components = {
    bump = {
      world = {
        cellSize = 32,
      },
    },
  },
  children = {
    -- The world is under a node with a camera: the camera draws this node and all under it
    -- as a group, moved so that the window's centre shows its point.
    -- A script moves the camera by its properties, not by the node's place.
    {
      id = "w0r1dn",
      name = "World",
      components = {
        onlr = {
          camera = {
            posX = 640,
            posY = 360,
          },
        },
      },
      children = {
        -- One node is the whole player: its body, its script and its picture are components.
        -- A script reads them as self.node.components.bump.body and self.node.components.onlr.sprite.
        {
          id = "k3f9pl",
          name = "Player",
          posX = 100,
          posY = 500,
          components = {
            -- A package's component: packages/bump/components/body.lua.
            bump = {
              body = {
                height = 48,
                width = 32,
              },
            },
            -- One of the engine's own components: packages/onlr/components/sprite.lua.
            onlr = {
              sprite = {
                image = "images/player.png",
              },
            },
            -- The user's script: components/player.lua. Only the values that differ from its defaults.
            player = {
              jump = {
                height = 120,
              },
              speed = 250,
            },
          },
          children = {
            -- A child has a place of its own: the shadow is 44 pixels under the player.
            -- Its z is added to its parent's. It is lower, so the shadow draws behind the player.
            {
              id = "p7c2sh",
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
          id = "g5d0gr",
          name = "Ground",
          posY = 600,
          components = {
            bump = {
              body = {
                height = 120,
                width = 1280,
              },
            },
            onlr = {
              shape = {
                color = {
                  0.2,
                  0.6,
                  0.3,
                  1,
                },
                height = 120,
                kind = "rectangle",
                width = 1280,
              },
            },
          },
        },
        -- An instance: a node made from another node file, its base.
        -- It has an id of its own and instance, which holds all that it is: the base and the changes.
        -- A change is written under the id that the changed node has in the base's file,
        -- and is laid over that node: what it writes replaces the base's, and the rest is the base's.
        -- This one changes the coin's place only. c0in7x is the coin's first node.
        {
          id = "n4q8wm",
          instance = {
            base = "nodes/coin.lua",
            changes = {
              c0in7x = {
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
              -- The coin itself: a new name, a place, twice the size, and worth 5.
              c0in7x = {
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
                    id = "f7ag2e",
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
              -- Another node of the level names that glint as t1r6bz/g1nt4k, and this coin as t1r6bz.
              g1nt4k = {
                active = false,
              },
            },
          },
        },
      },
    },
    -- Beside the world, so no camera holds it: it draws at the window's pixels and stays on the screen.
    -- It comes after the world in the tree, so it draws over it.
    -- The engine's text shows it, and the script counter sets the text.
    {
      id = "s9c0re",
      name = "Score",
      posX = 16,
      posY = 16,
      components = {
        counter = {},
        onlr = {
          text = {
            text = "Coins: 0",
          },
        },
      },
    },
  },
}
