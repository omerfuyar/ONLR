-- LÖVE reads this before it opens the window. The editor writes it once.
function love.conf(t)
  -- Sets what project.lua holds: the window's size and title, and the folder of saved files.
  -- It also adds lib/ to the places where require looks.
  require("onlr").conf(t)

  -- More of LÖVE's settings go here, as in any game.
  t.window.resizable = true
end
