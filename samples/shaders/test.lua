-- Checks shaders (DESIGN 6.7, 10): onlr.shader draws each draw of its nodes through its shader, or its nodes as one picture,
-- with the values that the node file and a script give; components that name one file share its shader; the engine's time;
-- a draw that leaves its shader set is set back; an image among the values; and the error of a shader that does not compile.
-- The test draws the tree into a canvas and reads its pixels.
local check = require("check")
local onlr = require("onlr")
local shaders = require("onlr.library.shader")

check.fixedTime(1 / 60)

local canvas

-- Draws the tree as a frame does, and gives a function that reads a pixel as a text, such as "255 0 0".
local function draw()
  canvas = canvas or love.graphics.newCanvas(320, 240)
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.origin()
  onlr.loop.draw()
  love.graphics.setCanvas()
  local pixels = canvas:newImageData()
  return function(x, y)
    local r, g, b = pixels:getPixel(x, y)
    return ("%d %d %d"):format(r * 255 + 0.5, g * 255 + 0.5, b * 255 + 0.5)
  end
end

check.run(function()
  local tree = onlr.tree
  check.frames(1)

  -- draws: the white squares take each node's tint; both name tint.glsl and share one shader, so each sends its own values
  local at = draw()
  check.equal(at(18, 18), "255 0 0", "a shader's values from the node file tint its square")
  check.equal(at(48, 18), "0 255 0", "another node of the same file draws with its own values")
  check.equal(at(5, 5), "0 0 0", "nothing beside the squares")
  local tinted = assert(tree.find("Tinted")).components.onlr.shader.passes[1]
  local again = assert(tree.find("Tinted again")).components.onlr.shader.passes[1]
  check.equal(tinted.shader, again.shader, "two components that name one file share its shader")

  -- a node of the same file that sets no values gets what the file's notes start them with, half of blue, and not the
  -- values of the node drawn before it, which shares its shader
  local defaulted = at(78, 18)
  check.ok(defaulted == "128 128 255" or defaulted == "127 127 255", "values that a node does not set start as the notes say: " .. defaulted)

  -- passes: draws tints the square red, and the second pass moves the picture; three passes move it twice
  check.equal(at(23, 53), "255 0 0", "a second pass shades what the first drew")
  check.equal(at(12, 53), "0 0 0", "and moves it from where it was")
  check.equal(at(123, 53), "0 255 0", "three passes, each on the picture of the one before")
  check.equal(at(113, 53), "0 0 0", "the third moved it again")

  -- picture: the nodes draw into one picture, which the shader moves to the right as a whole; draws could not move a shape
  check.equal(at(113, 14), "255 255 255", "picture moves what its nodes drew")
  check.equal(at(102, 14), "0 0 0", "and leaves where they were")

  -- a draw that sets a shader and does not set it back shades nothing after it
  check.equal(at(193, 14), "0 0 255", "a script draws through its own shader")
  check.equal(at(212, 18), "255 255 255", "the node drawn after it is not shaded: the engine set the shader back")

  -- a text among the values is an image of the project
  local masked = assert(tree.find("Masked")).components.onlr.shader.passes[1]
  check.equal(masked.values.pattern and masked.values.pattern:type(), "Image", "an image's path in values gives an image")
  check.equal(at(238, 18), "0 0 255", "which the shader draws with")

  -- a script sets a value, and the shader gets it before the next draw
  tinted.values.amount = 0
  at = draw()
  check.equal(at(18, 18), "255 255 255", "a value that a script sets reaches the shader")
  check.equal(at(48, 18), "0 255 0", "and only its own component's draw")
  tinted.values.amount = 1

  -- time is the sum of the frames' dt, which the loop sends before each frame draws
  local before = shaders.time
  check.frames(30)
  check.ok(math.abs(shaders.time - before - 0.5) < 1e-6, "30 frames of 1/60 move time by half a second: " .. shaders.time - before)
  local red = tonumber(draw()(158, 18):match("^(%d+)"))
  local wanted = (shaders.time % 1) * 255
  check.ok(math.abs(red - wanted) <= 2, ("a shader's time is the engine's: red %d, wanted %.1f"):format(red, wanted))

  -- the values that a GLSL file declares, read from its text: time is the engine's, and not among them
  local listed = {}
  for _, value in ipairs(shaders.values(assert(love.filesystem.read("effects/tint.glsl")))) do
    listed[#listed + 1] = value.name .. ":" .. value.type
  end
  check.equal(table.concat(listed, " "), "amount:number tint:vec4", "a GLSL file's values")
  -- the notes at the ends of their lines
  local notes = shaders.values(table.concat({
    "extern number amount; // 0 to 1, default 0.5: how much of the colour",
    "extern vec4 tint;     // color, default 0 0 1 1",
    "extern vec3 glow;     // color",
    "extern int steps;     // 1 to 8, default 4",
    "extern bool on;       // default true",
    "extern number speed;  // how fast it moves",
    "extern vec2 wind;     // default 1 2 3",
  }, "\n"))
  local a, t, g, st, on, sp, w = unpack(notes)
  check.ok(a.min == 0 and a.max == 1 and a.default == 0.5 and a.description == "how much of the colour", "a range, a default and a description")
  check.ok(t.color and t.default[3] == 1 and t.description == nil, "a colour and its default")
  check.equal(table.concat(shaders.start(g), " "), "1 1 1", "a colour without a default starts white")
  check.ok(st.min == 1 and st.max == 8 and st.default == 4, "an int's range")
  check.equal(on.default, true, "a bool's default")
  check.ok(sp.description == "how fast it moves" and sp.min == nil, "a note of no word of its own is a description")
  check.ok(w.default == nil and table.concat(shaders.start(w), " ") == "0 0", "a default of the wrong size is passed over")
  check.equal(#shaders.values(assert(love.filesystem.read("effects/clock.glsl"))), 0, "time is not a value of the user's")

  -- a shader that does not compile is an error that names its file and line, and the node and the property that name it
  check.fails(function()
    tree.spawn("nodes/broken.lua")
  end, "nodes/broken.lua, node Broken, property passes[1].shader: effects/broken.glsl:4: ", "a shader that does not compile")
end)
