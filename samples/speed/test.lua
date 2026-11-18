-- The measure of speed (DESIGN 16): 5000 nodes, each with a sprite and a script.
-- It reports the time of a frame's update and draw, also while nodes are spawned and destroyed in every frame.
local check = require("check")
local onlr = require("onlr")

local times = { update = 0, draw = 0, endFrame = 0 }

-- Measures the engine's steps of a frame.
for name in pairs(times) do
  local step = onlr.loop[name]
  onlr.loop[name] = function(...)
    local start = love.timer.getTime()
    step(...)
    times[name] = times[name] + love.timer.getTime() - start
  end
end

local function measure(frames, each)
  for name in pairs(times) do
    times[name] = 0
  end
  for _ = 1, frames do
    if each then
      each()
    end
    check.frames(1)
  end
  return ("update %.2f ms, draw %.2f ms, the frame's end %.2f ms"):format(
    times.update / frames * 1000, times.draw / frames * 1000, times.endFrame / frames * 1000)
end

check.run(function()
  check.equal(#onlr.tree.findAllComponents("mover"), 5000, "5000 nodes")
  -- A few frames first, so LuaJIT has compiled the code.
  check.frames(30)
  check.report("5000 nodes, a frame: " .. measure(100))

  local spawned = {}
  check.report("with 20 nodes spawned and 20 destroyed in each frame: " .. measure(100, function()
    for i = 1, 20 do
      spawned[#spawned + 1] = onlr.tree.spawn("nodes/dot.lua", i * 3, 230)
    end
    if #spawned > 200 then
      for _ = 1, 20 do
        table.remove(spawned, 1):destroy()
      end
    end
  end))
  check.equal(#onlr.tree.findAllComponents("mover"), 5200, "the spawned nodes")
  local first = assert(onlr.tree.find("Dot"))
  check.ok(first.posX ~= 6, "the scripts ran")
end)
