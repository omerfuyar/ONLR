-- A writer of tar archives, in the ustar format, for the Linux build's .tar.gz (DESIGN 14.2).
-- It stands in until OpenECS-std's compress writes tar.

local tar = {}

local function octal(n, width)
  return ("%0" .. (width - 1) .. "o"):format(n) .. "\0"
end

local function pad(text, width)
  return text .. ("\0"):rep(width - #text)
end

-- One entry's header: 512 bytes.
local function header(name, size, mode, kind, time)
  local prefix = ""
  if #name > 100 then
    -- A long name is split at a slash into a prefix and a name.
    local at = name:find("/", #name - 100, true)
    if not at or at - 1 > 155 then
      error("the name is too long for a tar archive: " .. name, 0)
    end
    prefix, name = name:sub(1, at - 1), name:sub(at + 1)
  end
  local fields = {
    pad(name, 100), octal(mode, 8), octal(0, 8), octal(0, 8), octal(size, 12), octal(time, 12),
    "        ", kind, pad("", 100), "ustar\0", "00", pad("", 32), pad("", 32), octal(0, 8), octal(0, 8), pad(prefix, 155), pad("", 12),
  }
  local block = table.concat(fields)
  local sum = 0
  for i = 1, #block do
    sum = sum + block:byte(i)
  end
  fields[7] = ("%06o"):format(sum) .. "\0 "
  return table.concat(fields)
end

---A tar archive's bytes.
---@param files {name: string, data: string?, executable: boolean?}[] each file's name and what it holds; a name that ends with / is a folder
---@return string
function tar.pack(files)
  local time = os.time()
  local out = {}
  for _, file in ipairs(files) do
    if file.name:sub(-1) == "/" then
      out[#out + 1] = header(file.name, 0, 493, "5", time)
    else
      local data = file.data or ""
      out[#out + 1] = header(file.name, #data, file.executable and 493 or 420, "0", time)
      out[#out + 1] = data
      out[#out + 1] = ("\0"):rep((512 - #data % 512) % 512)
    end
  end
  out[#out + 1] = ("\0"):rep(1024)
  return table.concat(out)
end

return tar
