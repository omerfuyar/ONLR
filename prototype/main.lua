-- The file that LÖVE runs first. The editor writes it once; it is the user's afterwards.
-- start() sets love.run, LÖVE's loop, to the engine's: LÖVE's loop, with the scene added.
require("onlr").start()

-- Plain LÖVE code keeps working beside the scene. The engine calls these too:
-- love.update before the components' update, love.draw after the scene, over it.
function love.draw()
  love.graphics.print("Coins: " .. require("modules.score").coins, 10, 10)
end
