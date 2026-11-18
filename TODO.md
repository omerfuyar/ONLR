# ONLR TODO

What is not decided yet, and work that is waiting. When an item is settled, write the decision into [OVERVIEW.md](OVERVIEW.md) or [DESIGN.md](DESIGN.md), where it belongs, and remove it from here.

## Next

What the owner wants worked on, in this order.

1. **The editor's look and use.** The owner's wishes are under [Editor](#editor).
2. **The Windows experiment.** The owner runs it later, and reports what it prints (see [Tasks](#tasks)). Until then, the preview on Windows is built as DESIGN 12.1 says, and not tested.
3. **The packages.** The first set is built, each with a sample that tests it (see [Libraries](#libraries)). Next: the open limits that each lists, and the second round. The camera's helpers are built too (DESIGN 10).
4. **Linux and the `.love` file first.** Windows follows. macOS and Android are noted for later (see [Export](#export)).

## Engine

- **Components for sound, animation and particles.** Ideas. Libraries come first (OVERVIEW 9): anim8 animates a sprite through its `quad` (DESIGN 11.5), and peachy, for Aseprite's files, could too; ripple for sounds and their volumes; and LÖVE's own particle systems, now `particles.emitter` (DESIGN 11.6), whose settings Hot Particles edits, as a panel of the editor could. A sound property already streams with the option `stream` (DESIGN 6.2), and a node under the top node plays music for the whole game (DESIGN 5).
- **Tags.** A component type serves as a tag (DESIGN 7). An idea for later: tags or groups of their own. `onlr.tree.findAll` and `findAllComponents` stay so that a function that finds by tag can join them.
- **Loading.** A root's files are loaded when the root loads, and those that the next root does not name are let go (DESIGN 6.2). An idea for later: reading a big root's images and sounds in a thread, while a picture of progress shows, as love-loader and lily do.

## Runner and link

- **The preview on Windows.** SDL's offscreen driver gets OpenGL only through EGL, and LÖVE's runtime for Windows holds no `libEGL.dll`. The owner's experiment showed it, with LÖVE 11.5 and an NVIDIA card: with the offscreen driver LÖVE stops with "Could not initialize OpenGL / GLES library", and shows a message box that waits for a click; with SDL's normal driver it gets OpenGL 3.3. So the preview does not start on Windows as DESIGN 12.1 starts it on Linux.

  The second experiment checked a normal window that the engine hides at once, with SDL's `SDL_HideWindow` through LuaJIT's FFI: LÖVE reports it hidden, it draws into a canvas, and reads the canvas back right. DESIGN 12.1 takes this way. But a black window shows for a moment, between LÖVE opening it and the engine hiding it, and the preview starts again at every change of a script (DESIGN 12.5). The next experiment opens the window outside the screen, borderless and one pixel wide, then hides it (see [Tasks](#tasks)). If it still shows:
  - ANGLE's `libEGL.dll` and `libGLESv2.dll` beside LÖVE's files in ONLR's archive. LÖVE itself stays unchanged. The preview then draws with OpenGL ES over Direct3D, not with the OpenGL of the exported game, so a shader may look different in the node view. The offscreen driver also asks EGL for its list of devices, which ANGLE may not give.
- **The offscreen driver elsewhere.** It is checked on Linux with an NVIDIA card, with the system's LÖVE 11.5 and with LÖVE's own AppImage, and on a computer with no display and no graphics card, where Mesa draws in software. It needs the system's EGL library. Not checked: Intel and AMD cards.
- **The node view's speed.** Measured on the owner's computer, on Linux with an NVIDIA card, with the node view filling the editor's window at 946×1006 pixels: about 41 frames a second when draw blended the frame into the panel's pixels, 10.7 ms of the panel's 14.4 ms. The node view now draws with gpu (DESIGN 13.3), which leaves about 6.5 ms a frame of moving the pixels through the link and into the texture. To measure again on the owner's computer; if it is still slow, the runner sends a frame only when the picture changed, or a smaller one while dragging.

- **The game in a panel.** Play shows the game in LÖVE's own window, and only what a mode draws into differs between the modes (DESIGN 12.1). Showing the game in a panel is an idea for later. What it needs:
  - Frames from the game. `love.graphics.captureScreenshot` reads the window's picture, also when there is no window, so the game draws as always. Drawing into a canvas of the engine's instead would break a game that sets canvases of its own.
  - A pace. Without a window LÖVE does not wait for the screen, and runs hundreds of frames a second.
  - The panel's keys, text and pointer, sent to the game, and the engine answering for `love.keyboard.isDown`, `love.mouse.getPosition` and the like. Also the pointer's modes, gamepads, the desktop's size, and the keys that the editor takes before a panel gets them.
- **Reloading while playing.** For later. A changed script or image takes effect in the running game without a restart. Open: what happens to the values a component keeps.
- **Previews of node files.** For later. A small picture of a node file, such as in the files panel, would be a view that the preview draws (DESIGN 12.3). No panel shows one: the files panel and the asset viewer know nothing of ONLR. The preview draws when asked and updates nothing, so a preview of an animation or of particles would stand still.
- **A debugger.** Stopping at a line and reading variables. Not planned; an error's file, line and stack are shown (DESIGN 12.2).

## Editor

- **From Unity.** What its editor has that ONLR's lacks, as candidates. None is decided.
  - The node view: a rectangle tool that sizes a node by its corners; marks for nodes that draw nothing, with a toggle; a picture of what each camera sees.
  - The nodes panel: an eye that hides a node in the node view only, and a lock that keeps it from being chosen there.
  - The inspector: a lock that keeps its node while another is chosen; reordering components; a round button that picks a node for a reference (a file has the dialog's button now); a pipette for the colour picker; a list of an instance's changes, to keep or drop them all.
  - The files panel: favourite folders; Find what names this file.
  - The console: Pause on Error. An error's entry holds its stack, so no pane is needed for it.
  - Playing: a tint over the editor while the game plays, such as OpenECS's frame colour, `ecs.colorFrame`, which waits for a way to set a setting for the run only, as `ecs.setting.set` writes the user's file; sizes of the window to choose from, such as a phone's; values that were changed in the running game, with a way to keep them.
  - The editor: a list of the history's records, to jump back to one; a search over every function, node and file with one key. A window for keys is OpenECS-std's key list now (below).
  - Tools of their own, each a panel: a cutter of sprite sheets into quads, a timeline for animations, a palette for tile maps.
- **Panels for later.** Ideas, each a panel type of a plugin (DESIGN 13.1): a node editor, in which the user connects nodes to write logic without code, as Unreal's Blueprints do, and whose output is a script, so the engine needs nothing new; a tile editor, which waits for the choice of a library for tile maps (see [Libraries](#libraries)).
- **Video in the asset viewer.** For later. LÖVE plays Ogg Theora video, and OpenECS-std's video reads MPEG-1 only, so the asset viewer shows no video (DESIGN 13.1).
- **A project's own script template.** A new script starts from ONLR's template (DESIGN 13.4). An idea for later: a project that keeps a template of its own.
- **A merge driver for node files.** For later. A conflict in a node file is git's conflict of text, which the user resolves by hand (DESIGN 4.2). A merge driver that ONLR ships would merge by ids and fields, so that only one field changed on both sides conflicts. Git calls it for node files through `.gitattributes`, and takes its command from its own settings, not from the repository, so the editor would set it in each clone that it opens. Checked on a real merge of coin run's `nodes/level.lua`, as the editor writes it, with one branch's change on each side:
  - Merge cleanly: a node moved and another node's colour; a script's two values a line apart; a component added and another value of the node; a child added and another node moved; two instances changed.
  - Conflict: a node's `posX` and `posY`; a node's `name` and `posX`; two children added at the end of one node's list.

## Export

- **An AppImage as a Linux build.** One file is easier to hand out than an archive. Making it needs `appimagetool`, which runs on Linux only.
- **The Windows executable's icon and details.** For later: a build keeps LÖVE's (DESIGN 14.2). Changing them means editing the executable's resources, with a small writer of our own.
- **Windows on 32 bits and on ARM.** LÖVE 11.5 has a 32-bit runtime. Not planned unless asked for.
- **macOS, for later.** LÖVE ships `love.app` in a zip; a build puts the `.love` file inside it and changes its `Info.plist`. Open: signing, which needs a Mac, and what an unsigned build shows its user. The editor itself runs on macOS when OpenECS does.
- **Android, for later.** LÖVE's Android project builds a package with the game inside. It needs a JDK, the Android SDK and Gradle on the user's computer. Open: whether the editor drives them, or only prepares the folder; touch input and screen sizes in the engine.
- **iOS, for later.** It needs Xcode on a Mac and a developer account.
- **The web.** love.js supports LÖVE 11 without LuaJIT, and is not maintained by LÖVE's team. Not planned until LÖVE has a web target of its own.

## Libraries

- **The first set of packages, chosen on 2026-11-17 and built on 2026-11-18.** Each is a package in `packages/`, with components that compose as OVERVIEW 9 says:

  | Job                  | Package wraps        | Its components                                                                                   |
  | -------------------- | -------------------- | ------------------------------------------------------------------------------------------------ |
  | Collision of boxes   | bump (built)         | `bump.world` on the root, `bump.body` on a node (DESIGN 11.3).                                   |
  | Physics              | `love.physics` (built) | A world, bodies, shapes and joints (DESIGN 11.4). No library. Open: the limits that DESIGN 11.4 lists, such as a shape whose node moves under its body after it started, properties that a script changes after the start, and Box2D's other shapes and joints. |
  | Particles            | LÖVE's particle systems (built) | `particles.emitter` on a node, its settings as properties (DESIGN 11.6). No library. Open: the limits that DESIGN 11.6 lists; the node view shows a still picture, and a moving one needs the preview to update what it shows. |
  | Animation            | anim8 (built)        | `anim8.animation` beside `onlr.sprite`, which sets the sprite's `quad` each frame (DESIGN 11.5). Open: the limits that DESIGN 11.5 lists; the node view should show the first frame, which needs a function that the preview calls once a node's components are made, as Unity calls `OnValidate`, or the preview drawing a node's components after those they need. |
  | Tile maps from Tiled | STI (built)          | `sti.map` on a node, which draws its layers where the node draws (DESIGN 11.7). Open: the limits that DESIGN 11.7 lists; tiles that collide, through STI's plugins for bump and Box2D tied to `bump.world` and `physics.world`; Tiled's objects made into nodes, such as a spawn point that is a node file's instance; and parallax. |
  | Tweens and timers    | flux and tick (built) | `flux.tweens` and `tick.timers` on a node, each a group of the library's own that ends with its node (DESIGN 11.8). tick, by flux's author, was chosen over a timer of ONLR's own and over hump's timer, which would bring hump's tweens beside flux. Open: the limits that DESIGN 11.8 lists. |
  | Input actions        | baton (built)        | `baton.input` on a node: its controls and pairs as properties, its joystick by number (DESIGN 11.9). Open: the limits that DESIGN 11.9 lists; the inspector listening for a key to bind. |
  | Scaling to the window | push (built)        | `push.screen`, a group on the top node that draws the game at a fixed size and scales it to the window (DESIGN 11.10). Open: the limits that DESIGN 11.10 lists; a camera under the screen could take the screen's size itself, without its `width` and `height`. |
  | Screen effects       | moonshine (built)    | `moonshine.chain`, a group, with an effect type of its own for each of moonshine's effects beside it, in `moonshine.effect`, applied in the chain's `order` (DESIGN 11.11). Open: the limits that DESIGN 11.11 lists, such as effects that measure with the window's size under `push.screen`, and a chain that covers what drew before it. |
  | Sound                | `love.audio` (built) | `audio.source` and `audio.music`, a sound decoded whole and one streamed, at a node, with a place in the world if mono; `audio.listener`, LÖVE's listener at its node or its camera's point (DESIGN 11.12). No library. Open: the limits that DESIGN 11.12 lists, such as a node that `setPaused` pauses playing on, and volumes by kind of sound, as ripple gives. |
  | Interface inside the game | SUIT (built)    | A component for each of SUIT's widgets, `suit.button`, `suit.label`, `suit.checkbox`, `suit.slider`, `suit.input` and `suit.imagebutton`, placed on nodes, which tell their nodes of a click or a change (DESIGN 11.13). Open: the limits that DESIGN 11.13 lists, such as overlapping widgets, a theme for each widget, and a layout of rows and columns that a node could give its children. |
  | Light and shadows    | Shädows (built)      | `shadows.world`, a group that draws the light over its node and all under it; `shadows.light` and `shadows.shape.box`, `.circle` and `.polygon` at nodes (DESIGN 11.14). Shipped as ONLR's own copy, which sets no global (`packages/shadows/library/ONLR.md`). Open: the limits that DESIGN 11.14 lists, such as a camera that turns, heights, rooms and stars, and Shädows' normal and height maps. |

- **The second round, weighed on 2026-11-18.** Sound was built first, as `audio`, then SUIT, then Shädows (all above). Of each:
  - **In-game interface: SUIT, built on 2026-11-18** (above). Slab was left out: about 18,000 lines, made for a tool's windows and docking rather than a game's menus, and it sets globals.
  - **Light and shadows: Shädows, built on 2026-11-18** (above). The owner chose to ship ONLR's own copy, changed so that it sets no global, rather than to relax the rule or to write lights of ONLR's own. Measured, it set one global, `shadows`, through Lua's `module`; the names such as `Object` and `Light` were the modules' own. `packages/shadows/library/ONLR.md` says how to change a newer version the same way.
- **The camera's helpers, built on 2026-11-18.** `onlr.camera.view` stays the one view: gamera and hump's camera do what it does, and STALKER-X, which does more, has no licence file and needs hump. What they do better came as components of the engine beside the camera, which a game combines: `onlr.camera.follow`, `onlr.camera.limits` and `onlr.camera.shake` (DESIGN 10). They are the engine's, since nearly every game with a camera follows something (OVERVIEW 9). They are in a folder with the camera, which is `onlr.camera.view`, since a type cannot also be a folder of types; physics's shapes and joints, and moonshine's effects, are in folders too. Open: the limits that DESIGN 10 lists. A game may still use any camera library in its scripts.
- **How a library was chosen.** A library works in a project as it is, and a package is made for it only when it is chosen (OVERVIEW 9). A library fits ONLR when:
  - it is Lua that LuaJIT runs in LÖVE 11.5, with no compiled module, so an export runs on every platform without a build;
  - it does not take `love.run` and does not replace LÖVE's callbacks. Adding to `love.handlers` is fine (DESIGN 8.1);
  - it returns a module and sets no global;
  - its licence lets a game ship it: MIT, zlib or ISC;
  - it is maintained, or small and finished.

  The rules on `love.run` and on globals change if most useful libraries break them.

  The candidates, by job:

  | Job                         | Candidates                                     | What matters for ONLR                                                                                   |
  | --------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
  | Collision of boxes          | bump.lua; slick; HC                            | bump's boxes do not turn. slick and HC take polygons that turn. slick's licence is MPL-2.0, which asks that changes to its own files stay open. |
  | Physics                     | `love.physics`; breezefield                    | `love.physics` is part of LÖVE and needs components only. breezefield makes it shorter to use.         |
  | Tile maps from Tiled        | STI; cartographer                              | STI draws a map through a canvas of its own, so a package draws its layers itself, to follow the camera.   |
  | Animation of a sprite sheet | anim8; peachy                                  | anim8 gives a LÖVE quad for each frame, whose rectangle a script copies into `onlr.sprite`'s `quad`. peachy reads Aseprite's files.           |
  | Camera                      | gamera; hump's camera                          | Both turn a point of the window into the world's. hump's other parts take LÖVE's callbacks; its camera does not. |
  | Scaling to the window       | push; shove; maid64                            | Each draws a group on the top node (DESIGN 5). maid64 is for pixel art only.                           |
  | Tweens and timers           | flux; tween.lua; hump's timer; tick            | Each is called from a component's `update`.                                                            |
  | Input                       | baton                                          | Turns keys, buttons and sticks into a game's own actions.                                              |
  | Sound                       | ripple                                         | Groups sounds by tags, with a volume for each.                                                         |
  | Interface inside the game   | SUIT; Slab                                     | SUIT and Slab draw in the window's space, from `love.draw` or a component. love-nuklear and cimgui-love are left out: they are compiled modules. |
  | Light and shadows           | shadows; light_world                           | Each draws a group, such as the world under a camera (DESIGN 5).                                     |
  | Screen effects              | moonshine                                      | Draws a group (DESIGN 5).                                                                              |
  | Saved games and data        | bitser; binser; json.lua                       | bitser uses LuaJIT's FFI, which LÖVE has.                                                              |
  | Loading in a thread         | love-loader; lily                              | For the [Engine](#engine)'s loading.                                                                   |
  | Debugging                   | lovebird; lurker                               | lurker swaps changed files in a running game, which may clash with the engine's loaded types (see [Runner and link](#runner-and-link), reloading while playing). |

  Whichever library gives bodies, its world is a component of what a root has one of, and contacts reach scripts with `node:send`, as DESIGN 11.3 shows.

  Licences, checked on 2026-11-17: bump, anim8, peachy, gamera, push, shove, flux, tick, baton, ripple, Slab, shadows, binser, json.lua, love-loader, lovebird, lurker and breezefield are MIT; STI, hump, HC, moonshine and SUIT are MIT too, though GitHub does not read their files; bitser is ISC; tween.lua is BSD-2-Clause; slick is MPL-2.0. light_world's repository is gone.

  Libraries of entities and of classes, such as tiny-ecs, Concord, middleclass and classic, overlap ONLR's own nodes and components. A user may still use them in scripts, and no package is made for them.
- **A bump package's details.** DESIGN 11.3 shows its outline as a sample, and `samples/coinrun` holds one that works: its body has `solid`, and other bodies pass through one that is not solid. Open if bump is chosen as a package of ONLR's own: a body on a node that is turned or scaled, since bump's boxes are not.

- **A new project's default filter.** The engine keeps LÖVE's `linear` when the manifest names none (DESIGN 3.2). Open, for the owner: whether a new project writes `defaultFilter = "nearest"`, which keeps pixel art sharp and makes large images that are scaled down rough. It depends on whether most games made with ONLR are pixel art.
- **Highdpi.** A window that the system scales, at a display scale above 100%, is stretched by the system and blurred, unless the manifest's `window` has `highdpi`. Not checked on the owner's computers: Windows and Linux at the owner's display scale.

## LÖVE

- **LÖVE 12.0.** It is not released. It changes the default font, removes functions that 11 deprecated, and builds on SDL3. When it is released: which versions a project may name, and whether the engine serves both.

## Tasks

- **A guide to using ONLR.** A user's guide, written for someone who knows LÖVE or is learning it: making a project, the editor's panels, nodes and components, writing a script, packages, playing and exporting. It shows what to do, step by step, and links to DESIGN for how it works. Where it lives, as a document of the repository or as pages of its own, is open.
- **The preview's hidden window on Windows is not tested.** `plugins/onlr/runner/preview.lua` hides LÖVE's window with `SDL_HideWindow` through LuaJIT's FFI, as DESIGN 12.1 says. It was written on Linux, where the offscreen driver is used, and never run on Windows.
- **The Windows experiment.** It tells whether the preview's window can open on Windows without showing for a moment (see [Runner and link](#runner-and-link)). The owner runs it in the command prompt:
  1. Keep `C:\t\main.lua` as it is, and make `C:\t\conf.lua` with these lines. They open LÖVE's window outside the screen, without a border, one pixel wide:

     ``` lua
     function love.conf(t)
       t.window.x = -10000
       t.window.y = -10000
       t.window.width = 1
       t.window.height = 1
       t.window.borderless = true
     end
     ```

  2. In LÖVE's folder, run `lovec.exe C:\t`.
  3. Report everything that it prints, any error, and whether anything showed: a window, a flash, or a button in the task bar, even for a moment.
- **What OpenECS's updates of 2026-11-15 to 18 give the editor.** OpenECS and OpenECS-std added these; how the editor should use each, most useful first:
  - **The profiler** (std DESIGN 32, Alt+W then F): each plugin's own time, each panel's draw and each step of the main loop, as the core measures them while `ecs.profile` is on. It replaces the hand measurement of the node view's speed (see [Runner and link](#runner-and-link)): the owner measures again with it, and its Copy report gives the numbers. A check of ONLR's plugin with it, such as the inspector and the nodes panel on a large node file, finds where the editor is slow.
  - **The plugin skill** (OpenECS's skill for plugin authors): what to read, write, check and audit for a plugin, with its advice on Lua's speed. ONLR's plugin, `plugins/onlr/`, is audited against it once.
  - **The console's actions**: a double click on an entry goes to the file and line that it names. The game's errors and `print`s reach the console through the link (DESIGN 12.2); they should name the project's file with its path from the project's folder and its line, `components/player.lua:12:`, so a double click opens the script there. To check with the runner's messages, and with a stack's lines.
  - **`ui.search` and `ui.matches`**: done on 2026-11-18. The nodes panel's search is `ui.search`, and matches each word with `ui.matches`, keeping `t:` for types (DESIGN 13.4).
  - **`ui.path`**: done on 2026-11-18. The export panel's folder is one, with `openFolder`, and so is a file's row in the inspector, whose dialog shows the endings that LÖVE reads; a path in the project is kept from its folder, and one outside it is refused (DESIGN 13.4). The round button of Unity's list is this, for files; for nodes it is still dragging.
  - **The key list** (std DESIGN 33, Alt+W then K): every binding of the tool, which the user changes in their settings. ONLR's bindings, such as `onlr.deleteChosen`, show there by their functions' names, so those names should say what they do to a user, and `ecs.key.functions` should list them.
  - **`ui.graph`**: bars of numbers, which stack in colours. A panel of the running game's frame, its update and draw times and its count of nodes, which the engine sends through the link, as Unity's profiler of the game, for later.
  - **A slider's release is one change**: `onSubmit` gets the value that a drag ends on, and the slider shows its value while dragging. The inspector's slider already takes `onSubmit`, so a drag is one record of the history; `samples/editor` checks it once.
  - **`ui.show` draws only what changed**, `ecs.scale` scales the core's own interface, and frames draw while a window moves or resizes. The editor gets these without a change.
- **What OpenECS-std needs.** The editor needs these of the standard plugins, which do not have them yet. They are the owner's too, so they change when that is the better solution:
  - net: listening on one address, `127.0.0.1`, and telling the port that was chosen (DESIGN 12.2). It listens on every address today, and does not tell the port. Until it does, the engine could listen and print its port.
  - process: environment variables for the program it starts, for `SDL_VIDEODRIVER` (DESIGN 12.1). Until it has them, `env` starts the runner on Linux and `cmd /c` on Windows.
  - fs: a file's permissions. Until it tells them, the Linux build marks as programs LÖVE's launcher, the files of `bin/` and the libraries.
  - fs: watching the folders inside a folder, for the project's folder.
  - The files panel: another plugin says how a kind of file opens, such as a node file in a node view, which new files it makes, such as a script from a template, and hears what it renames, moves and deletes, so the editor changes the paths that name them (DESIGN 13.7).
  - fs: moving a file to the system's trash, for the files panel.
  - video: Ogg Theora, which LÖVE plays, for later (see [Editor](#editor)).
  - ui: a field and a number field that tell when they lose the keys, so the inspector takes a typed value without Return; a click twice on a tree's node, apart from one click, so the files panel need not time a second click itself (DESIGN 13.7).
  - The tool's menu: entries that a plugin gives while it runs, for the projects opened last (DESIGN 13.2).
  - The core: a panel hears where dragged data is over it, so the nodes panel shows a line where a dragged node will land. While data is dragged, the core gives no panel the pointer's moves (OpenECS DESIGN 7.9).
  - The test's `dropFiles` gives a node view a place 26 units above the pointer's, the height of a tab row. Checked in `samples/editor/editortest.lua`, which drops an image at y 150 and gets 124.
- **The gallery has no test of the editor.** `samples/gallery` is tested in LÖVE only. An editor test can click and read the files the editor writes, but cannot read the nodes that the preview draws, so it cannot check that each room opens and shows in a node view. A function of the test that returns the preview's nodes, or a screenshot compared with a saved one, would let it.
- **The editor on Windows is not tested.** The paths, the rename over a file when a data file is saved, and starting the runners were written on Linux.
- **What the editor does not do yet.** Offering to move a project that names another version of LÖVE (DESIGN 15.1) is not written.
- **The tests on Windows.** `shuild.c` runs them on Linux only: they need SDL's offscreen driver, and set variables as a POSIX shell does.
- **A warning when a popup opens.** On the owner's computer, a dropdown logs "[ecs] The GPU cannot present to a window (The GPU API doesn't support transparent windows)". It is OpenECS's, not ONLR's: its popups ask for a transparent window.
- **The release of 0.1.0.** It waits for OpenECS 0.7.0, which the release workflow names. Once OpenECS 0.7.0 is released: `dev` goes into `main` through a pull request, which the owner merges; the tag `v0.1.0` on `main` makes the draft release (DESIGN 17); the owner tries the Linux archive (unpacks it, runs `./ONLR gallery`, plays a room and exports it), then publishes the draft. `.github/scripts/package.sh 0.1.0 0.7.0 linux-x86_64` makes the archive on the owner's computer too, to try it before the tag.
- **The archive on Windows is not tested.** `ONLR.cmd`, the LÖVE in `love/` that the runners find, and `--install`'s shortcut were made on Linux. `ONLR.cmd` shows a console for a moment; a small program in its place, or OpenECS starting a preset beside its executable, would not.
- **The Linux runtime has no address.** DESIGN 15.2 downloads it from ONLR, which hosts the contents of LÖVE's AppImage as a `.tar.gz`. Nothing hosts it yet, so `plugins/onlr/runtimes.lua` has no address and no hash for it. Until then a Linux build uses the LÖVE that runs the preview and the game, when it is an unpacked AppImage, or the folder that `onlr.linuxRuntime` names. The AppImage's own SHA-256 hash is `65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00`.
- **Export on Windows is not tested.** The user's data folder there, `%APPDATA%`, and a Linux build made on Windows, which cannot find LÖVE's AppImage.
- **OpenECS's TODO.md** still lists this editor's open questions. Replace them there with a link to this repository.
- **Rulesets.** `.github/rulesets/` holds the rules of `dev` and `main`. The owner imports them in the repository's settings.
