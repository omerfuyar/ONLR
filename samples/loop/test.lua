-- Checks the engine's loop (DESIGN 8.1): the order of a frame's steps, fixedUpdate, events and quit.
local check = require("check")
local onlr = require("onlr")
local log = require("shared.log")

-- Every frame lasts 0.051 seconds, and fixedRate is 50: two or three fixed steps of 0.02 in each frame.
check.fixedTime(0.051)

local function without(lines, text)
  local out = {}
  for _, line in ipairs(lines) do
    if not line:find(text, 1, true) then
      out[#out + 1] = line
    end
  end
  return out
end

check.run(function()
  -- love.load, then the tree loads, and start is called when it has loaded.
  -- This function goes on in love.update, so the first frame's love.update is in the log too.
  check.equal(log.take(), { "love.load", "load", "start", "love.update" }, "loading")

  -- A frame: LÖVE's callback first, then the components', and love.draw over the nodes.
  check.frames(1)
  check.equal(without(log.take(), "fixedUpdate"), { "update", "lateUpdate", "draw", "love.draw", "love.update" }, "one frame")

  -- fixedUpdate is called as often as the time asks, before update, with the same dt each time.
  log.take()
  check.frames(4)
  local fixed, firstUpdate, firstFixed = 0, nil, nil
  for i, line in ipairs(log.take()) do
    if line == "fixedUpdate 0.02" then
      fixed = fixed + 1
      firstFixed = firstFixed or i
    elseif line == "update" then
      firstUpdate = firstUpdate or i
    end
  end
  check.equal(fixed, 10, "ten fixed steps in four frames of 0.051 seconds")
  check.ok(firstFixed < firstUpdate, "fixedUpdate comes before update")

  -- In a frame that lasts long, fixedUpdate is called at most 8 times.
  check.fixedTime(1)
  check.frames(1)
  log.take()
  check.fixedTime(0.001)
  check.frames(1)
  local count = 0
  for _, line in ipairs(log.take()) do
    count = count + (line:find("fixedUpdate", 1, true) and 1 or 0)
  end
  check.equal(count, 8, "at most 8 fixed steps in a frame")

  -- An event: LÖVE's handler, which calls the game's own callback, then the components' function of that name.
  love.event.push("keypressed", "a", "a", false)
  love.event.push("ping", 5)
  check.frames(1)
  local lines = log.take()
  local events = {}
  for _, line in ipairs(lines) do
    if line:find("key", 1, true) or line:find("ping", 1, true) then
      events[#events + 1] = line
    end
  end
  check.equal(events, { "love.keypressed a", "keypressed a", "love.handlers.ping 5", "ping 5" }, "events")

  -- quit: the game does not quit when a component's quit returns true.
  love.event.quit(3)
  check.frames(2)
  check.ok(table.concat(log.take(), " "):find("quit", 1, true), "the component's quit was asked, and the game runs on")

  -- onlr.loop's steps are functions, which a game's own love.run calls.
  for _, name in ipairs({ "load", "event", "update", "draw", "endFrame" }) do
    check.equal(type(onlr.loop[name]), "function", "onlr.loop." .. name)
  end
end)
