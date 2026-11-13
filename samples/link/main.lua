-- The test of the player and the link (DESIGN 12, 16): this program listens as the editor does, starts players
-- on other samples, and speaks the link with them over LuaSocket.
love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";packages/?.lua")

function love.load(args)
  if args[1] == "--test" then
    require("test")
  else
    print("This sample only tests: run it with --test, as .github/scripts/test.sh does.")
    love.event.quit(0)
  end
end
