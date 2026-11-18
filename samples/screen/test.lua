-- Checks the push package (DESIGN 11.10): the game draws at its own size and is scaled to the window, places turn
-- between the window and the game, the bars of a window of another shape, and one screen for a game.
local check = require("check")
local onlr = require("onlr")

-- The window's pixels, as LÖVE shows them at the end of the frame.
local function capture()
  local shot
  love.graphics.captureScreenshot(function(data)
    shot = data
  end)
  check.frames(2)
  return assert(shot, "no screenshot")
end

local function color(data, x, y)
  local r, g, b = data:getPixel(x, y)
  return ("%d %d %d"):format(r + 0.5, g + 0.5, b + 0.5)
end

check.run(function()
  local top = assert(onlr.tree.top)
  local screen = top.components.push.screen
  check.equal(love.graphics.getWidth(), 640, "the manifest's window stays as it is")

  -- The game's 10 pixels are the window's 20: the red square fills the window's top left 20 by 20.
  local shot = capture()
  check.equal(color(shot, 2, 2), "1 0 0", "the red square at the window's corner")
  check.equal(color(shot, 18, 18), "1 0 0", "twice its size")
  check.equal(color(shot, 22, 22), "0 0 0", "and no larger")
  check.equal(color(shot, 637, 357), "0 0 1", "the blue square at the window's far corner")
  check.equal(color(shot, 622, 342), "0 0 1", "twice its size")

  -- Without a canvas, the default, the drawing is scaled: a text under the screen draws with a font twice as large.
  local text = onlr.tree.root:addComponent("onlr.text")
  local got
  screen:drawTree(function()
    got = onlr.font.sharp(text.font)
  end)
  check.equal(got:getHeight(), text.font:getHeight() * 2, "a text under the screen is sharp")
  onlr.tree.root:removeComponent("onlr.text")
  -- With canvas, the game draws into push's canvas and the canvas is scaled: the squares are the same. canvas is read
  -- when the screen starts, and a screen that starts again draws from the next frame on (DESIGN 6.4).
  screen.canvas = true
  screen:setEnabled(false)
  screen:setEnabled(true)
  check.frames(1)
  shot = capture()
  check.equal({ color(shot, 2, 2), color(shot, 18, 18), color(shot, 22, 22), color(shot, 622, 342) }, { "1 0 0", "1 0 0", "0 0 0", "0 0 1" }, "with a canvas")
  screen.canvas = false
  screen:setEnabled(false)
  screen:setEnabled(true)
  check.frames(1)

  -- Places between the window and the game.
  local gx, gy = screen:toGame(320, 180)
  check.equal(gx * 1000 + gy, 160090, "the window's middle is the game's")
  local rx, ry = screen:toReal(160, 90)
  check.equal(rx * 1000 + ry, 320180, "and back")

  -- A wider window: the game is 2 times its size still, with bars of 80 at the left and the right.
  screen:resize(800, 360)
  gx, gy = screen:toGame(80, 0)
  check.equal(gx + gy, 0, "the game's corner is past the bar")
  check.equal(screen:toGame(40, 0), nil, "a place on a bar is in no place of the game")
  screen:resize(640, 360)

  -- A second screen is an error that names the first one's node.
  local other = onlr.tree.root
  check.fails(function()
    other:addComponent("push.screen")
  end, "Top has it", "a game has one screen")
end)
