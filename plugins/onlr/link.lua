-- The editor's end of the link (DESIGN 12.2): it reads the messages that arrived without copying their blocks. How a message is
-- written and read is runner/wire.lua's, which the runner's end loads too.

local ffi = require("ffi")

local link = {}

-- how a message is written and read, which the runner's end shares
local wire = assert(loadfile(require("ecs").plugin.folder .. "runner/wire.lua"))()
link.write, link.pack = wire.write, wire.pack
local HEADER = wire.HEADER

---The size of the first message of what arrived, when its first line has arrived.
---@param buf string.buffer what arrived and was not read yet
---@return integer?
function link.need(buf)
  local ptr, len = buf:ref()
  local textSize, blockSize, headerEnd = wire.header(ffi.string(ptr, math.min(len, HEADER)))
  return textSize and headerEnd - 1 + textSize + blockSize
end

-- The types of arrays of bytes, by their size, so a block's view, which OpenECS's functions take as bytes, is made without a
-- new type for each frame.
local arrays, arrayCount = {}, 0

---Takes the whole messages out of what arrived, and gives each to handle. A message's block is given where it lies in buf,
---without a copy, as an array of bytes, so it is read during handle only, which must not change buf.
---@param buf string.buffer what arrived and was not read yet; what is left is the start of a message
---@param handle fun(message: table, block: ffi.cdata*?, size: integer)
function link.unpack(buf, handle)
  while true do
    local ptr, len = buf:ref()
    local textSize, blockSize, headerEnd = wire.header(ffi.string(ptr, math.min(len, HEADER)))
    if not textSize or not blockSize or not headerEnd then
      return
    end
    local total = headerEnd - 1 + textSize + blockSize
    if len < total then
      return
    end
    local text = ffi.string(ptr + headerEnd - 1, textSize)
    local message = wire.read(text)
    if message then
      local block
      if blockSize > 0 then
        local array = arrays[blockSize]
        if not array then
          array = ffi.typeof("uint8_t(*)[$]", blockSize)
          -- a view's size changes rarely, so few types are kept
          if arrayCount >= 8 then
            arrays, arrayCount = {}, 0
          end
          arrays[blockSize], arrayCount = array, arrayCount + 1
        end
        block = ffi.cast(array, ptr + headerEnd - 1 + textSize)[0]
      end
      handle(message, block, blockSize)
    end
    buf:skip(total)
  end
end

return link
