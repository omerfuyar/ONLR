-- The top node: the manifest names this file in topNode, so the game loads it once,
-- before the first root, and keeps it for the whole game. Each root runs as its last child,
-- so what is here outlives every level, and a group on this node would hold the whole game,
-- such as a library that scales the game to the window.
-- It is a node file as any other, and the editor opens it as any other.
---@type onlr.NodeFile
return {
  format = 1,
  id = "g4m3tp",
  name = "Game",
  children = {
    -- Its music plays on when a level ends.
    {
      id = "m5ckq2",
      name = "Music",
      components = {
        music = {
          track = "sounds/theme.ogg",
        },
      },
    },
  },
}
