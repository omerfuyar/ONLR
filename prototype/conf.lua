-- LÖVE reads this before any other file of the game. The editor writes it once, and no one changes it:
-- LÖVE's settings are in manifest.lua, which the project settings panel changes.

function love.conf(t)
  -- Loads the engine, as packages.onlr. When it loads, the engine adds packages/ to the places where
  -- require looks and answers to the name onlr too. So every other file writes require("onlr"),
  -- and require("bump") finds packages/bump/init.lua.
  -- conf() gives LÖVE what manifest.lua holds: the window, the game's name, the folder of saved files,
  -- and LÖVE's other settings under their own names.
  require("packages.onlr").conf(t)
end
