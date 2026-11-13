-- The file that LÖVE runs first. The editor writes it once; it is the user's afterwards.
-- It loads the engine as packages.onlr, which LÖVE finds in the project's folder as it is.
-- start() sets love.run, LÖVE's loop, to the engine's: LÖVE's loop, with the tree of nodes added.
-- Code outside functions runs in the editor too, when it draws the node view.
-- The game's own start goes in love.load, which runs only in the game.
require("packages.onlr").start()

-- Plain LÖVE code keeps working beside the nodes. The engine calls these too:
-- love.update before the components' update, love.draw after the nodes, over them.
function love.draw()
  love.graphics.print("Coins: " .. require("shared.score").coins, 10, 10)
end
