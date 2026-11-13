local log = require("shared.log")

require("packages.onlr").start()

-- Plain LÖVE code keeps working beside the nodes (DESIGN 8.1). The engine calls these too:
-- love.update before the components' update, love.draw after the nodes, and LÖVE's handler of an event before the components'.
function love.update()
  log.add("love.update")
end

function love.draw()
  log.add("love.draw")
end

function love.keypressed(key)
  log.add("love.keypressed " .. key)
end

-- An event of the game's own goes through love.handlers, as a library's does.
function love.handlers.ping(value)
  log.add("love.handlers.ping " .. value)
end

-- The sample's test: test.sh runs the sample with --test, and test.lua checks the game and quits.
function love.load(args)
  log.add("love.load")
  if args[1] == "--test" then
    require("test")
  end
end
