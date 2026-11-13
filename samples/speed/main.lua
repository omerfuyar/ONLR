require("packages.onlr").start()

-- The sample's test: test.sh runs the sample with --test, and test.lua checks the game and quits.
function love.load(args)
  if args[1] == "--test" then
    require("test")
  end
end
