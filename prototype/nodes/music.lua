-- A kept node: the manifest names this file in keptNodes, so the game loads it once,
-- before the first root, and keeps it beside every root. Its music plays on when a level ends.
-- It is a node file as any other, and could be held in another as an instance.
---@type onlr.NodeFile
return {
  format = 1,
  id = "m5ckq2",
  name = "Music",
  components = {
    music = {
      track = "sounds/theme.ogg",
    },
  },
}
