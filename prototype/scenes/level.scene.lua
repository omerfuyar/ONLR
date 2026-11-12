-- A scene, as the editor writes it. The user arranges it in the editor and does not edit it by hand.
-- A value that equals its default is left out: an object without x is at 0.
---@type onlr.Scene
return {
  format = 1,
  objects = {
    {
      id = "c8m1",
      name = "Camera",
      x = 640,
      y = 360,
      components = {
        { type = "onlr.camera" },
      },
    },
    {
      -- What a scene has one of is a component of an object, as any other.
      id = "w2x7",
      name = "World",
      components = {
        { type = "bump.world", cellSize = 64 },
      },
    },
    {
      id = "k3f9",
      name = "Player",
      x = 100,
      y = 500,
      components = {
        -- One of the engine's own components.
        { type = "onlr.sprite", image = "images/player.png" },
        -- A pack's component: lib/bump/body.lua.
        { type = "bump.body", width = 32, height = 48 },
        -- The user's script: scripts/player.lua. Only the values that differ from its defaults.
        { type = "scripts.player", speed = 250, jump = { height = 120 } },
      },
      children = {
        -- A child's place is in its parent: the shadow is 44 pixels under the player, wherever that is.
        {
          id = "p7c2",
          name = "Shadow",
          y = 44,
          z = -1,
          components = {
            { type = "onlr.sprite", image = "images/shadow.png" },
          },
        },
      },
    },
    {
      id = "g5d0",
      name = "Ground",
      y = 600,
      components = {
        { type = "onlr.shape", kind = "rectangle", width = 1280, height = 120, color = { 0.2, 0.6, 0.3, 1 } },
        { type = "bump.body", width = 1280, height = 120 },
      },
    },
    {
      -- An instance of a prefab: its own id, name and place, and the values it changes.
      id = "n4q8",
      name = "Coin",
      prefab = "prefabs/coin.prefab.lua",
      x = 400,
      y = 540,
    },
    {
      id = "t1r6",
      name = "Big coin",
      prefab = "prefabs/coin.prefab.lua",
      x = 700,
      y = 540,
      scaleX = 2,
      scaleY = 2,
      -- By the id of the object in the prefab, then the component's place in it, then the property.
      overrides = {
        c0in = { [3] = { worth = 5 } },
      },
    },
  },
}
