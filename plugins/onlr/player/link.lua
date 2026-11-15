-- The link (DESIGN 12.2): a TCP connection on this computer between the editor, which listens, and a player.
-- A message is a Lua table written as text, and may carry a block of bytes after it, such as a frame's pixels.
-- Each message starts with a line of two numbers: the size of the text and the size of the block.

local socket = require("socket")

local link = {}

---@type table? the connection, LuaSocket's
local connection
local buffer = ""

---Whether the editor closed the link, or it never opened.
link.closed = true

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
      return ("%d"):format(value)
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

---Reads a message's text. It runs as data, with nothing but math.huge in reach.
---@param text string
---@return table?
function link.read(text)
  local chunk = loadstring("return " .. text, "=message")
  if not chunk then
    return nil
  end
  setfenv(chunk, { math = { huge = math.huge } })
  local ok, message = pcall(chunk)
  return ok and type(message) == "table" and message or nil
end

---Connects to the editor, which listens on a port of this computer.
---@param port integer
---@return boolean ok
function link.connect(port)
  local c = socket.tcp()
  c:settimeout(5)
  if not c:connect("127.0.0.1", port) then
    return false
  end
  c:setoption("tcp-nodelay", true)
  c:settimeout(0)
  connection = c
  link.closed = false
  return true
end

---Sends a message, and a block of bytes after it when one is given.
---@param message table
---@param block string?
function link.send(message, block)
  if not connection then
    return
  end
  local text = link.write(message)
  local bytes = ("%d %d\n"):format(#text, block and #block or 0) .. text .. (block or "")
  connection:settimeout(5)
  local sent, err = connection:send(bytes)
  connection:settimeout(0)
  if not sent and err == "closed" then
    link.closed = true
  end
end

---Gives the messages that arrived, each as { message, block }, without waiting.
---@return {[1]: table, [2]: string}[]
function link.poll()
  local messages = {}
  if not connection then
    return messages
  end
  while true do
    local bytes, err, partial = connection:receive(65536)
    bytes = bytes or partial
    if bytes and #bytes > 0 then
      buffer = buffer .. bytes
    end
    if err == "closed" then
      link.closed = true
    end
    if err or not bytes or #bytes == 0 then
      break
    end
  end
  while true do
    local textSize, blockSize, headerEnd = buffer:match("^(%d+) (%d+)\n()")
    if not textSize then
      break
    end
    textSize, blockSize = tonumber(textSize), tonumber(blockSize)
    if #buffer < headerEnd - 1 + textSize + blockSize then
      break
    end
    local text = buffer:sub(headerEnd, headerEnd + textSize - 1)
    local block = buffer:sub(headerEnd + textSize, headerEnd + textSize + blockSize - 1)
    buffer = buffer:sub(headerEnd + textSize + blockSize)
    local message = link.read(text)
    if message then
      messages[#messages + 1] = { message, block }
    end
  end
  return messages
end

---Waits until a message may have arrived, at most some seconds.
---@param seconds number
function link.wait(seconds)
  if connection and not link.closed then
    socket.select({ connection }, nil, seconds)
  else
    socket.sleep(seconds)
  end
end

return link
