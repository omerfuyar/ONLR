-- The project settings panel: the fields of the project's manifest (DESIGN 3.2). With no project open,
-- it offers New Project, Open Project and the projects opened last (DESIGN 13.2).

local ecs = require("ecs")
local ui = require("ui")
local project = require("onlr_project")
local shared = require("shared")

local STYLES = ui.styles()
local FILTERS = { "linear", "nearest" }

local function label(text)
  return ui.text(text, { width = 110 })
end

local function draw(state, surface)
  local out = {}
  local manifest = project.folder() ~= "" and project.manifest()
  out[#out + 1] = ui.row({ gap = 8 }, {
    ui.button("New project", { id = "new", onClick = project.newProject }),
    ui.button("Open project", { id = "open", onClick = project.openProject }),
  })
  if not manifest then
    if project.folder() ~= "" then
      out[#out + 1] = ui.text(project.file("manifest.lua").error or "The manifest does not load.", { color = "#e06c75", wrap = true })
    end
    out[#out + 1] = ui.text("Opened last", { style = STYLES.heading })
    for i, folder in ipairs(project.recent()) do
      out[#out + 1] = ui.button(folder, { id = "recent" .. i, onClick = function()
        project.open(folder)
      end })
    end
  else
    local function text(field, title)
      out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
        label(title),
        ui.field(tostring(manifest[field] or ""), { id = field, grow = 1, onSubmit = function(new)
          project.setManifest(field, new)
        end }),
      })
    end
    local function number(field, title, value, least)
      out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
        label(title),
        ui.number(value, { id = field, grow = 1, min = least, step = 1, onSubmit = function(new)
          project.setManifest(field, new)
        end }),
      })
    end
    out[#out + 1] = ui.text(project.folder(), { style = STYLES.note })
    text("name", "Name")
    text("id", "Id")
    text("gameVersion", "Game version")
    -- Any node file can be the start node (DESIGN 13.3).
    local files = project.nodeFiles()
    local function nodeFile(field, title, none)
      local choices, selected = {}, 0
      if none then
        choices[1] = "(none)"
        selected = 1
      end
      for _, path in ipairs(files) do
        choices[#choices + 1] = path
        if path == manifest[field] then
          selected = #choices
        end
      end
      out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
        label(title),
        ui.dropdown(selected, choices, { id = field, grow = 1, onSelect = function(choice)
          local path = choices[choice]
          project.setManifest(field, path ~= "(none)" and path or nil)
        end }),
      })
    end
    nodeFile("startNode", "Start node", false)
    nodeFile("topNode", "Top node", true)
    local window = type(manifest.window) == "table" and manifest.window or {}
    number("window.width", "Window width", window.width or 800, 1)
    number("window.height", "Window height", window.height or 600, 1)
    for _, field in ipairs({ "resizable", "fullscreen" }) do
      out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
        label(shared.words(field)),
        ui.toggle(window[field] == true, { id = "window." .. field, onChange = function(on)
          project.setManifest("window." .. field, on or nil)
        end }),
      })
    end
    local filter = manifest.defaultFilter == "nearest" and 2 or 1
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      label("Default filter"),
      ui.dropdown(filter, FILTERS, { id = "defaultFilter", grow = 1, onSelect = function(choice)
        project.setManifest("defaultFilter", choice == 2 and "nearest" or nil)
      end }),
    })
    number("fixedRate", "Fixed rate", manifest.fixedRate or 60, 1)
  end
  ui.show(state.panel, surface, ui.scroll({ id = "settings", padding = 8, gap = 6 }, out))
end

ecs.panel.registerType({
  name = "settings",
  title = "Project",
  create = function(panel)
    shared.follow(panel)
    return { panel = panel }
  end,
  draw = draw,
  event = function(state, event)
    ui.event(state.panel, event)
  end,
  destroy = function(state)
    shared.forget(state.panel)
    ui.forget(state.panel)
  end,
})
