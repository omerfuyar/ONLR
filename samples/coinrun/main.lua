-- The file that LÖVE runs first. The editor writes it once; it is the user's afterwards.
-- It loads the engine as packages.onlr, which LÖVE finds in the project's folder as it is.
-- start() sets love.run, LÖVE's loop, to the engine's: LÖVE's loop, with the tree of nodes added.
-- Code outside functions runs in the editor too, when it draws the node view.
-- The game's own start goes in love.load, which runs only in the game.
require("packages.onlr").start()

-- Plain LÖVE code keeps working beside the nodes. The engine calls these too:
-- love.update before the components' update, love.draw after the nodes, over them.
function love.draw()
  love.graphics.print("FPS: " .. love.timer.getFPS(), 1200, 10)
end

-- The sample's test: test.sh runs the sample with --test, and test.lua checks the game and quits.
function love.load(args)
  if args[1] == "--test" then
    require("test")
  end
end
