-- Checks the gallery: every room loads and runs a second without an error, the bar names it, and each room does what
-- it shows, as far as a test sees it without eyes. The gallery is a demonstration of ONLR (DESIGN 16), so this test
-- keeps it working; each package's own sample tests the package.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

-- A press of the mouse at a place of the game: the window is 960 by 540, and the game 640 by 360, scaled by 1.5.
local function press(x, y)
  love.event.push("mousepressed", x * 1.5, y * 1.5, 1, false, 1)
  check.frames(2)
end

check.run(function()
  local tree = onlr.tree
  local gallery = assert(tree.findComponent("gallery"))
  local title = assert(tree.find("Title")).components.suit.label
  check.frames(2)
  check.ok(#gallery.rooms >= 15, "the gallery finds its rooms: " .. #gallery.rooms)
  check.ok(title.text:find("^1 of %d+   Nodes and drawing"), "the bar names the first room: " .. title.text)

  -- Each room in turn, by the bar's button: it loads, runs, and its root has a room component with a title.
  local seen = {}
  for i = 1, #gallery.rooms do
    if i > 1 then
      assert(tree.find("After")):send("clicked")
      check.frames(2)
    end
    local root = tree.root
    check.ok(root.components.room ~= nil, gallery.rooms[i] .. " has a room component")
    check.ok(title.text:find(root.components.room.title, 1, true), "the bar names " .. gallery.rooms[i])
    seen[root.name] = root
    check.frames(60)

    if root.name == "Instances" then
      local before = #root:getChildren()
      press(320, 300)
      check.equal(#root:getChildren(), before + 1, "a click spawns a coin")
    elseif root.name == "Collision" then
      check.ok(tree.find("Player").posX > 60, "the player stands where it was put")
    elseif root.name == "Physics" then
      local crate = assert(tree.find("Crate"))
      check.ok(crate.posY > 80, "a crate falls")
      check.ok(assert(tree.find("Cart")).posX > 110, "the cart's wheels drive it: " .. tree.find("Cart").posX)
      local before = #root:getChildren()
      press(400, 100)
      check.equal(#root:getChildren(), before + 1, "a click drops another")
    elseif root.name == "Tile map" then
      local ball = assert(tree.find("Ball"))
      check.frames(120)
      local y = ball.posY
      check.frames(30)
      check.ok(y > 60 and y < 330 and math.abs(ball.posY - y) < 1, "the ball rests on the map's ground: " .. y .. ", " .. ball.posY)
      check.ok(tree.find("Goal") ~= nil and tree.find("Cloth") ~= nil, "the map's object Goal is a flag")
    elseif root.name == "Animation" then
      press(200, 200)
      check.frames(2)
      local _, name = tree.find("Ball").components.anim8.animation:get()
      check.ok(name == "jump" or name == nil, "a click plays jump")
    elseif root.name == "Particles" then
      check.ok(tree.find("Fountain").components.particles.emitter:getCount() > 0, "the fountain sprays")
      press(400, 150)
      check.ok(tree.find("Burst") ~= nil, "a click makes a burst")
      check.frames(80)
      check.equal(tree.find("Burst"), nil, "which ends itself")
    elseif root.name == "Tweens" then
      check.ok(tree.find("Linear").posX > 80, "a box slides")
    elseif root.name == "Sound" then
      check.ok(tree.find("Music").components.audio.source:isPlaying(), "the music plays")
      tree.find("Music on"):send("changed", false)
      check.equal(tree.find("Music").components.audio.source:isPlaying(), false, "the checkbox pauses it")
    elseif root.name == "Interface" then
      tree.find("Size"):send("changed", 50)
      check.equal(tree.find("Shown").components.onlr.shape.radius, 50, "the slider sizes the circle")
      tree.find("Field"):send("submitted", "Hi")
      check.equal(tree.find("Shown").components.onlr.text.text, "Hi", "the field's text is shown")
    elseif root.name == "Effects" then
      tree.find("CRT"):send("changed", false)
      check.equal(root.components.moonshine.effect.crt:isEnabled(), false, "a checkbox turns an effect off")
    end
  end

  -- After the last room, the next is the first again; Page Up goes back.
  assert(tree.find("After")):send("clicked")
  check.frames(2)
  check.equal(tree.root.name, "Nodes", "the rooms go round")
  love.event.push("keypressed", "pageup", "pageup", false)
  check.frames(3)
  check.equal(gallery.index, #gallery.rooms, "Page Up goes to the last room")
end)
