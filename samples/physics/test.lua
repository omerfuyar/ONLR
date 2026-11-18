-- Checks the physics package (DESIGN 11.4): bodies fall and land, a body of two shapes on nodes of their own, contacts
-- told to both nodes, a polygon, the four joints, a node that a script moves, and a node that is turned off leaving the
-- world.
local check = require("check")
local onlr = require("onlr")

check.fixedTime(1 / 60)

local function near(actual, expected, what)
  check.ok(math.abs(actual - expected) < 1, ("%s: %s, not about %s"):format(what, tostring(actual), tostring(expected)))
end

check.run(function()
  local tree = onlr.tree
  local ground, ball, crate = assert(tree.find("Ground")), assert(tree.find("Ball")), assert(tree.find("Crate"))
  check.equal(tree.root.components.physics.world.meter, 64, "the root has the world")
  check.equal(#crate.components.physics.body.shapes, 2, "the crate's body holds the boxes of the nodes under it")
  check.equal(ground.components.physics.body:get():getType(), "static", "the ground's body is static")

  -- Both fall onto the ground, whose top is at 210: the ball's middle rests at 200, and so does the crate's.
  check.frames(120)
  near(ball.posY, 200, "the ball rests on the ground")
  near(crate.posY, 200, "the crate rests on the ground")
  check.equal(crate.rot, 0, "the crate does not turn: its rotation is fixed")
  local hit = ball.components.probe.hits[1]
  check.equal(hit and hit[1], "Ground", "the ball is told that it touched the ground")
  near(hit[2], 0, "the normal points up")
  near(hit[3], -1, "the normal points up")
  check.equal(ground.components.probe, nil, "the ground has no probe, and is told all the same")

  -- A polygon: the triangle's base, 10 below its node, rests on the ground.
  local triangle = assert(tree.find("Triangle"))
  near(triangle.posY, 200, "the triangle rests on the ground")

  -- Joints: each holds two bodies as its kind does, after two seconds of falling and swinging.
  local function apart(a, b)
    local ax, ay = a:toWorld(0, 0)
    local bx, by = b:toWorld(0, 0)
    return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
  end
  local nail, bob = assert(tree.find("Nail")), assert(tree.find("Bob"))
  near(apart(nail, bob), 40, "the hinge keeps the pendulum on its nail")
  check.ok(bob.posY > 20, "and it swung down: " .. bob.posY)
  local hook, weight = assert(tree.find("Hook")), assert(tree.find("Weight"))
  near(weight.posY, 50, "the rope lets the weight fall to its length, 30 below the hook")
  local post, swing = assert(tree.find("Post")), assert(tree.find("Swing"))
  near(apart(post, swing), 30, "the stick keeps its distance")
  local lid = assert(tree.find("Lid"))
  near(lid.posY, crate.posY - 15, "the welded lid stays on the crate")
  near(lid.posX, crate.posX, "and above it")
  check.ok(assert(hook.components.physics.joint.rope:get()):getMaxLength() > 29, "rope:get() gives LÖVE's joint")

  -- A joint ends with either body: the weight turned off frees the hook's rope.
  weight:setActive(false)
  check.frames(1)
  check.equal(hook.components.physics.joint.rope:get(), nil, "the rope is gone with the weight")
  weight:setActive(true)
  check.frames(1)
  check.ok(hook.components.physics.joint.rope:get() ~= nil, "and comes back with it")

  -- A script moves a node: the body goes there, and falls from there.
  ball.posY = 0
  check.frames(1)
  check.ok(ball.posY > 0 and ball.posY < 10, "the ball falls from where the script put it: " .. ball.posY)
  check.frames(120)
  near(ball.posY, 200, "and lands again")

  -- The ground turned off leaves the world: the bodies on it are told that the contact ended, and fall.
  local ends = #ball.components.probe.ends
  ground:setActive(false)
  check.frames(30)
  check.ok(#ball.components.probe.ends > ends, "the ball is told that the contact ended")
  check.ok(ball.posY > 220 and crate.posY > 220, "nothing stands on a ground that is turned off")
  check.equal(ground.components.physics.body:get(), nil, "the ground's body is gone")
end)
