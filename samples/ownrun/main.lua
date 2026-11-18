local onlr = require("packages.onlr")
onlr.start()

-- A game's own love.run, set after onlr.start: it calls the steps of onlr.loop from its own loop (DESIGN 8.1).
-- This one runs at a fixed pace: every frame is a sixtieth of a second, whatever the clock says.
function love.run()
  ---@diagnostic disable-next-line: undefined-field
  love.load(love.arg.parseGameArguments(arg), arg)
  onlr.loop.load()
  local dt = 1 / 60

  return function()
    love.event.pump()
    for name, a, b, c, d, e, f in love.event.poll() do
      if name == "quit" and not onlr.loop.event("quit", a) then
        return a or 0
      end
      ---@diagnostic disable-next-line: undefined-field
      love.handlers[name](a, b, c, d, e, f)
      onlr.loop.event(name, a, b, c, d, e, f)
    end

    if love.update then
      love.update(dt)
    end
    onlr.loop.update(dt)

    love.graphics.origin()
    love.graphics.clear(love.graphics.getBackgroundColor())
    onlr.loop.draw()
    love.graphics.present()

    onlr.loop.endFrame()
  end
end

-- The sample's test: test.sh runs the sample with --test, and test.lua checks the game and quits.
function love.load(args)
  if args[1] == "--test" then
    require("test")
  end
end
