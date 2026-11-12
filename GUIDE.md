# Making a tool with OpenECS

This guide goes through the template, one part at a time, and ends with what you need to make your own tool with it. The template's tool is a board of notes beside a small panel in C. Each file has comments that explain what OpenECS does with it.

## 1. What you need

- **OpenECS.** Download the archive from [OpenECS's releases](https://github.com/omerfuyar/OpenECS/releases) or build it from source.
- **A C compiler**, for plugins in C: any C23 compatible one. See `Development Dependencies` of [OpenECS readme](https://github.com/omerfuyar/OpenECS/blob/dev/README.md).
- **An editor with the Lua language server**, such as VS Code with the Lua extension, for completion and checks. Not mandatory of course, for convenience.

## 2. Run the tool

``` shell
git submodule update --init                  # gets shu and shuild, which shuild.c uses
cc shuild.c -o shuild && ./shuild            # builds the plugin in C
OpenECS/OpenECS --fresh --preset preset.lua
```

On Windows, with LLVM-MinGW's clang: `clang shuild.c -o shuild.exe` and `.\shuild.exe`, then `OpenECS\OpenECS.exe --fresh --preset preset.lua`.

`--fresh` starts from the preset each time. Without it, a tool starts from its last saved session. It can be saved manually by the user or automatically if the setting `ecs.keepSession` is on.

Type a note and press Return, or Add. Click a note to choose it; Delete or Remove takes it away. Drag a tab to move a panel: beside another, into its tab row, or out of the window.

Every key of OpenECS starts with Alt+W by default. Press it to see the list.

## 3. Project structure

| Path               | What it holds                                                                     |
| ------------------ | --------------------------------------------------------------------------------- |
| `preset.lua`       | The tool: its name, its plugins, its settings and keys, and where panels go.      |
| `plugins/notes/`   | A plugin in Lua: `manifest.lua` and `init.lua`.                                   |
| `plugins/pulse_c/` | A plugin in C: `manifest.lua` and `Pulse.c`, which `shuild.c` builds.             |
| `test.lua`         | A test of the tool (14).                                                          |
| `shuild.c`         | Builds the plugins in C (12).                                                     |
| `dependencies/`    | shu and shuild, as git submodules, which `shuild.c` builds with.                  |
| `.luarc.json`      | Tells your editor where OpenECS's definitions are (13).                           |
| `.github/`         | Checks that run on each pull request, and the rules of the repository's branches. |

## 4. The preset

A preset is a Lua file that returns a table. OpenECS reads it as data: it can use Lua's loops and conditions, but can't call plugins.

- There are required and optional fields. OpenECS checks every field when it reads the file; a missing, unknown or wrong field stops the start, and the message names the field, such as `workspaces[1].windows[1][2].size`.
- `app.id` names the tool everywhere: its saved session, its part of the user's settings file, and its desktop file. Use a reversed domain, such as `org.example.MyTool`. `app.name` is the window's title.
- `depends` names each plugin and the lowest version it accepts: `"0.1"` accepts 0.1.0 and later, below 1.0.0.
- `pluginsDir` is a folder, relative to the preset, where plugins are looked for first. Then OpenECS looks in the user's plugins and its own.
- `settings` sets settings for this tool, and `keys` adds keys (9).
- `workspaces` is a list of named arrangements of panels. Each holds `windows`, one layout tree for each OS window: the main window first, then any pop-out windows. A tree's node is either a group, `{ panels = { ... } }`, whose panels are tabs, or a split, `{ split = "horizontal", child, child }`. A split's child has a `share` of the room, or a fixed `size` in layout units.
- `format` is the version of the file's format, which OpenECS checks.
- `open` names a function that gets each file of the command line, such as `OpenECS/OpenECS --preset preset.lua notes.txt`.

## 5. A plugin

A plugin is a folder with a manifest and its code. `plugins/notes/manifest.lua`:

- `name` is the folder's name. `version` is the plugin's own, and `api` the version of OpenECS's plugin interface it was written for.
- `type` is `"lua"`, for code that starts in `init.lua`, or `"native"`, for a library built with C.
- `depends` names the plugins it uses. They load first.

When OpenECS loads the plugin, `init.lua` or `ECSPlugin_Init` runs once. They register everything the plugin offers like panel types, settings, functions and events.

Everything declared by plugins is named. OpenECS adds the plugin's name: the panel type `"board"` of the plugin `notes` is `notes.board`. Everything that names something, takes the full name: presets, key bindings, lookups and events.

## 6. Panels

A panel type is a table of functions that OpenECS calls; each panel of the type has its own state, the value `create` gives:

| Function                        | OpenECS calls it                                                                   |
| ------------------------------- | ---------------------------------------------------------------------------------- |
| `create(panel, saved, version)` | When a panel opens. `saved` is what `saveState` gave in the saved session, or nil. |
| `draw(state, surface, seconds)` | When the panel is shown, resized, or asked with `panel:redraw()`.                  |
| `event(state, event)`           | For each pointer, key, text, focus or drop event of the panel.                     |
| `saveState(state)`              | When the session is saved.                                                         |
| `destroy(state)`                | When the panel closes.                                                             |

- A panel handle has fields: `panel.title`, which sets its tab's title, `panel.unsaved`, which marks unsaved work and asks before closing, `panel.id` and `panel.type`. Its methods do things: `panel:redraw()`, etc.

## 7. Drawing

A panel draws into its surface: pixels that OpenECS shows. Sizes in plugins are in layout units, which follow the screen's scale; `surface.width / surface.scale` is the panel's width in layout units.

- A panel type with `continuous = true` draws every frame while it shows. Draws on demand if not.
- `surface:fill(x, y, width, height, color)` fills pixels. Colours are texts: `"#RRGGBB"`, `"#RRGGBBAA"`, or a colour of the theme, such as `"background"`, `"text"` or `"accent"`, which follow the current theme; dark, light or custom.
- The **draw** plugin draws shapes, images and text: `draw.fill`, `draw.line`, `draw.circle`, `draw.text` and more.
- The **ui** plugin builds interfaces on draw. The board describes its elements each time it draws, and `ui.show` lays them out and draws them; `ui.event` gives the board's events to them. Its elements: columns, rows, lists, separators, text, buttons, sliders, toggles etc.
- Plugins that read files give draw what to draw: **image** reads images, and **gltf** 3D models.

[OpenECS-std's design](https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md) describes every standard plugin.

## 8. Settings

- `ecs.setting.declare({ name = "newestFirst", type = "bool", default = true, description = "...", changed = fn })` declares `notes.newestFirst`. Types: `bool`, `integer`, `number`, `string`, `choice`, `key`, `color`, `list` and `table`.
- `ecs.setting.get("notes.newestFirst")` gives the value in effect: from the user's settings file, its part for this tool first; else from the preset's `settings`; else the default. Colours have one more layer before the default: the theme, dark or light.
- The settings window lists every setting with its description, and writes the user's file. `changed` runs when the value in effect changes, wherever the change comes from.

## 9. Functions and keys

- `ecs.service.register({ remove = { sig = "void(handle<ecs.panel> panel)", doc = "...", fn = fn } })` registers `notes.remove` in this template. The signature tells how values pass between Lua and C, so plugins in either language call it.
- `ecs.key.bind("notes.board", "Delete", "notes.remove")` binds a key while a board has the focus. A function that takes a panel gets the focused one.
- `ecs.panel.addMenuEntry("notes.board", "notes.remove")` adds it to the board's right-click menu. A menu entry's function takes the panel, `void(handle<ecs.panel> panel)`, or nothing, `void()`. The entry shows the function's description, and the key the plugin bound to it for the board, such as Delete.
- The preset's `keys` and the user's settings file add keys and change them: `keys = { ["notes.board"] = { ["Ctrl+D"] = "notes.remove" } }`. A key under `prefix` runs after Alt+W.
- Another Lua plugin calls it with `require("notes").remove(panel)`, once its manifest depends on `notes`. A C plugin calls it through `notes.h`, the header `--definitions` writes for notes: `NotesFunctions_Get(plugin, &notes)` looks up every function of notes, then `notes.remove(panel)` calls one.

## 10. Saved state

- A panel's `saveState` gives a Lua value of plain data, which the session keeps; `create` gets it back with the `stateVersion` it was saved with, so a newer plugin can read an older state or leave it.
- A plugin's own state, apart from its panels, is `ecs.plugin.register({ stateVersion = 1, saveState = fn, restoreState = fn, destroy = fn })`. `destroy` runs before the program exits.
- The user can disable and enable plugins while the tool runs, in the plugin list (Alt+W, then ;). A disabled plugin's `destroy` runs, its panels wait as placeholders, and when it is enabled again it runs from the start and gets back its state.
- Alt+W, then S saves the session to a file you choose. The dialog starts in the user's folder of saved sessions, `~/.local/share/OpenECS/sessions/` (`%APPDATA%\OpenECS\sessions\` on Windows), which the launcher lists, for every tool.

## 11. Events and timers

- `ecs.timer.start(seconds, repeat, fn)` runs a function later, or again and again, and gives a timer whose `stop()` ends it. A panel stops its timers in its type's `destroy`.
- `ecs.event.declare("added", description)` declares `notes.added`; `ecs.event.emit("notes.added", value)` sends it, and any plugin can `ecs.event.subscribe("notes.added", fn)`, which calls `fn(name, value)`. OpenECS sends its own, such as `ecs.panelOpened` with `{ panel = id, type = name }`; [DESIGN.md 8.4](https://github.com/omerfuyar/OpenECS/blob/dev/DESIGN.md) lists them.

## 12. A plugin in C

`plugins/pulse_c/Pulse.c` is a panel type in C. `shuild.c` builds each plugin folder with C files into `lib<name>.so`, or `<name>.dll` on Windows, and builds again only what changed. On Windows a DLL links OpenECS's import library in the release's `lib/`, through which it calls OpenECS.

- A native plugin defines `ECSPlugin_Init(plugin)`, which registers everything, as `init.lua` does. `OpenECS.h` documents every function, and names each one's Lua counterpart.
- `draw.h`, in OpenECS's `include/`, has the functions of draw: `DrawFunctions_Get(plugin, &draw)` looks them all up, with their signatures. OpenECS writes such a header for any plugin: `OpenECS/OpenECS --definitions OpenECS/include/` writes the plugin interface and them for every plugin it finds.
- A C plugin's memory is its own; free it in the panel's `Destroy`, and in the plugin's `Destroy` (`ECSPlugin_Register`).
- C and Lua plugins work together through functions, events, handles and structs, whatever language each is in. A struct is plain data, such as a vector: `ECSStruct_Register(plugin, "vec2", "float x, float y")` in C, or `ecs.struct.register` in Lua.
- A C plugin does the same with `ECSEvent_Declare`, `ECSEvent_Emit`, `ECSEvent_Subscribe` and `ECSTimer_Start`, which `OpenECS.h` documents beside their Lua names.

## 13. Your editor

- `.luarc.json` names `OpenECS/include/`, so the Lua language server knows the `ecs` module, and the functions of the standard plugins: `require("ui")` completes and checks.
- `---@type ecs.Preset` above a preset's `return`, and `---@type ecs.Manifest` above a manifest's, complete and check their fields.
- For functions of plugins that are not standard, write their definitions with `--definitions` and add the folder to `workspace.library`.

## 14. Tests

- `test.lua` runs the tool, sends input as a user would, and checks the session: `OpenECS --test test.lua`. Release builds of OpenECS do not run tests; a Debug build does, which you build from [OpenECS's source](https://github.com/omerfuyar/OpenECS#building).
- A test returns `preset` and `run(test)`. `test.click`, `test.key` and `test.text` send input; `test.session()` gives the session as a table, and `test.match(actual, expected)` compares the fields it names. [OpenECS's design, section 17.5](https://github.com/omerfuyar/OpenECS/blob/dev/DESIGN.md), lists every function.
- This repository's checks build OpenECS's Debug build and run the test on each pull request.

## 15. Shipping your tool

- **Name it.** Change `name`, `app.id` and `app.name` in `preset.lua`, rename the plugins and their folders, and change the names they declare.
- **Install it.** Copy the plugins' folders, with the built libraries, into `~/.local/share/OpenECS/plugins/`, and the preset into `~/.config/OpenECS/presets/`. On Windows, both go into `%APPDATA%\OpenECS\`: `plugins\` and `presets\`. Then `OpenECS --preset mytool` starts it by name, and the launcher lists it.
- **Add it to the system's launcher.** `OpenECS/OpenECS --preset mytool --install` adds the tool with its name and icon: a desktop file on Linux, a Start menu shortcut on Windows. The preset's `app.categories` and `app.mimeTypes` say where it goes and which files it opens. `--uninstall` removes it.

## 16. Where to go next

- [OpenECS-examples](https://github.com/omerfuyar/OpenECS-examples): one example for each part of OpenECS and each standard plugin, in the order to read them.
- [OpenECS's design](https://github.com/omerfuyar/OpenECS/blob/dev/DESIGN.md): how everything works, in detail.
- [OpenECS's Discussions](https://github.com/omerfuyar/OpenECS/discussions): questions, and the tools you build.
