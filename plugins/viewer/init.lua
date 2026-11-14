-- The asset viewer: it shows a file as what it is, with the standard loaders: an image with image, through ui,
-- a sound with audio and mixer, and a text with syntax.

local ecs = require("ecs")
local ui = require("ui")
local fs = require("fs")
local audio = require("audio")
local mixer = require("mixer")
local syntax = require("syntax")

local STYLES = ui.styles()
local STATE_VERSION = 1
local IMAGES = { png = true, jpg = true, jpeg = true, bmp = true, tga = true, gif = true, webp = true }
local SOUNDS = { wav = true, ogg = true, mp3 = true, flac = true }
local COLORS = {
  keyword = "#c678dd", string = "#98c379", comment = "#7f848e", number = "#d19a66", ["function"] = "#61afef",
  type = "#e5c07b", constant = "#d19a66",
}
-- A text of more lines shows its start only.
local LINES = 2000

local panels = {} ---@type table<ecs.Panel, table>

local function kindOf(path)
  local ending = (path:match("%.(%w+)$") or ""):lower()
  return IMAGES[ending] and "image" or SOUNDS[ending] and "sound" or "text"
end

-- A text's lines as spans in the colours of its language.
local function textLines(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end
  local text = file:read(1024 * 1024) or ""
  file:close()
  if text:find("\0", 1, true) then
    return nil
  end
  local language = syntax.languageOf(path)
  local ranges = language and syntax.highlight(language, text) or {}
  local lines, spans = {}, {}
  local at, r = 1, 1
  local function add(first, last, color)
    -- A piece may run over line ends: each line gets its part.
    local piece = text:sub(first, last)
    local from = 1
    while true do
      local stop = piece:find("\n", from, true)
      local part = piece:sub(from, (stop or #piece + 1) - 1):gsub("\r", ""):gsub("\t", "  ")
      if part ~= "" then
        spans[#spans + 1] = { text = part, color = color }
      end
      if not stop then
        break
      end
      lines[#lines + 1] = spans
      spans = {}
      from = stop + 1
    end
  end
  while at <= #text and #lines < LINES do
    local range = ranges[r]
    if range and range.start <= at then
      add(at, range.stop, COLORS[range.kind])
      at, r = range.stop + 1, r + 1
    else
      local stop = range and range.start - 1 or #text
      add(at, stop)
      at = stop + 1
    end
  end
  lines[#lines + 1] = spans
  return lines
end

local function load(state, path)
  if state.voice then
    mixer.stop(state.voice)
  end
  state.path, state.kind, state.lines, state.sound, state.voice, state.error = path, nil, nil, nil, nil, nil
  state.panel.title = path and path:match("[^/\\]*$") or "Viewer"
  if not path then
    return
  end
  local info = fs.info(path)
  if not info or info.type ~= "file" then
    state.error = "No such file."
    return
  end
  state.kind = kindOf(path)
  state.size = info.size
  if state.kind == "sound" then
    local sound, err = audio.load(path)
    state.sound, state.error = sound, not sound and tostring(err) or nil
  elseif state.kind == "text" then
    state.lines = textLines(path)
    if not state.lines then
      state.kind = "other"
    end
  end
  state.panel:redraw()
end

local function draw(state, surface)
  local children = {}
  if not state.path then
    children[1] = ui.text("No file is open.", { style = STYLES.note })
  else
    children[#children + 1] = ui.text(("%s, %d bytes"):format(state.path, state.size or 0), { style = STYLES.note })
    if state.error then
      children[#children + 1] = ui.text(state.error, { color = "#e06c75", wrap = true })
    elseif state.kind == "image" then
      children[#children + 1] = ui.scroll({ id = "image" }, { ui.image(state.path, {}) })
    elseif state.kind == "sound" then
      children[#children + 1] = ui.row({ gap = 8, align = "center" }, {
        ui.button("Play", { id = "play", onClick = function()
          if state.voice then
            mixer.stop(state.voice)
          end
          state.voice = state.sound:play(1, false)
        end }),
        ui.button("Stop", { id = "stop", onClick = function()
          if state.voice then
            mixer.stop(state.voice)
            state.voice = nil
          end
        end }),
        ui.text(("%.2f seconds"):format(state.sound:length()), {}),
      })
    elseif state.kind == "text" then
      local items = {}
      for i, spans in ipairs(state.lines) do
        items[i] = ui.text(#spans > 0 and spans or " ", { font = "mono" })
      end
      children[#children + 1] = ui.scroll({ id = "text" }, items)
    else
      children[#children + 1] = ui.text("The viewer shows images, sounds and texts.", { style = STYLES.note })
    end
  end
  ui.show(state.panel, surface, ui.column({ padding = 8, gap = 6 }, children))
end

ecs.panel.registerType({
  name = "file",
  title = "Viewer",
  stateVersion = STATE_VERSION,
  create = function(panel, saved, version)
    local state = { panel = panel }
    panels[panel] = state
    if version == STATE_VERSION and type(saved) == "table" and saved.path then
      load(state, saved.path)
    end
    return state
  end,
  draw = draw,
  event = function(state, event)
    ui.event(state.panel, event)
  end,
  saveState = function(state)
    return { path = state.path }
  end,
  destroy = function(state)
    if state.voice then
      mixer.stop(state.voice)
    end
    ui.forget(state.panel)
    panels[state.panel] = nil
  end,
})

ecs.service.register({
  open = { sig = "void(string path)", doc = "Show a file in a viewer: the one that shows it, the first one open, or a new one", fn = function(path)
    local free
    for panel, state in pairs(panels) do
      if state.path == path then
        load(state, path)
        ecs.layout.focus(panel)
        return
      end
      free = free or state
    end
    if free then
      load(free, path)
      ecs.layout.focus(free.panel)
    else
      ecs.layout.open("viewer.file", { path = path })
    end
  end },
  reload = { sig = "void(string path)", doc = "Read a file again in the viewers that show it", fn = function(path)
    for _, state in pairs(panels) do
      if state.path == path then
        load(state, path)
      end
    end
  end },
})
