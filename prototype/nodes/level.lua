-- A node file, as the editor writes it: one field on each line, in a fixed order.
-- The user arranges it in the editor and does not edit it by hand.
-- The comments are this prototype's: the editor writes none.
-- A value that equals its default is left out: a node without x is at 0.
---@type onlr.NodeFile
return {
  format = 1,
  -- The file returns one node. Every other node is under it.
  -- The manifest names this file, so the game loads this node as its scene: it is the scene's root.
  id = "l3v1",
  name = "Level",
  -- What the whole scene has one of is a component of the root, such as the world
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
      x = 640,
      y = 360,
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
      x = 100,
      y = 500,
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
        -- A child is for what has a place of its own: the shadow is 44 pixels under the player.
        -- Its z is added to its parent's. It is lower, so the shadow draws behind the player.
        {
          id = "p7c2",
          name = "Shadow",
          y = 44,
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
      y = 600,
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
    -- An instance: another node file, held here as a node. It is that file's node,
    -- with this entry laid over it. What the entry writes replaces the node's,
    -- and what it leaves out is the node's.
    -- This one writes its place only, so its name and its components are the coin's.
    {
      id = "n4q8",
      instance = "nodes/coin.lua",
      x = 400,
      y = 540,
    },
    {
      id = "t1r6",
      instance = "nodes/coin.lua",
      name = "Big coin",
      x = 700,
      y = 540,
      scaleX = 2,
      scaleY = 2,
      -- Laid over the coin's components, name by name: this coin is worth 5.
      components = {
        coin = {
          worth = 5,
        },
      },
      -- Laid over the nodes under the coin, by their ids in the coin's file:
      -- this coin has no glint. Another node of the level names that glint as t1r6/g1nt.
      overrides = {
        g1nt = {
          active = false,
        },
      },
    },
  },
}
