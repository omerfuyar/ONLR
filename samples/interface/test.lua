-- Checks the suit package (DESIGN 11.13): a button tells its node when it is clicked; a checkbox, a slider and a text
-- field change their properties and tell their nodes; a widget draws at its node; a script's change of a property shows; a widget under a camera
-- takes the pointer in its own space, as one under a push.screen does; and the node view draws a widget still.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

-- The mouse, as the test moves it: LÖVE's own reads the real pointer, which the offscreen window has not.
local mouse = { x = -100, y = -100, down = false }
love.mouse.getPosition = function()
  return mouse.x, mouse.y
end
love.mouse.getX = function()
  return mouse.x
end
love.mouse.getY = function()
  return mouse.y
end
love.mouse.isDown = function()
  return mouse.down
end

-- A pixel of the window, as LÖVE shows it at the end of the frame, from 0 to 255.
local function rgb(x, y)
  local shot
  love.graphics.captureScreenshot(function(data)
    shot = data
  end)
  check.frames(2)
  local r, g, b = assert(shot, "no screenshot"):getPixel(x, y)
  return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

-- Moves the pointer to a place of the window, presses its button and lets it go.
local function click(x, y)
  mouse.x, mouse.y = x, y
  check.frames(2)
  mouse.down = true
  check.frames(2)
  mouse.down = false
  check.frames(2)
end

check.run(function()
  local tree = onlr.tree
  check.frames(2)

  -- A widget draws at its node, in the theme's colours: the button's box is SUIT's grey, and blue under the pointer.
  check.equal({ rgb(12, 28) }, { 63, 63, 63 }, "the button draws its box at its node")
  check.equal({ rgb(5, 5) }, { 0, 0, 0 }, "and nothing beside it")

  -- A button: hovered under the pointer, and clicked.
  local play = assert(tree.find("Play"))
  local button = play.components.suit.button
  mouse.x, mouse.y = 30, 20
  check.frames(2)
  check.equal(button:isHovered(), true, "the pointer is over the button")
  check.equal(button:getState(), "hovered", "its state")
  check.equal({ rgb(12, 28) }, { 48, 153, 186 }, "it draws as hovered")
  click(30, 20)
  check.equal(play.components.probe.told, { "clicked" }, "a click tells its node")
  click(100, 20)
  check.equal(play.components.probe.told, { "clicked" }, "a click beside it does not")

  -- A checkbox: a click unchecks it.
  local sound = assert(tree.find("Sound"))
  click(20, 50)
  check.equal(sound.components.suit.checkbox.checked, false, "a click unchecks the checkbox")
  check.equal(sound.components.probe.told, { false }, "and tells its node")
  sound.components.suit.checkbox.checked = true
  click(20, 50)
  check.equal(sound.components.probe.told, { false, false }, "a script's check counts")

  -- A slider: held at three quarters of its width.
  local volume = assert(tree.find("Volume"))
  local slider = volume.components.suit.slider
  mouse.x, mouse.y = 85, 78
  check.frames(2)
  mouse.down = true
  check.frames(3)
  mouse.down = false
  check.frames(2)
  check.ok(math.abs(slider.value - 0.75) < 0.01, "the slider follows the pointer: " .. slider.value)
  check.ok(#volume.components.probe.told > 0, "and tells its node")

  -- A text field: a click gives it the keyboard, typing changes its text, and Enter submits it.
  local name = assert(tree.find("Name"))
  local input = name.components.suit.input
  click(50, 105)
  check.equal(input:hasFocus(), true, "a click gives the field the keyboard")
  love.event.push("textinput", "c")
  check.frames(2)
  check.equal(input.text, "abc", "typing adds to its text")
  love.event.push("keypressed", "backspace", "backspace", false)
  check.frames(2)
  check.equal(input.text, "ab", "backspace takes away")
  love.event.push("keypressed", "return", "return", false)
  check.frames(2)
  check.equal(name.components.probe.told, { "abc", "ab", "submitted ab" }, "its node is told each change, and Enter")
  input.text = "zed"
  check.frames(2)
  check.equal(input.text, "zed", "a script sets its text")
  click(150, 10)
  check.equal(input:hasFocus(), false, "a click elsewhere takes the keyboard away")

  -- Under a camera that shows it twice as large, from the screen's middle: the coin at 30, 10 is at 160, 95.
  local coin = assert(tree.find("Coin"))
  click(176, 111)
  check.equal(coin.components.probe.told, { "clicked" }, "a widget under a camera takes the pointer in its own space")
  click(105, 80)
  check.equal(coin.components.probe.told, { "clicked" }, "and not at its place of the window")

  -- Under a push.screen of half the window's size, a widget at 60, 50 of the game is at 120, 100 of the window.
  local game = tree.newNode("Game")
  game:addComponent("push.screen", { width = 100, height = 75 })
  local small = tree.newNode("Small", game)
  small.posX, small.posY = 60, 50
  small:addComponent("probe")
  small:addComponent("suit.button", { text = "Go", width = 20, height = 10 })
  check.frames(2)
  click(140, 110)
  check.equal(small.components.probe.told, { "clicked" }, "a widget under a push.screen takes the game's pointer")
  game:destroy()
  check.frames(1)

  -- The node view draws a widget with no pointer over it, and knows its rectangle.
  love.graphics.push("all")
  button:drawEditor(false)
  love.graphics.pop()
  check.equal({ button:bounds() }, { 0, 0, 60, 20 }, "the button's rectangle")
  check.equal({ coin.components.suit.imagebutton:bounds() }, { 0, 0, 16, 16 }, "the image button's is its image's")
end)
