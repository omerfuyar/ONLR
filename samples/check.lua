-- The helper of the samples' tests (DESIGN 16). test.sh copies it into each sample's packages/, so a test loads it
-- with require("check"). A sample's main.lua loads its test.lua when LÖVE gets --test; the test calls check.run
-- with a function, which runs beside the game, a frame at a time, and checks it. Then the game quits:
-- with 0 when every check passed, and with 1 and the failed checks printed otherwise.

local check = {}

local failures = 0
local count = 0

local function fail(message)
  failures = failures + 1
  print("FAILED: " .. message)
  print(debug.traceback("", 3))
end

---Checks that a value is true.
---@param value any
---@param what string what was checked, for the message
function check.ok(value, what)
  count = count + 1
  if not value then
    fail(what)
  end
end

local function same(a, b)
  if rawequal(a, b) then
    return true
  end
  if type(a) ~= "table" or type(b) ~= "table" then
    if type(a) == "number" and type(b) == "number" then
      return math.abs(a - b) < 1e-6
    end
    return a == b
  end
  for k, v in pairs(a) do
    if not same(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

local function show(value, depth)
  depth = depth or 0
  if type(value) == "table" and (depth > 3 or getmetatable(value)) then
    return tostring(rawget(value, "name") or value)
  end
  if type(value) ~= "table" then
    return type(value) == "string" and ("%q"):format(value) or tostring(value)
  end
  local keys = {}
  for k in pairs(value) do
    keys[#keys + 1] = k
  end
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  local parts = {}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = tostring(k) .. " = " .. show(value[k], depth + 1)
  end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

---Checks that two values are equal: tables field by field, and numbers nearly.
---@param actual any
---@param expected any
---@param what string
function check.equal(actual, expected, what)
  count = count + 1
  if not same(actual, expected) then
    fail(("%s: got %s, expected %s"):format(what, show(actual), show(expected)))
  end
end

---Checks that a function raises an error whose message holds a text, and gives the message.
---@param fn fun(): any
---@param text string
---@param what string
---@return string?
function check.fails(fn, text, what)
  count = count + 1
  local ok, err = pcall(fn)
  if ok then
    fail(what .. ": no error")
    return nil
  end
  if not tostring(err):find(text, 1, true) then
    fail(("%s: the error %q does not say %q"):format(what, tostring(err), text))
  end
  return tostring(err)
end

---Lets the game run a number of frames, then goes on with the test.
---@param frames? integer 1 when left out
function check.frames(frames)
  for _ = 1, frames or 1 do
    coroutine.yield()
  end
end

---Prints a line that test.sh shows also when the test passes, such as a time that was measured.
---@param text string
function check.report(text)
  print("report: " .. text)
end

---Makes every frame last the same time, so a test's game moves the same way on every computer.
---@param dt? number 1/60 when left out
function check.fixedTime(dt)
  love.timer.step = function()
    return dt or (1 / 60)
  end
end

---Runs a test beside the game: the function goes on once in each frame, in love.update, before the components' update.
---The game quits when it returns.
---@param test fun()
function check.run(test)
  love.errorhandler = function(message)
    print("ERROR: " .. debug.traceback(tostring(message), 2))
    return function()
      return 1
    end
  end
  local thread = coroutine.create(test)
  local update = love.update
  function love.update(dt)
    if update then
      update(dt)
    end
    if coroutine.status(thread) == "dead" then
      return
    end
    local ok, err = coroutine.resume(thread)
    if not ok then
      print("ERROR: " .. debug.traceback(thread, tostring(err)))
      failures = failures + 1
    end
    if coroutine.status(thread) == "dead" then
      print(("%d checks, %d failed"):format(count, failures))
      love.event.quit(failures > 0 and 1 or 0)
    end
  end
end

return check
