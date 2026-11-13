-- A scene, as the editor writes it: one field on each line, in a fixed order.
-- The user arranges it in the editor and does not edit it by hand.
-- The comments are this prototype's: the editor writes none.
-- A value that equals its default is left out: an object without x is at 0.
---@type onlr.Scene
return {
  format = 1,
  -- The scene's own components: what the whole scene has one of.
  -- No object is made to hold them. To a component, self.object is the scene's root.
  components = {
    {
      type = "bump.world",
      cellSize = 32,
    },
  },
  objects = {
    {
      id = "c8m1",
      name = "Camera",
      x = 640,
      y = 360,
      components = {
        {
          type = "onlr.camera",
        },
      },
    },
    {
      id = "k3f9",
      name = "Player",
      x = 100,
      y = 500,
      components = {
        -- One of the engine's own components.
        {
          type = "onlr.sprite",
          image = "images/player.png",
        },
        -- A pack's component: lib/bump/body.lua.
        {
          type = "bump.body",
          width = 32,
          height = 48,
        },
        -- The user's script: components/player.lua. Only the values that differ from its defaults.
        {
          type = "components.player",
          speed = 250,
          jump = {
            height = 120,
          },
        },
      },
      children = {
        -- A child's place is in its parent: the shadow is 44 pixels under the player, wherever that is.
        -- Its z is added to its parent's. It is lower, so the shadow draws behind the player.
        {
          id = "p7c2",
          name = "Shadow",
          y = 44,
          z = -1,
          components = {
            {
              type = "onlr.sprite",
              image = "images/shadow.png",
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
        {
          type = "onlr.shape",
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
        {
          type = "bump.body",
          width = 1280,
          height = 120,
        },
      },
    },
    -- An instance of a prefab: the prefab's object, with this entry laid over it.
    -- What the entry writes replaces the prefab's, and what it leaves out is the prefab's.
    -- This one writes its place only, so its name and its components are the prefab's.
    {
      id = "n4q8",
      prefab = "prefabs/coin.prefab.lua",
      x = 400,
      y = 540,
    },
    {
      id = "t1r6",
      prefab = "prefabs/coin.prefab.lua",
      name = "Big coin",
      x = 700,
      y = 540,
      scaleX = 2,
      scaleY = 2,
      -- Laid over the components of the prefab's object, by type: this coin is worth 5.
      components = {
        {
          type = "components.coin",
          worth = 5,
        },
      },
      -- Laid over the objects inside the prefab, by their ids in the prefab's file:
      -- this coin has no glint. Another object of the scene names that glint as t1r6/g1nt.
      overrides = {
        g1nt = {
          active = false,
        },
      },
    },
  },
}
