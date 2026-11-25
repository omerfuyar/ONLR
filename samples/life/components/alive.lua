-- For the link's test (samples/link): in the preview, each loadEditor counts the components of this type that are still
-- alive, and reports the count as its error, which the preview's bounds carry (DESIGN 12.3). A view made again forgets its
-- old components, so the count stays 0 however often the file is sent.
---@class alive : onlr.Component
local Alive = {}

local alive = setmetatable({}, { __mode = "k" })

function Alive:loadEditor()
  collectgarbage("collect")
  collectgarbage("collect")
  local count = 0
  for _ in pairs(alive) do
    count = count + 1
  end
  alive[self] = true
  error(("%d alive"):format(count), 0)
end

return Alive
