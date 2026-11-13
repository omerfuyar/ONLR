-- The editor's side of the link, for the test: it listens on a free port of 127.0.0.1, starts a player,
-- and sends and reads messages as DESIGN 12.2 says.
local socket = require("socket")

local editor = {}

-- The repository's folder, and LÖVE's executable, which test.sh names in LOVE.
local root = love.filesystem.getSource() .. "/../.."
local love2d = os.getenv("LOVE") or "love"

local function escape(c)
  return ("\\%03d"):format(c:byte())
end

local function write(value)
  local kind = type(value)
  if kind == "string" then
    return '"' .. value:gsub('[%c"\\]', escape) .. '"'
  elseif kind == "table" then
    local parts = {}
    for key, item in pairs(value) do
      parts[#parts + 1] = "[" .. write(key) .. "]=" .. write(item)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return tostring(value)
end

---Starts a player on a sample, and waits for it to connect.
---@param sample string such as "coinrun"
---@param mode "edit"|"play"
---@param more string? more arguments
---@return table player with send, receive, expect and stopped
function editor.start(sample, mode, more)
  local server = assert(socket.bind("127.0.0.1", 0))
  local _, port = server:getsockname()
  local log = os.tmpname()
  -- timeout ends a player that the test leaves behind, such as one that shows an error.
  os.execute(("timeout 60 %q %q --onlr-player=%q --onlr-mode=%s --onlr-port=%d %s > %q 2>&1 &"):format(
    love2d, root .. "/samples/" .. sample, root .. "/player", mode, port, more or "", log))
  server:settimeout(10)
  local connection = assert(server:accept(), "the player did not connect")
  server:close()
  connection:settimeout(0)

  local player = { log = log }
  local buffer = ""

  function player.send(message)
    local text = write(message)
    connection:settimeout(5)
    connection:send(("%d 0\n"):format(#text) .. text)
    connection:settimeout(0)
  end

  -- Reads one message, waiting at most some seconds. Gives the message and its block of bytes, or nil.
  function player.receive(seconds)
    local deadline = socket.gettime() + (seconds or 5)
    while true do
      local textSize, blockSize, headerEnd = buffer:match("^(%d+) (%d+)\n()")
      if textSize and #buffer >= headerEnd - 1 + textSize + blockSize then
        local text = buffer:sub(headerEnd, headerEnd + textSize - 1)
        local block = buffer:sub(headerEnd + textSize, headerEnd + textSize + blockSize - 1)
        buffer = buffer:sub(headerEnd + textSize + blockSize)
        local chunk = assert(loadstring("return " .. text))
        setfenv(chunk, { math = { huge = math.huge } })
        return chunk(), block
      end
      local left = deadline - socket.gettime()
      if left <= 0 then
        return nil
      end
      socket.select({ connection }, nil, left)
      local bytes, err, partial = connection:receive(1048576)
      bytes = bytes or partial
      if bytes and #bytes > 0 then
        buffer = buffer .. bytes
      elseif err == "closed" then
        player.closed = true
        return nil
      end
    end
  end

  -- Reads messages until one of a type arrives, and gives it. The others are dropped.
  function player.expect(kind, seconds)
    local deadline = socket.gettime() + (seconds or 5)
    while socket.gettime() < deadline do
      local message, block = player.receive(deadline - socket.gettime())
      if not message then
        return nil
      end
      if message.type == kind then
        return message, block
      end
    end
  end

  -- Whether the player closed the link, which it does when it ends.
  function player.stopped(seconds)
    local deadline = socket.gettime() + (seconds or 5)
    while not player.closed and socket.gettime() < deadline do
      player.receive(0.1)
    end
    return player.closed == true
  end

  -- What the player printed.
  function player.printed()
    local file = io.open(log)
    local text = file and file:read("*a") or ""
    if file then
      file:close()
    end
    return text
  end

  return player
end

return editor
