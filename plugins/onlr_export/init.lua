-- Export (DESIGN 14): the .love file, and the builds, which are made from it and LÖVE's runtime by copying and joining files.

local ecs = require("ecs")
local ui = require("ui")
local fs = require("fs")
local compress = require("compress")
local project = require("onlr_project")
local console = require("console")
local runtimes = require("runtimes")
local tar = require("tar")

local STYLES = ui.styles()

local panels = {} ---@type table<ecs.Panel, table>
local status = "" -- what the last export did

local function say(text, isError)
  status = text
  console.add(text, isError and "error" or "info")
  for panel in pairs(panels) do
    panel:redraw()
  end
end

local function read(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end
  local data = file:read("a")
  file:close()
  return data
end

local function write(path, data)
  local file = io.open(path, "wb")
  if not file then
    return false
  end
  file:write(data)
  file:close()
  return true
end

-- A pattern of the manifest's exclude as a Lua pattern: * stands for any part of a name, ** for any folders,
-- and a pattern that ends with / names a folder (DESIGN 3.2). A pattern names a path from the project's folder.
local function luaPattern(pattern)
  local folder = pattern:sub(-1) == "/"
  local out = pattern:gsub("[%^%$%(%)%%%.%[%]%+%-%?]", "%%%0"):gsub("%*%*/?", "\1"):gsub("%*", "[^/]*"):gsub("\1", ".*")
  return "^" .. out .. (folder and "" or "$")
end

---The export's folder, ending with a slash: the one that the user chose, which the editor keeps for the project.
---A path that does not start at a root is in the project's folder.
---@return string? folder nil when none is chosen
local function exportFolder()
  local folder = project.setting("exportFolder")
  if type(folder) ~= "string" or folder == "" then
    return nil
  end
  folder = folder:gsub("\\", "/")
  if not folder:match("^/") and not folder:match("^%a:/") then
    folder = project.folder() .. folder
  end
  if folder:sub(-1) ~= "/" then
    folder = folder .. "/"
  end
  return folder
end

-- The game's name as a file's name.
local function fileName()
  local manifest = project.manifest() or {}
  local name = tostring(manifest.name or "game"):gsub('[<>:"/\\|%?%*%c]', ""):gsub("^%s+", ""):gsub("%s+$", "")
  return name ~= "" and name or "game"
end

---The files that an export holds: every file of the project, apart from those whose name starts with a dot, what exclude
---in the manifest names, and the export's folder when it is inside the project (DESIGN 14.1).
---@return {name: string, data: string}[] files in the order of their names
local function collect()
  local root = project.folder()
  local manifest = project.manifest() or {}
  local patterns = {}
  for _, pattern in ipairs(type(manifest.exclude) == "table" and manifest.exclude or {}) do
    patterns[#patterns + 1] = luaPattern(tostring(pattern))
  end
  local out = exportFolder()
  local skip = out and out:sub(1, #root) == root and out:sub(#root + 1) or nil
  local files = {}
  local function excluded(path)
    for _, pattern in ipairs(patterns) do
      if path:match(pattern) then
        return true
      end
    end
    return false
  end
  local function walk(dir)
    for _, entry in ipairs(fs.list(root .. dir, "") or {}) do
      local path = dir .. entry.name
      if entry.name:sub(1, 1) ~= "." then
        if entry.type == "folder" then
          if path .. "/" ~= skip and not excluded(path .. "/") then
            walk(path .. "/")
          end
        elseif not excluded(path) then
          files[#files + 1] = { name = path, data = read(root .. path) or "" }
        end
      end
    end
  end
  walk("")
  table.sort(files, function(a, b)
    return a.name < b.name
  end)
  return files
end

-- Makes ready for an export: saves the project, and gives the export's folder.
local function prepare()
  if project.folder() == "" then
    say("No project is open.", true)
    return nil
  end
  local folder = exportFolder()
  if not folder then
    say("Choose the folder that exports are written to first.", true)
    return nil
  end
  if not project.saveAll() then
    say("The project is not saved, so nothing is exported.", true)
    return nil
  end
  fs.makeFolder(folder)
  return folder
end

---Writes the .love file: a zip archive of the project's folder, with main.lua at its root (DESIGN 14.1).
---@return string? path the .love file
local function exportLove()
  local folder = prepare()
  if not folder then
    return nil
  end
  local path = folder .. fileName() .. ".love"
  local ok, err = compress.zip.write(path, collect(), 0)
  if not ok then
    say("The .love file was not written: " .. tostring(err), true)
    return nil
  end
  say("Wrote " .. path)
  return path
end

-- The files of a runtime's folder, by their paths in it.
local function runtimeFiles(folder)
  local files = {}
  local function walk(dir)
    for _, entry in ipairs(fs.list(folder .. dir, "") or {}) do
      if entry.name:sub(1, 1) ~= "." then
        if entry.type == "folder" then
          walk(dir .. entry.name .. "/")
        elseif entry.type == "file" then
          files[#files + 1] = dir .. entry.name
        end
      end
    end
  end
  walk("")
  table.sort(files)
  return files
end

---Makes the Linux build: LÖVE's files, with the .love file joined to the end of LÖVE's executable, in a .tar.gz archive,
---and a launcher named after the game (DESIGN 14.2).
local function exportLinux()
  local love = exportLove()
  if not love then
    return
  end
  local out = love:match("^(.*/)")
  runtimes.get("linux-x86_64", function(runtime, message)
    if not runtime then
      return say(message or "LÖVE's runtime for Linux is missing.", true)
    end
    local name = fileName()
    local files = { { name = name .. "/" } }
    local folders = {}
    for _, path in ipairs(runtimeFiles(runtime)) do
      local data = read(runtime .. path) or ""
      local target = path
      local executable = path:match("^bin/") ~= nil or path:match("%.so") ~= nil
      if path == "bin/love" then
        -- LÖVE runs a .love file that is joined to the end of its executable.
        data = data .. (read(love) or "")
      elseif path == "AppRun" then
        -- LÖVE's own launcher sets where its libraries are, and starts bin/love: the build names it after the game.
        target, executable = name, true
      end
      local dir = target:match("^(.*/)")
      if dir and not folders[dir] then
        -- each folder above the file, the outer ones first
        local at = ""
        for part in dir:gmatch("[^/]+/") do
          at = at .. part
          if not folders[at] then
            folders[at] = true
            files[#files + 1] = { name = name .. "/" .. at }
          end
        end
      end
      files[#files + 1] = { name = name .. "/" .. target, data = data, executable = executable }
    end
    local packed, err = compress.gzip.pack(tar.pack(files), 0)
    local path = out .. name .. "-linux-x86_64.tar.gz"
    if not packed or not write(path, packed) then
      return say("The Linux build was not written: " .. tostring(err), true)
    end
    say("Wrote " .. path)
  end)
end

---Makes the Windows build: love.exe with the .love file joined to its end, named after the game, beside LÖVE's libraries,
---in a zip archive (DESIGN 14.2).
local function exportWindows()
  local love = exportLove()
  if not love then
    return
  end
  local out = love:match("^(.*/)")
  say("Getting LÖVE's runtime for Windows.")
  runtimes.get("windows-x86_64", function(runtime, message)
    if not runtime then
      return say(message or "LÖVE's runtime for Windows is missing.", true)
    end
    local name = fileName()
    local files = {}
    for _, path in ipairs(runtimeFiles(runtime)) do
      local lower = path:lower()
      if lower == "love.exe" then
        files[#files + 1] = { name = name .. "/" .. name .. ".exe", data = (read(runtime .. path) or "") .. (read(love) or "") }
      elseif lower:match("%.dll$") or lower == "license.txt" then
        -- LÖVE's libraries, and its license.txt, which lists the licences of LÖVE and of the libraries inside it.
        files[#files + 1] = { name = name .. "/" .. path, data = read(runtime .. path) or "" }
      end
    end
    local path = out .. name .. "-windows-x86_64.zip"
    local ok, err = compress.zip.write(path, files, 0)
    if not ok then
      return say("The Windows build was not written: " .. tostring(err), true)
    end
    say("Wrote " .. path)
  end)
end

local function chooseFolder()
  ecs.dialog.show({ type = "openFolder", location = exportFolder() or project.folder() }, function(files)
    if files and files[1] then
      project.setSetting("exportFolder", files[1])
    end
  end)
end

ecs.panel.registerType({
  name = "panel",
  title = "Export",
  create = function(panel)
    local state = { panel = panel }
    panels[panel] = state
    return state
  end,
  draw = function(state, surface)
    local children = {}
    if project.folder() == "" then
      children[1] = ui.text("No project is open.", { style = STYLES.note })
    else
      children = {
        ui.text("The folder that exports are written to", { style = STYLES.heading }),
        ui.row({ gap = 6 }, {
          ui.field(tostring(project.setting("exportFolder") or ""), { id = "folder", grow = 1, onSubmit = function(text)
            project.setSetting("exportFolder", text)
          end }),
          ui.button("Choose", { id = "choose", onClick = chooseFolder }),
        }),
        ui.button("Export the .love file", { id = "love", onClick = exportLove }),
        ui.button("Export a Linux build", { id = "linux", onClick = exportLinux }),
        ui.button("Export a Windows build", { id = "windows", onClick = exportWindows }),
        ui.text(status, { wrap = true }),
      }
    end
    ui.show(state.panel, surface, ui.column({ padding = 8, gap = 8 }, children))
  end,
  event = function(state, event)
    ui.event(state.panel, event)
  end,
  destroy = function(state)
    ui.forget(state.panel)
    panels[state.panel] = nil
  end,
})

for _, name in ipairs({ "onlr_project.opened", "onlr_project.closed", "onlr_project.settings" }) do
  ecs.event.subscribe(name, function()
    for panel in pairs(panels) do
      panel:redraw()
    end
  end)
end

ecs.service.register({
  love = { sig = "void()", doc = "Export the .love file", fn = function()
    exportLove()
  end },
  linux = { sig = "void()", doc = "Export a Linux build", fn = exportLinux },
  windows = { sig = "void()", doc = "Export a Windows build", fn = exportWindows },
  chooseFolder = { sig = "void()", doc = "Choose the folder that exports are written to", fn = chooseFolder },
})
