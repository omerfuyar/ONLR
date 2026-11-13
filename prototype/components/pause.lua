-- A script on a node under the top node: Escape pauses the root, the level.
-- A paused node still draws and gets no update or event, so the level stays on the screen
-- behind the text, and the player does not move. This node is not paused, so it hears the key again.
local onlr = require("onlr")

---@class pause : onlr.Component
local Pause = {}

-- The text that says the game is paused: the engine's component on the same node.
Pause.needs = { "onlr.text" }

function Pause:keypressed(key)
  if key ~= "escape" then
    return
  end
  local paused = not onlr.node.root:isPaused()
  onlr.node.root:setPaused(paused)
  self.node.components.onlr.text:setEnabled(paused)
end

return Pause
