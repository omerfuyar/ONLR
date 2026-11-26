-- Checks the physics package (DESIGN 11.4): bodies fall and land, a body of two fixtures on nodes of their own, contacts
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
  check.equal(#crate.components.physics.body.fixtures, 2, "the crate's body holds the fixtures of the nodes under it")
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
  check.ok(assert(hook.components.physics.joint:get()):getMaxLength() > 29, "rope:get() gives LÖVE's joint")

  -- A joint ends with either body: the weight turned off frees the hook's rope.
  weight:setActive(false)
  check.frames(1)
  check.equal(hook.components.physics.joint:get(), nil, "the rope is gone with the weight")
  weight:setActive(true)
  check.frames(1)
  check.ok(hook.components.physics.joint:get() ~= nil, "and comes back with it")

  -- A fixture takes its node's onlr.shape: a line of two points is an edge, and of more a chain, both of which collide.
  local function lineOf(name, points)
    local node = tree.newNode(name)
    -- far beside the level, where nothing falls on it
    node.posX = 2000
    node:addComponent("onlr.shape", { kind = "line", points = points })
    node:addComponent("physics.body", { type = "static" })
    node:addComponent("physics.fixture")
    return assert(node.components.physics.fixture:get()):getShape():getType()
  end
  check.equal(lineOf("Edge", { { x = 0, y = 0 }, { x = 40, y = 0 } }), "edge", "a line of two points is an edge")
  check.equal(lineOf("Chain", { { x = 0, y = 0 }, { x = 40, y = 0 }, { x = 80, y = 20 } }), "chain", "a line of three is a chain")
  check.equal(ground.components.physics.fixture:get():getShape():getType(), "polygon", "a rectangle is a box, Box2D's polygon")

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

  -- What a script changes after the start reaches Box2D before the next step (DESIGN 11.4). Far beside the level, without
  -- gravity's help: a static body with a fixture on a node under it.
  local holder = tree.newNode("Holder")
  holder.posX = 3000
  holder:addComponent("physics.body", { type = "static" })
  local part = tree.newNode("Part", holder)
  part:addComponent("onlr.shape", { width = 10, height = 10 })
  local fixture = part:addComponent("physics.fixture")
  check.frames(1)
  local x1 = assert(fixture:get()):getBoundingBox()
  part.posX = 50
  check.frames(1)
  near(assert(fixture:get()):getBoundingBox() - x1, 50, "a fixture's node that moves under its body moves the fixture")
  local function width()
    local left, _, right = assert(fixture:get()):getBoundingBox()
    return right - left
  end
  local before = width()
  part.components.onlr.shape.width = 30
  check.frames(1)
  near(width() - before, 20, "a shape that a script resizes collides at its new size")
  fixture.friction = 0.9
  check.frames(1)
  near(assert(fixture:get()):getFriction(), 0.9, "a fixture's property that a script changes is set")
  local body = holder.components.physics.body
  body.gravityScale = 0
  body.type = "kinematic"
  check.frames(1)
  check.equal({ body:get():getGravityScale(), body:get():getType() }, { 0, "kinematic" }, "and a body's")
  local world = assert(tree.findComponent("physics.world"))
  local gravity = world.gravity
  world.gravity = { x = 10, y = 20 }
  check.frames(1)
  check.equal({ world:get():getGravity() }, { 10, 20 }, "a gravity that a script changes")
  world.gravity = gravity

  -- A chain may close into a loop: a line of three points is two edges open, and three as a loop.
  local function chainOf(loop)
    local node = tree.newNode("Chain", holder)
    node:addComponent("onlr.shape", { kind = "line", points = { { x = 0, y = 0 }, { x = 40, y = 0 }, { x = 20, y = 30 } } })
    local f = node:addComponent("physics.fixture", { loop = loop })
    return assert(f:get()):getShape():getChildCount()
  end
  check.equal({ chainOf(false), chainOf(true) }, { 2, 3 }, "a chain's loop joins its last point to its first")

  -- Box2D's other joints, each between two bodies; a value that tunes one is set without making it again.
  local placed = 0
  local function jointOf(kind, values)
    -- each pair apart from the others, so they do not collide
    placed = placed + 1
    local a = tree.newNode("A" .. kind)
    a.posX, a.posY = 5000 + placed * 200, 0
    a:addComponent("physics.body", { type = "static" })
    local b = tree.newNode("B" .. kind)
    b.posX, b.posY = a.posX, 50
    b:addComponent("onlr.shape", { kind = "circle", radius = 5 })
    local other = b:addComponent("physics.body", { gravityScale = 0 })
    b:addComponent("physics.fixture")
    values = values or {}
    values.kind, values.other = kind, other
    return a:addComponent("physics.joint", values)
  end
  for _, kind in ipairs({ "prismatic", "wheel", "friction", "motor", "pulley" }) do
    local joint = jointOf(kind)
    check.frames(1)
    check.equal(joint:get() and joint:get():getType(), kind, "a joint of kind " .. kind)
  end
  local slider = jointOf("prismatic", { motor = true, motorSpeed = 0, axis = { x = 0, y = 1 } })
  check.frames(1)
  local made = slider:get()
  slider.motorSpeed = 40
  check.frames(30)
  check.equal(slider:get(), made, "a tuned joint is not made again")
  near(assert(slider:get() --[[@as love.PrismaticJoint]]):getMotorSpeed(), 40, "its motor's new speed is set")
  check.ok(slider.other.node.posY > 55, "and slides the other body along the axis: " .. slider.other.node.posY)

  -- A joint's node that moves under its body makes the joint again, at its new place.
  local pin = tree.newNode("Pin", holder)
  local swing = tree.newNode("Swinging")
  swing.posX, swing.posY = 3000, 40
  local swingBody = swing:addComponent("physics.body", { gravityScale = 0 })
  local hinge = pin:addComponent("physics.joint", { kind = "hinge", other = swingBody })
  check.frames(1)
  pin.posY = 20
  check.frames(1)
  local _, ay = assert(hinge:get()):getAnchors()
  near(ay, 20, "a joint's node that moves under its body moves the joint")

  -- While the top node loads, there is no root to add a world to: a body that finds none says so (DESIGN 11.4).
  local early = tree.newNode("Early", tree.top)
  check.fails(function()
    check.whileTopLoads(function() early:addComponent("physics.body") end)
  end, "while the top node loads: put a physics.world on the top node", "a body on the top node without a world")
  early:destroy()
  check.frames(1)
end)
