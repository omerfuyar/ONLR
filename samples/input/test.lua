-- Checks the baton package (DESIGN 11.9): controls bound to keys, a pair read as a stick, pressed for one frame,
-- released, binding again with apply, a joystick that is not there, and the errors of a source or a pair that is wrong.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

-- The test holds keys itself: baton asks love.keyboard.isDown each frame.
local held = {}
love.keyboard.isDown = function(...)
  for i = 1, select("#", ...) do
    if held[select(i, ...)] then
      return true
    end
  end
  return false
end

check.run(function()
  local player = assert(onlr.tree.find("Player"))
  local input, walker = player.components.baton.input, player.components.walker
  check.ok(input ~= nil, "a script that needs it gets it")
  check.equal(input:getJoystick(), nil, "no joystick is connected")
  check.equal(input:getActiveDevice(), "none", "nothing was used yet")

  -- A pair: right and down at once are a stick at 45 degrees, of length 1.
  held.d, held.down = true, true
  check.frames(1)
  local x, y = input:get("move")
  check.ok(math.abs(x - y) < 1e-9 and math.abs(x * x + y * y - 1) < 1e-9, ("the pair is a stick of length 1: %s, %s"):format(x, y))
  check.equal(input:getActiveDevice(), "kbm", "the keyboard was used")
  local px = player.posX
  check.frames(60)
  check.ok(player.posX - px > 40, "the script walked by the pair: " .. (player.posX - px))
  held.d, held.down = nil, nil
  check.frames(1)
  check.equal(input:down("move"), false, "let go, the pair is not down")
  check.equal(input:released("move"), true, "and was released")

  -- pressed is true for one frame, while the key is held.
  held.space = true
  check.frames(1)
  check.equal(input:pressed("jump"), true, "jump is pressed in the frame that space went down")
  check.equal(input:down("jump"), true, "and down")
  check.frames(5)
  check.equal(input:pressed("jump"), false, "and not pressed in the frames after")
  check.equal(walker.jumps, 1, "the script saw one jump")
  held.space = nil
  check.frames(1)
  check.equal(input:released("jump"), true, "released when it is let go")
  held.space = true
  check.frames(1)
  check.equal(walker.jumps, 2, "a second press is a second jump")
  held.space = nil

  -- apply binds the controls again: jump is now the key j.
  input.controls[5].sources = "key:j"
  input:apply()
  held.space = true
  check.frames(1)
  check.equal(input:down("jump"), false, "space no longer jumps after apply")
  held.space, held.j = nil, true
  check.frames(1)
  check.equal(input:down("jump"), true, "j does")
  held.j = nil

  -- A source of no kind, and a pair of a control that is not there, are errors when the input loads.
  input.controls = { { name = "fire", sources = "keys:f" } }
  check.fails(function()
    input:apply()
  end, "a source keys:f", "a source of no kind is an error")
  input.controls = { { name = "left", sources = "key:left" } }
  check.fails(function()
    input:apply()
  end, "names right for right", "a pair of a missing control is an error")
  check.fails(function()
    input:get("fly")
  end, "No control with name", "asking for a control that is not there is an error")
end)
