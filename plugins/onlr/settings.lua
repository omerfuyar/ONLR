-- The project settings panel: the fields of the project's manifest (DESIGN 3.2). With no project open,
-- it offers New Project, Open Project and the projects opened last (DESIGN 13.2).

local ecs = require("ecs")
local ui = require("ui")
local project = require("project")
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
    ui.button("New project", { id = "new", tooltip = "Make a project in an empty folder", onClick = project.newProject }),
    ui.button("Open project", { id = "open", tooltip = "Open a project's folder", onClick = project.openProject }),
  })
  if not manifest then
    if project.folder() ~= "" then
      out[#out + 1] = ui.text(project.file("manifest.lua").error or "The manifest does not load.", { color = "error", wrap = true })
    end
    out[#out + 1] = ui.text("Opened last", { style = STYLES.heading })
    for i, folder in ipairs(project.recent()) do
      out[#out + 1] = ui.button(folder, { id = "recent" .. i, tooltip = "Open this project again", onClick = function()
        project.open(folder)
      end })
    end
  else
    local function text(field, title)
      out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
        label(title),
        ui.field(tostring(manifest[field] or ""), { id = field, grow = 1, tooltip = "Return writes it to the manifest", onSubmit = function(new)
          project.setManifest(field, new)
        end }),
      })
    end
    local function number(field, title, value, least)
      out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
        label(title),
        ui.number(value, { id = field, grow = 1, min = least, step = 1, tooltip = "Return writes it to the manifest", onSubmit = function(new)
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
        ui.dropdown(selected, choices, { id = field, grow = 1, tooltip = "A node file of the project", onSelect = function(choice)
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
        ui.toggle(window[field] == true, { id = "window." .. field, tooltip = "LÖVE's window setting of this name", onChange = function(on)
          project.setManifest("window." .. field, on or nil)
        end }),
      })
    end
    -- LÖVE draws a game at its own pixels from the window's top left, so a window that grows shows empty space: a push.screen on the
    -- top node scales the game to it (DESIGN 11.10), which one click sets up.
    local top = type(manifest.topNode) == "string" and project.file(manifest.topNode) and project.tree(manifest.topNode).first
    if top and top.components["push.screen"] then
      out[#out + 1] = ui.text("The top node's screen scales the game to the window.", { style = STYLES.note, wrap = true })
    else
      out[#out + 1] = ui.text("The game draws at its own pixels from the top left, so a larger or full screen window shows empty space "
        .. "around it. A screen on the top node scales the game to the window.", { style = STYLES.note, wrap = true })
      out[#out + 1] = ui.button("Scale to the window", { id = "scaleToWindow",
        tooltip = "Add a push.screen of the window's size to the top node, with the push package and a top node if the project lacks them",
        onClick = project.scaleToWindow })
    end
    local filter = manifest.defaultFilter == "nearest" and 2 or 1
    out[#out + 1] = ui.row({ gap = 6, align = "center" }, {
      label("Default filter"),
      ui.dropdown(filter, FILTERS, { id = "defaultFilter", grow = 1, tooltip = "How images are scaled: smooth, or nearest for pixel art", onSelect = function(choice)
        project.setManifest("defaultFilter", choice == 2 and "nearest" or nil)
      end }),
    })
    number("fixedRate", "Fixed rate", manifest.fixedRate or 60, 1)
  end
  ui.show(state.panel, surface, ui.scroll({ id = "settings", padding = 8, gap = 6 }, out))
end

local open = {} ---@type table<ecs.Panel, true> the open Project panels

ecs.panel.registerType({
  name = "settings",
  title = "Project",
  create = function(panel)
    shared.follow(panel, { "onlr.opened", "onlr.closed", "onlr.changed", "onlr.saved", "onlr.settings" })
    open[panel] = true
    return { panel = panel }
  end,
  draw = draw,
  event = function(state, event)
    ui.event(state.panel, event)
  end,
  destroy = function(state)
    open[state.panel] = nil
    shared.forget(state.panel)
    ui.forget(state.panel)
  end,
})

-- The editor that starts with no project shows the Project panel, which lists the projects opened last (DESIGN 13.2).
ecs.timer.start(0, false, function()
  if project.folder() == "" then
    shared.show("onlr.settings", open)
  end
end)

return {
  functions = {
    showProjectSettings = { sig = "void()", doc = "Show the Project panel, the project's settings", fn = function()
      shared.show("onlr.settings", open)
    end },
  },
}
