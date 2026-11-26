-- How the link's messages are written and read (DESIGN 12.2), which both of its ends load: the runner as one of its parts, and the
-- editor with loadfile, so the two never write a message each in its own way. It requires nothing.
-- A message is a Lua table written as text, and may carry a block of bytes after it. Each message starts with a line of two
-- numbers: the size of the text and the size of the block.

local wire = {}

-- The most that a message's first line takes: two numbers and a space and a line's end.
wire.HEADER = 48

local function escape(c)
  return ("\\%03d"):format(c:byte())
end

---Writes a value as Lua text: numbers, texts, booleans and tables of them.
---@param value any
---@return string
function wire.write(value)
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
      parts[i] = wire.write(item)
    end
    local count = #parts
    for key, item in pairs(value) do
      local isIndex = type(key) == "number" and key >= 1 and key <= count and key == math.floor(key)
      local written = not isIndex and wire.write(item)
      if written and written ~= "nil" then
        parts[#parts + 1] = "[" .. wire.write(key) .. "]=" .. written
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
function wire.pack(message, block)
  local text = wire.write(message)
  return ("%d %d\n"):format(#text, block and #block or 0) .. text .. (block or "")
end

---Reads the first line of what arrived: the sizes of the text and the block, and where the text starts; nil until the line came.
---@param head string the start of what arrived, at least HEADER bytes of it when there are so many
---@return integer? textSize
---@return integer? blockSize
---@return integer? textStart
function wire.header(head)
  local textSize, blockSize, textStart = head:match("^(%d+) (%d+)\n()")
  if not textSize then
    return nil
  end
  return tonumber(textSize), tonumber(blockSize), textStart
end

---Reads a message's text. It runs as data, with nothing but math.huge in reach.
---@param text string
---@return table?
function wire.read(text)
  local chunk = loadstring("return " .. text, "=message")
  if not chunk then
    return nil
  end
  setfenv(chunk, { math = { huge = math.huge } })
  local ok, message = pcall(chunk)
  return ok and type(message) == "table" and message or nil
end

return wire
