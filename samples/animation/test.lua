-- Checks the anim8 package (DESIGN 11.5): an animation sets its sprite's quad to each frame in turn, loops, plays
-- another on play, stops at the end of one that does not loop and tells its node, and plays a range backwards.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

-- The column and row, from 1, of the frame that a node's sprite shows.
local function frame(node)
  local quad = node.components.onlr.sprite.quad
  check.equal(quad.width, 16, "a frame is 16 pixels wide")
  return quad.x / 16 + 1, quad.y / 16 + 1
end

check.run(function()
  local tree = onlr.tree
  local roller, jumper = assert(tree.find("Roller")), assert(tree.find("Jumper"))
  local animation = roller.components.anim8.animation

  -- Without first, the first of the list plays, from its first frame.
  check.equal(animation.current, "roll", "the first animation of the list plays")
  check.equal(select(1, frame(roller)), 1, "from the first frame")
  check.equal(select(2, frame(roller)), 1, "of the first row")
  check.equal(#animation:get().frames, 4, "get() gives anim8's animation")

  -- first names the animation that plays first; 4-1 plays the row backwards, each frame for 0.2 seconds.
  local other = jumper.components.anim8.animation
  check.equal(other.current, "jump", "first chooses the animation")
  check.equal(frame(jumper), 4, "4-1 starts at the fourth column")

  -- A frame shows for 0.1 seconds: 7 frames of the game are past it.
  check.frames(7)
  check.equal(frame(roller), 2, "the second frame after 0.1 seconds")
  check.frames(18)
  check.equal(frame(roller), 1, "and the first again after 0.4: it loops")
  check.equal(frame(jumper), 2, "the jumper went back two columns in 0.4 seconds")

  -- play: another animation, from its first frame. Playing the one that plays changes nothing.
  animation:play("jump")
  check.equal(select(2, frame(roller)), 2, "the jump shows the second row")
  check.equal(frame(roller), 1, "from its first frame")
  check.frames(7)
  animation:play("jump")
  check.equal(frame(roller), 2, "play of the animation that plays goes on")
  check.frames(30)
  check.equal(frame(roller), 3, "it stops on its last frame")
  check.equal(animation:isPlaying(), false, "and plays no more")
  check.equal(#roller.components.probe.ended, 1, "its node is told once")
  check.equal(roller.components.probe.ended[1], "jump", "with the animation's name")
  animation:play("jump")
  check.equal(frame(roller), 1, "play starts one that stopped again")
  check.fails(function()
    animation:play("fly")
  end, "there is no animation fly", "play of a name that is not in the list fails")

  -- pause holds the frame, and resume goes on.
  animation:play("roll")
  animation:pause()
  check.frames(30)
  check.equal(frame(roller), 1, "a paused animation holds its frame")
  animation:resume()
  check.frames(7)
  check.equal(frame(roller), 2, "and resume goes on")
  check.equal(frame(jumper), 1, "the jumper stopped on its last frame, the first column")
  check.equal(jumper.components.probe.ended[1], "jump", "and was told")
end)
