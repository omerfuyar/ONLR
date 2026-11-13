-- LÖVE reads this before any other file of the game. The editor writes it once.

function love.conf(t)
  -- Loads the engine, as lib.onlr. When it loads, the engine adds lib/ to the places where
  -- require looks and answers to the name onlr too. So every other file writes require("onlr"),
  -- and require("bump") finds lib/bump/init.lua.
  -- conf() sets what manifest.lua holds: the window's size and title, and the folder of saved files.
  require("lib.onlr").conf(t)

  -- More of LÖVE's settings go here, as in any game.
  t.window.resizable = true
end
