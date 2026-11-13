-- The file that LÖVE runs first. The editor writes it once; it is the user's afterwards.
-- It loads the engine as lib.onlr, which LÖVE finds in the project's folder as it is.
-- start() sets love.run, LÖVE's loop, to the engine's: LÖVE's loop, with the scene added.
require("lib.onlr").start()

-- Plain LÖVE code keeps working beside the scene. The engine calls these too:
-- love.update before the components' update, love.draw after the scene, over it.
function love.draw()
  love.graphics.print("Coins: " .. require("shared.score").coins, 10, 10)
end
