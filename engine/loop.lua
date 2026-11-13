-- onlr.loop: the steps that the engine adds to LÖVE's loop (DESIGN 8.1). The engine's love.run calls them,
-- around LÖVE's own callbacks. A game that sets its own love.run calls them from its own loop instead.

local data = require("onlr.data")
local life = require("onlr.life")
local tree = require("onlr.tree")

---@class onlr.loop
local loop = {}

-- The time that fixedUpdate has not used yet.
local rest = 0

-- What the player's files set when the editor started the game (DESIGN 12.1): frame() is called once
-- in each turn of the loop, and while paused is true the loop draws and calls nothing of the game.
-- step asks for one frame of a fixed step while paused.
---@type {frame: fun()?, paused: boolean?, step: boolean?}?
loop._player = nil

---Loads the top node and the first root. Called once, after love.load.
function loop.load()
  tree._load()
end

---Calls the components' function of an event's name, after LÖVE's handler of it.
---@param name string such as "keypressed"
---@param ... any what LÖVE gives with the event
---@return boolean stay for quit only: a component's quit returned true, so the game does not quit
function loop.event(name, ...)
  local any = life.call(name, ...)
  return name == "quit" and any
end

---Calls the components' fixedUpdate as often as the time asks, then their update, then their lateUpdate.
---Called after love.update.
---@param dt number seconds since the last frame
function loop.update(dt)
  local step = 1 / (data.manifest().fixedRate or 60)
  rest = rest + dt
  local count = 0
  while rest >= step and count < 8 do
    life.call("fixedUpdate", step)
    rest = rest - step
    count = count + 1
  end
  if rest >= step then
    rest = 0
  end
  life.call("update", dt)
  life.call("lateUpdate", dt)
end

---Calls the components' draw in the order of drawing, and each group's drawTree in its place. Called before love.draw.
function loop.draw()
  life.draw()
end

---Takes out what was destroyed, loads a new root if a script asked for one,
---and calls start of the components that started to run. Called when the frame ends.
function loop.endFrame()
  tree._endFrame()
end

---The engine's love.run: LÖVE's own loop, with the steps above added. onlr.start makes it LÖVE's.
---@return fun(): any
function loop.run()
  if love.load then
    ---@diagnostic disable-next-line: undefined-field
    love.load(love.arg.parseGameArguments(arg), arg)
  end
  loop.load()
  if love.timer then
    love.timer.step()
  end
  local dt = 0

  return function()
    local player = loop._player
    if player and player.frame then
      player.frame()
    end
    local paused = player and player.paused and not player.step
    if love.event then
      love.event.pump()
      for name, a, b, c, d, e, f in love.event.poll() do
        if name == "quit" then
          local stay = not paused and love.quit and love.quit()
          if not paused and loop.event("quit", a) then
            stay = true
          end
          if not stay then
            return a or 0
          end
        elseif not paused then
          ---@diagnostic disable-next-line: undefined-field
          love.handlers[name](a, b, c, d, e, f)
          loop.event(name, a, b, c, d, e, f)
        end
      end
    end

    if love.timer then
      dt = love.timer.step()
    end
    if player and player.step then
      dt = 1 / (data.manifest().fixedRate or 60)
      rest = 0
    end
    if not paused then
      if love.update then
        love.update(dt)
      end
      loop.update(dt)
    end

    if love.graphics and love.graphics.isActive() then
      love.graphics.origin()
      love.graphics.clear(love.graphics.getBackgroundColor())
      loop.draw()
      if love.draw then
        love.draw()
      end
      love.graphics.present()
    end

    if not paused then
      loop.endFrame()
    end
    if player then
      player.step = false
    end
    if love.timer then
      love.timer.sleep(0.001)
    end
  end
end

return loop
