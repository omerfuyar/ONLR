-- On a checkbox: it turns an effect of the room's chain on or off.
local onlr = require("onlr")

---@class effect : onlr.Component
local Effect = {}

Effect.name = onlr.property.string("vignette", { description = "The effect's name, as moonshine.effect names it" })

function Effect:changed(checked)
  local root = onlr.tree.root
  local found = root and root.components.moonshine.effect[self.name]
  if found then
    found:setEnabled(checked)
  end
end

return Effect
