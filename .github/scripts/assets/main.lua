-- Makes the samples' small assets: PNG files that LÖVE's ImageData writes, and short WAV files.
-- Run it from the repository's folder: love .github/scripts/assets
-- The files are committed, so this runs again only when an asset changes.

local function write(path, bytes)
  local file = assert(io.open(path, "wb"))
  file:write(bytes)
  file:close()
end

-- An image of one colour, drawn by a function that says which pixels are inside the shape.
local function image(path, width, height, color, inside)
  local data = love.image.newImageData(width, height)
  data:mapPixel(function(x, y)
    if not inside or inside(x + 0.5, y + 0.5) then
      return color[1], color[2], color[3], color[4] or 1
    end
    return 0, 0, 0, 0
  end)
  write(path, data:encode("png"):getString())
end

local function circle(cx, cy, radius)
  return function(x, y)
    return (x - cx) ^ 2 + (y - cy) ^ 2 <= radius ^ 2
  end
end

local function u16(n)
  return string.char(n % 256, math.floor(n / 256) % 256)
end

local function u32(n)
  return u16(n % 65536) .. u16(math.floor(n / 65536))
end

-- A WAV file of one channel, 16 bits, from a function that gives each sample from -1 to 1.
local function wav(path, seconds, wave)
  local rate = 11025
  local samples = {}
  for i = 0, math.floor(seconds * rate) - 1 do
    local value = math.max(-1, math.min(1, wave(i / rate)))
    samples[#samples + 1] = u16(math.floor(value * 32767) % 65536)
  end
  local body = table.concat(samples)
  write(path, "RIFF" .. u32(36 + #body) .. "WAVEfmt " .. u32(16) .. u16(1) .. u16(1) .. u32(rate) .. u32(rate * 2) .. u16(2) .. u16(16)
    .. "data" .. u32(#body) .. body)
end

local function tone(frequency, seconds)
  return function(t)
    return math.sin(t * frequency * 2 * math.pi) * 0.4 * math.min(1, (seconds - t) * 20)
  end
end

function love.load()
  os.execute("mkdir -p samples/properties/images samples/properties/sounds samples/coinrun/images samples/coinrun/sounds samples/speed/images samples/loading/images samples/drawing/images")

  image("samples/properties/images/dot.png", 4, 4, { 1, 0, 0 })
  wav("samples/properties/sounds/beep.wav", 0.05, tone(880, 0.05))

  image("samples/loading/images/one.png", 2, 2, { 1, 0, 0 })
  image("samples/loading/images/two.png", 2, 2, { 0, 1, 0 })
  image("samples/loading/images/three.png", 2, 2, { 0, 0, 1 })

  image("samples/drawing/images/red.png", 8, 8, { 1, 0, 0 })

  image("samples/speed/images/dot.png", 4, 4, { 1, 1, 1 }, circle(2, 2, 2))

  image("samples/coinrun/images/player.png", 32, 48, { 0.3, 0.5, 0.9 })
  image("samples/coinrun/images/shadow.png", 32, 8, { 0, 0, 0, 0.4 }, function(x, y)
    return ((x - 16) / 16) ^ 2 + ((y - 4) / 4) ^ 2 <= 1
  end)
  image("samples/coinrun/images/coin.png", 16, 16, { 1, 0.8, 0.1 }, circle(8, 8, 8))
  image("samples/coinrun/images/glint.png", 4, 4, { 1, 1, 1 }, circle(2, 2, 2))
  image("samples/coinrun/images/flag.png", 8, 12, { 0.9, 0.2, 0.2 }, function(x, y)
    return x <= 2 or y <= 6
  end)
  wav("samples/coinrun/sounds/jump.wav", 0.12, function(t)
    return math.sin(t * (400 + t * 3000) * 2 * math.pi) * 0.4 * math.min(1, (0.12 - t) * 20)
  end)
  -- The theme: four notes, which the music loops.
  wav("samples/coinrun/sounds/theme.wav", 1.2, function(t)
    local notes = { 262, 330, 392, 330 }
    local note = notes[math.floor(t / 0.3) % 4 + 1]
    return math.sin(t * note * 2 * math.pi) * 0.25 * math.min(1, (0.3 - t % 0.3) * 20)
  end)

  love.event.quit(0)
end
