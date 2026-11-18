-- The gallery's script, on the top node: the rooms are the node files of a folder, in the order of their names, and
-- Page Up, Page Down or the bar's buttons load the room before or after as the root. A new room is a new file there.
local onlr = require("onlr")

---@class gallery : onlr.Component
---@field rooms string[]
---@field index integer
local Gallery = {}

Gallery.folder = onlr.property.string("nodes/rooms", { description = "The folder of the rooms' node files" })
Gallery.title = onlr.property.component("suit.label", { description = "The label that shows the room's title" })
Gallery.about = onlr.property.component("suit.label", { description = "The label that shows what the room shows" })

function Gallery:load()
  self.rooms = {}
  for _, name in ipairs(love.filesystem.getDirectoryItems(self.folder)) do
    if name:match("%.lua$") then
      self.rooms[#self.rooms + 1] = self.folder .. "/" .. name
    end
  end
  table.sort(self.rooms)
  self.index = 1
end

-- Loads the room a step away: 1 is the next, -1 the one before. The ends go round.
---@param step integer
function Gallery:go(step)
  self.index = (self.index - 1 + step) % #self.rooms + 1
  onlr.tree.loadRoot(self.rooms[self.index])
end

function Gallery:keypressed(key)
  if key == "pagedown" then
    self:go(1)
  elseif key == "pageup" then
    self:go(-1)
  end
end

-- The bar shows the room's own title and text, which its root's room component holds.
function Gallery:lateUpdate()
  local root = onlr.tree.root
  local room = root and root.components.room
  if self.title then
    self.title.text = ("%d of %d   %s"):format(self.index, #self.rooms, room and room.title or root and root.name or "")
  end
  if self.about then
    self.about.text = room and room.about or ""
  end
end

return Gallery
