-- LÖVE reads this before any other file of the game. The editor writes it once.

-- Adds lib/ to the places where require looks. From here on, require("onlr") finds
-- lib/onlr/init.lua, and require("bump") finds lib/bump/init.lua.
love.filesystem.setRequirePath("?.lua;?/init.lua;lib/?.lua;lib/?/init.lua")

function love.conf(t)
  -- Sets what project.lua holds: the window's size and title, and the folder of saved files.
  require("onlr").conf(t)

  -- More of LÖVE's settings go here, as in any game.
  t.window.resizable = true
end
