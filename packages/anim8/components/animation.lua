-- The component type anim8.animation: plays the frames of a sprite sheet on the node's onlr.sprite.
-- The sprite draws the image; the animation only chooses its part, the sprite's quad, each frame. So the sprite's
-- colour and origin, and the node's place, scale and turn, hold for every frame: a scale of -1 on x flips it.
local onlr = require("onlr")
local anim8 = require("anim8")

---@class anim8.animation : onlr.Component
---@field current string? the name of the animation that plays, or that stopped at its end
---@field private built table<string, anim8.Animation> anim8's animations, by their names
---@field private _editor boolean? it is in the node view, which tells no node
local Animation = {}

Animation.needs = { "onlr.sprite" }

-- The grid: how the sprite's image is cut into frames, as anim8.newGrid takes it.
Animation.frameWidth = onlr.property.integer(32, { min = 1, heading = "Grid" })
Animation.frameHeight = onlr.property.integer(32, { min = 1 })
Animation.left = onlr.property.integer(0, { min = 0, description = "Where the first frame starts, from the image's left" })
Animation.top = onlr.property.integer(0, { min = 0, description = "Where the first frame starts, from the image's top" })
Animation.border = onlr.property.integer(0, { min = 0, description = "The space between frames" })

-- The animations: each takes the frames of its columns and rows of the grid, in rows, as anim8's grid does.
Animation.animations = onlr.property.list(onlr.property.group({
  name = onlr.property.string("idle"),
  columns = onlr.property.string("1-4", { description = "A column, or a range of them: 3, 1-4, or 4-1 backwards" }),
  rows = onlr.property.string("1", { description = "A row, or a range of them" }),
  duration = onlr.property.number(0.1, { min = 0.001, description = "The seconds that each frame shows" }),
  loop = onlr.property.bool(true, { description = "It starts again at its end. Without, it stops on its last frame and its node is told animationEnd(name)" }),
}), { heading = "Animations" })
Animation.first = onlr.property.string("", { description = "The animation that plays first: the first of the list when empty" })

-- A column or a row as anim8 takes it: a number, or a range such as "1-4".
local function interval(text)
  local trimmed = text:gsub("%s", "")
  return tonumber(trimmed) or trimmed
end

-- Once: cuts the sprite's image into the grid, and makes each animation.
function Animation:load()
  local sprite = self.node.components.onlr.sprite --[[@as onlr.sprite]] -- always there: the type needs it
  local image = sprite.image
  if not image then
    error("anim8.animation: the sprite has no image to cut into frames", 0)
  end
  local w, h = image:getDimensions()
  local grid = anim8.newGrid(self.frameWidth, self.frameHeight, w, h, self.left, self.top, self.border)
  self.built = {}
  for _, a in ipairs(self.animations) do
    local ok, frames = pcall(grid.getFrames, grid, interval(a.columns), interval(a.rows))
    if not ok then
      error(("anim8.animation %s: %s"):format(a.name, tostring(frames)), 0)
    end
    local name = a.name
    local onLoop
    if not a.loop then
      onLoop = function(animation)
        animation:pauseAtEnd()
        -- the node view tells no node: it runs no script (DESIGN 6.5)
        if not self._editor then
          self.node:send("animationEnd", name)
        end
      end
    end
    self.built[name] = anim8.newAnimation(frames, a.duration, onLoop)
  end
  local first = self.first ~= "" and self.first or (self.animations[1] and self.animations[1].name)
  self.current = nil
  if first then
    self:play(first)
  end
end

-- In the node view (DESIGN 6.5): the sprite shows the first frame of the animation that plays first, as the game starts with it,
-- and not the whole sheet. Without an image there is nothing to cut yet, and nothing is wrong.
function Animation:loadEditor()
  self._editor = true
  if (self.node.components.onlr.sprite --[[@as onlr.sprite]]).image then
    self:load()
  end
end

-- In the node view, while its node is chosen (DESIGN 6.5): the animation plays, and one that does not loop starts again at its end.
function Animation:updateEditor(dt)
  local animation = self.built and self.built[self.current]
  if animation then
    if animation.status == "paused" then
      animation:gotoFrame(1)
      animation:resume()
    end
    self:update(dt)
  end
end

-- Copies the frame that anim8 shows into the sprite's quad.
function Animation:_show()
  local animation = self.built[self.current]
  local x, y, w, h = animation.frames[animation.position]:getViewport()
  local quad = (self.node.components.onlr.sprite --[[@as onlr.sprite]]).quad
  quad.x, quad.y, quad.width, quad.height = x, y, w, h
end

-- Not called by the engine: scripts call it. Plays an animation from its first frame.
-- The one that plays already goes on, unless restart is true, so a script may call play each frame.
---@param name string
---@param restart? boolean
function Animation:play(name, restart)
  local animation = self.built[name]
  if not animation then
    error(("anim8.animation: there is no animation %s"):format(tostring(name)), 2)
  end
  if name == self.current and not restart and animation.status == "playing" then
    return
  end
  self.current = name
  animation:gotoFrame(1)
  animation:resume()
  self:_show()
end

-- Stops the animation on its frame, and resume goes on from there.
function Animation:pause()
  local animation = self.built[self.current]
  if animation then
    animation:pause()
  end
end

function Animation:resume()
  local animation = self.built[self.current]
  if animation then
    animation:resume()
  end
end

-- Whether the current animation plays: false when it is paused, or stopped at its end.
---@return boolean
function Animation:isPlaying()
  local animation = self.built[self.current]
  return animation ~= nil and animation.status == "playing"
end

-- anim8's animation, by its name, or the current one: for what the component does not do, such as its frame or its timer.
---@param name? string
---@return anim8.Animation?
function Animation:get(name)
  return self.built[name or self.current]
end

function Animation:update(dt)
  local animation = self.built[self.current]
  if animation then
    animation:update(dt)
    self:_show()
  end
end

return Animation
