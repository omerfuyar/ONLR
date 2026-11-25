-- The editor's end of the link (DESIGN 12.2): a message is a Lua table written as text, and may carry a block of bytes
-- after it. Each message starts with a line of two numbers: the size of the text and the size of the block.

local ffi = require("ffi")

local link = {}

local function escape(c)
  return ("\\%03d"):format(c:byte())
end

---Writes a value as Lua text: numbers, texts, booleans and tables of them.
---@param value any
---@return string
function link.write(value)
  local kind = type(value)
  if kind == "number" then
    if value ~= value then
      return "0/0"
    elseif value == math.huge then
      return "math.huge"
    elseif value == -math.huge then
      return "-math.huge"
    elseif value == math.floor(value) and math.abs(value) < 2 ^ 53 then
      return ("%.0f"):format(value)
    end
    return ("%.17g"):format(value)
  elseif kind == "string" then
    return '"' .. value:gsub('[%c"\\]', escape) .. '"'
  elseif kind == "boolean" then
    return tostring(value)
  elseif kind == "table" then
    local parts = {}
    for i, item in ipairs(value) do
      parts[i] = link.write(item)
    end
    local count = #parts
    for key, item in pairs(value) do
      local isIndex = type(key) == "number" and key >= 1 and key <= count and key == math.floor(key)
      local written = not isIndex and link.write(item)
      if written and written ~= "nil" then
        parts[#parts + 1] = "[" .. link.write(key) .. "]=" .. written
      end
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "nil"
end

---A message as the bytes that are sent.
---@param message table
---@param block string?
---@return string
function link.pack(message, block)
  local text = link.write(message)
  return ("%d %d\n"):format(#text, block and #block or 0) .. text .. (block or "")
end

-- The most that a message's first line takes: two numbers and a space and a line's end.
local HEADER = 48

---The size of the first message of what arrived, when its first line has arrived.
---@param buf string.buffer what arrived and was not read yet
---@return integer?
function link.need(buf)
  local ptr, len = buf:ref()
  local textSize, blockSize, headerEnd = ffi.string(ptr, math.min(len, HEADER)):match("^(%d+) (%d+)\n()")
  return textSize and headerEnd - 1 + tonumber(textSize) + tonumber(blockSize)
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
    local textSize, blockSize, headerEnd = ffi.string(ptr, math.min(len, HEADER)):match("^(%d+) (%d+)\n()")
    if not textSize then
      return
    end
    textSize, blockSize = tonumber(textSize) --[[@as integer]], tonumber(blockSize) --[[@as integer]]
    local total = headerEnd - 1 + textSize + blockSize
    if len < total then
      return
    end
    local text = ffi.string(ptr + headerEnd - 1, textSize)
    -- The text runs as data, with nothing but math.huge in reach.
    local chunk = load("return " .. text, "=message", "t", { math = { huge = math.huge } })
    local ok, message = pcall(chunk or error)
    if ok and type(message) == "table" then
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
