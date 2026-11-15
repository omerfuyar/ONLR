-- The editor's end of the link (DESIGN 12.2): a message is a Lua table written as text, and may carry a block of bytes
-- after it. Each message starts with a line of two numbers: the size of the text and the size of the block.

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

---Takes the whole messages out of what arrived.
---@param buffer string what arrived and was not read yet
---@return {[1]: table, [2]: string}[] messages each as { message, block }
---@return string rest what is left, the start of a message
function link.unpack(buffer)
  local messages = {}
  local at = 1
  while true do
    local textSize, blockSize, headerEnd = buffer:match("^(%d+) (%d+)\n()", at)
    if not textSize then
      break
    end
    textSize, blockSize = tonumber(textSize), tonumber(blockSize)
    if #buffer < headerEnd - 1 + textSize + blockSize then
      break
    end
    local text = buffer:sub(headerEnd, headerEnd + textSize - 1)
    local block = buffer:sub(headerEnd + textSize, headerEnd + textSize + blockSize - 1)
    at = headerEnd + textSize + blockSize
    -- The text runs as data, with nothing but math.huge in reach.
    local chunk = load("return " .. text, "=message", "t", { math = { huge = math.huge } })
    local ok, message = pcall(chunk or error)
    if ok and type(message) == "table" then
      messages[#messages + 1] = { message, block }
    end
  end
  return messages, buffer:sub(at)
end

return link
