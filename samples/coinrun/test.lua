-- Plays the game and checks it: the player falls onto the ground, runs, takes both coins, and the last coin loads the next root.
local check = require("check")
local onlr = require("onlr")
local score = require("shared.score")

-- Every frame lasts a sixtieth of a second, so the player moves the same way on every computer.
check.fixedTime(1 / 60)

-- The keys that the test holds down, in place of the keyboard's.
local held = {}
function love.keyboard.isDown(key)
  return held[key] == true
end

local function press(key)
  love.event.push("keypressed", key, key, false)
end

check.run(function()
  local tree = onlr.tree
  local function find(name)
    return assert(tree.find(name), name)
  end
  local player = find("Player")
  local music = find("Music").components.music

  -- The top node holds the music and the pause text, and the level runs under it as the root.
  check.equal({ tree.top.name, tree.root.name }, { "Game", "Level" }, "the top node and the root")
  check.equal(music.track:isPlaying(), true, "the music plays")
  check.equal(find("Pause").components.onlr.text:isEnabled(), false, "the pause text is off")
  check.equal(tree.root.components.bump.world.cellSize, 32, "the root has the world that its bodies collide in")

  -- The level's instances of the coin: one changed, with a script and a flag of its own, and its glint off.
  local big = find("Big coin")
  check.equal({ big.components.coin.worth, big.sclX, big.components.spin.speed }, { 5, 2, 2 }, "the changed coin")
  check.equal({ find("Flag"):getParent(), big:getChildren()[1]:isActive() }, { big, false }, "its flag, and its glint turned off")
  check.equal(find("Coin").components.spin, nil, "the other coin does not spin")

  -- The player falls onto the ground and stays there.
  check.frames(60)
  check.equal(player.posY, 552, "the player stands on the ground")
  check.ok(big.rot > 0, "the big coin spins")
  check.equal(find("Score").components.onlr.text.text, "Coins: 0", "the score's text")

  -- Space jumps.
  press("space")
  check.frames(5)
  check.ok(player.posY < 552, "the player jumps")
  check.frames(90)
  check.equal(player.posY, 552, "and lands")

  -- Escape pauses the root: it still draws, and nothing in it updates. The pause's own node hears the key again.
  held.right = true
  check.frames(10)
  check.ok(player.posX > 100, "the player runs to the right")
  press("escape")
  check.frames(2)
  local x = player.posX
  check.frames(10)
  check.equal(tree.root:isPaused(), true, "paused")
  check.equal(find("Pause").components.onlr.text:isEnabled(), true, "the pause text shows")
  check.equal(player.posX, x, "the player does not move")
  press("escape")
  check.frames(2)
  check.equal(tree.root:isPaused(), false, "resumed")

  -- The player takes the first coin: it is not solid, so the player runs through it.
  local frames = 0
  while score.coins == 0 and frames < 300 do
    check.frames(1)
    frames = frames + 1
  end
  check.equal(score.coins, 1, "the first coin")
  check.frames(2)
  check.equal(tree.find("Coin"), nil, "the coin was destroyed")
  check.equal(find("Score").components.onlr.text.text, "Coins: 1", "the score counts it")
  check.equal(tree.root.name, "Level", "a coin is left, so the level goes on")

  -- The last coin loads the next node file as the root. The top node stays, and the score lives in a module.
  frames = 0
  while tree.root.name == "Level" and frames < 300 do
    check.frames(1)
    frames = frames + 1
  end
  held.right = false
  check.equal({ score.coins, tree.root.name }, { 6, "Win" }, "the last coin, worth 5, ends the level")
  check.equal(tree.find("Player"), nil, "the level's nodes are gone")
  check.equal(find("Music").components.music, music, "the top node's own nodes stay")
  check.equal(music.track:isPlaying(), true, "and its music plays on")
  check.frames(2)
  check.equal(tree.root.components.onlr.text.text, "You win! Coins: 6", "the new root shows the score")

  -- A variant, spawned while the game runs: the coin, worth 5. Its body finds no world, so it adds one to the root.
  local spawned = tree.spawn("nodes/bigcoin.lua", 10, 10)
  check.equal({ spawned.name, spawned.components.coin.worth }, { "Big coin", 5 }, "a spawned variant")
  check.ok(tree.root.components.bump.world ~= nil, "the body added a world to the root")
end)
