# ONLR TODO

What is not decided yet, and work that is waiting. When an item is settled, write the decision into [OVERVIEW.md](OVERVIEW.md) or [DESIGN.md](DESIGN.md), where it belongs, and remove it from here.

## Next

What the owner wants worked on, in this order.

1. **OpenECS's dev of 2026-11-24.** The editor works on it. [Tasks](#tasks), "What OpenECS's dev of 2026-11-24 gives the editor", lists what to use of it.
2. **The review of 2026-11-24.** Its items are under [Review](#review), P1 first.
3. **The editor's look and use.** The owner's wishes are under [Editor](#editor). The owner chose these from Unity's list: the eye and the lock (built, DESIGN 13.3), a button that picks a node for a reference (built, 13.4), a list of the history (built, 13.6), and Pause on Error, which became the game stopping at its error with its nodes kept for the editor (built, 12.6).
4. **The Windows experiment.** The owner runs it later, and reports what it prints (see [Tasks](#tasks)). Until then, the preview on Windows is built as DESIGN 12.1 says, and not tested.
5. **The packages.** The first set is built, each with a sample that tests it (see [Libraries](#libraries)). Next: the open limits that each lists, and the second round. The camera's helpers are built too (DESIGN 10).
6. **Linux and the `.love` file first.** Windows follows, then Android and iOS, which the owner wants; macOS is noted for later (see [Export](#export)).
7. **Shaders, and the graph panel for scripts and shaders.** Decided with the owner on 2026-11-25 (DESIGN 6.7, 6.8, 10 and 13.9). The milestones are under [Tasks](#tasks), "Shaders and graphs". Their place in this list is the owner's to choose.

## Engine

- **Components for sound, animation and particles.** Ideas. Libraries come first (OVERVIEW 9): anim8 animates a sprite through its `quad` (DESIGN 11.5), and peachy, for Aseprite's files, could too; ripple for sounds and their volumes; and LÖVE's own particle systems, now `particles.emitter` (DESIGN 11.6), whose settings Hot Particles edits, as a panel of the editor could. A sound property streams by its value, `{ path, stream = true }` (DESIGN 6.2), and a node under the top node plays music for the whole game (DESIGN 5).
- **Shaders: what is left open.** Shaders are designed (DESIGN 6.7, and `onlr.shader` in 10). Open:
  - Setting the shader back after each component's draw (DESIGN 6.3). The owner chose it, and wants it decided again later: what it costs on a large tree, measured, and whether a component should keep its shader for the next one on purpose, such as a script that shades the nodes drawn after it.
  - `time` on phones whose pixel shaders lack high precision (DESIGN 6.7): sending it as a part of a period, such as an hour, keeps its digits, but a shader that moves with it jumps once in that period.
  - Shaders under an `onlr.shader` of `draws` replace it and do not add up (DESIGN 10). A way to join them, such as a list of shaders that one `picture` applies in turn, as moonshine's chain does.
  - `drawTreeEditor` for `moonshine.chain` and `shadows.world` (DESIGN 11.11, 11.14), so their effects show in the node view as `onlr.shader`'s do.
  - A GLSL file's values cannot say their range, their default, or that they are a colour (DESIGN 6.7). An idea: a comment after an `extern` that says so.
- **Tags.** A component type serves as a tag (DESIGN 7). An idea for later: tags or groups of their own. `onlr.tree.findAll` and `findAllComponents` stay so that a function that finds by tag can join them.
- **Loading.** A root's files are loaded when the root loads, and those that the next root does not name are let go (DESIGN 6.2). An idea for later: reading a big root's images and sounds in a thread, while a picture of progress shows, as love-loader and lily do.

## Runner and link

- **The preview on Windows.** SDL's offscreen driver gets OpenGL only through EGL, and LÖVE's runtime for Windows holds no `libEGL.dll`. The owner's experiment showed it, with LÖVE 11.5 and an NVIDIA card: with the offscreen driver LÖVE stops with "Could not initialize OpenGL / GLES library", and shows a message box that waits for a click; with SDL's normal driver it gets OpenGL 3.3. So the preview does not start on Windows as DESIGN 12.1 starts it on Linux.

  The second experiment checked a normal window that the engine hides at once, with SDL's `SDL_HideWindow` through LuaJIT's FFI: LÖVE reports it hidden, it draws into a canvas, and reads the canvas back right. DESIGN 12.1 takes this way. But a black window shows for a moment, between LÖVE opening it and the engine hiding it, and the preview starts again at every change of a script (DESIGN 12.5). The next experiment opens the window outside the screen, borderless and one pixel wide, then hides it (see [Tasks](#tasks)). If it still shows:
  - ANGLE's `libEGL.dll` and `libGLESv2.dll` beside LÖVE's files in ONLR's archive. LÖVE itself stays unchanged. The preview then draws with OpenGL ES over Direct3D, not with the OpenGL of the exported game, so a shader may look different in the node view. The offscreen driver also asks EGL for its list of devices, which ANGLE may not give.
- **The offscreen driver elsewhere.** It is checked on Linux with an NVIDIA card, with the system's LÖVE 11.5 and with LÖVE's own AppImage, and on a computer with no display and no graphics card, where Mesa draws in software. It needs the system's EGL library. Not checked: Intel and AMD cards.

- **The game in a panel.** Play shows the game in LÖVE's own window, and only what a mode draws into differs between the modes (DESIGN 12.1). Showing the game in a panel is an idea for later. What it needs:
  - Frames from the game. `love.graphics.captureScreenshot` reads the window's picture, also when there is no window, so the game draws as always. Drawing into a canvas of the engine's instead would break a game that sets canvases of its own.
  - A pace. Without a window LÖVE does not wait for the screen, and runs hundreds of frames a second.
  - The panel's keys, text and pointer, sent to the game, and the engine answering for `love.keyboard.isDown`, `love.mouse.getPosition` and the like. Also the pointer's modes, gamepads, the desktop's size, and the keys that the editor takes before a panel gets them.
- **Reloading while playing.** For later. A changed script or image takes effect in the running game without a restart. Open: what happens to the values a component keeps.
- **Previews of node files.** For later. A small picture of a node file, such as in the files panel, would be a view that the preview draws (DESIGN 12.3). No panel shows one: the files panel and the asset viewer know nothing of ONLR. The preview draws when asked and updates nothing, so a preview of an animation or of particles would stand still.
- **A debugger.** Stopping at a line and reading variables. Not planned; an error's file, line and stack are shown (DESIGN 12.2).

## Editor

- **From Unity.** What its editor has that ONLR's lacks, as candidates. None is decided.
  - The node view: marks for nodes that draw nothing, with a toggle; a picture of what each camera sees.
  - The inspector: a pipette for the colour picker; a list of an instance's changes, to keep or drop them all.
  - The files panel: favourite folders; Find what names this file.
  - Playing: values that were changed in the running game, with a way to keep them. The tint and the window's sizes are built (DESIGN 12.1).
  - The editor: a window for keys is OpenECS-std's key list now (below). The search (DESIGN 13.8) could find functions written as `X.y = function(`, and text inside files.
  - Tools of their own, each a panel: a cutter of sprite sheets into quads, a timeline for animations, a palette for tile maps.
- **The Rectangle tool's limits** (DESIGN 13.3): sizing many chosen nodes as one rectangle; Shift to keep a node's proportions; a circle that keeps round, by its `radius`, and a text that gets a `width` to wrap at, in place of a scale.
- **Dragging components in the inspector.** Move Up and Move Down order them (DESIGN 13.4). Dragging a component's heading needs OpenECS-std's `ui.section` to start a drag and to tell where a drop lands among the sections, as its tree does.
- **moonshine's order.** `moonshine.chain` applies its effects in its `order` list (DESIGN 11.11). The node's `componentOrder` (DESIGN 5) could replace it, so the user orders the effects as the inspector shows them; `order` stays while a script changes the order at run time.
- **Graphs: what is left for later.** The graph panel, ira-scripts and ira-shaders are designed (DESIGN 6.8, 13.9). For later, after the milestones under [Tasks](#tasks):
  - Ira-scripts: blocks for LÖVE's own functions, made from LÖVE's definitions that ONLR ships (DESIGN 4.3), so each function of LÖVE is a block with typed pins; blocks for the engine's functions, such as `spawn`, `destroy`, `find` and `loadRoot` (DESIGN 7.2); blocks that call another component's functions; values of a graph's own that the inspector does not show, as Unreal's private variables; and a `delay` that starts over.
  - Ira-shaders: noise, gradients and checkers; Sample Image, which reads another image or the drawn one at a moved place, for ripples and heat haze; and a preview on each block, as Unity's Shader Graph has, which costs a shader and a frame for each block.
  - Graphs in packages, beside their scripts, so a package can ship a component as a graph.
- **Panels for later.** Ideas: a tile editor, which waits for the choice of a library for tile maps (see [Libraries](#libraries)).
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
- **Android, which the owner wants.** LÖVE's Android project builds a package with the game inside. It needs a JDK, the Android SDK and Gradle on the user's computer. Open: whether the editor drives them or only prepares the folder; signing; touch input, screen sizes and the phone's turning in the engine, and the play sizes of a phone (DESIGN 12.1) as a start. Shaders are decided: the editor checks each as GLSL ES, and a phone's export refuses one that fails (DESIGN 6.7); an ira-script has touch events (DESIGN 6.8).
- **iOS, which the owner wants.** LÖVE's Xcode project builds it. It needs Xcode on a Mac and a developer account, so ONLR prepares the project and the user builds it on a Mac. The same open questions as Android's.
- **The web.** love.js supports LÖVE 11 without LuaJIT, and is not maintained by LÖVE's team. Not planned until LÖVE has a web target of its own.

## Libraries

- **The first set of packages, chosen on 2026-11-17 and built on 2026-11-18.** Each is a package in `packages/`, with components that compose as OVERVIEW 9 says:

  | Job                  | Package wraps        | Its components                                                                                   |
  | -------------------- | -------------------- | ------------------------------------------------------------------------------------------------ |
  | Collision of boxes   | bump (built)         | `bump.world` on the root, `bump.body` on a node (DESIGN 11.3).                                   |
  | Physics              | `love.physics` (built) | A world, bodies, shapes and joints (DESIGN 11.4). No library. What a script changes after the start, a moving fixture's node and Box2D's other joints and loops are built. Open: the limits that DESIGN 11.4 lists, such as the mouse and gear joints. |
  | Particles            | LÖVE's particle systems (built) | `particles.emitter` on a node, its settings as properties (DESIGN 11.6). No library. Open: the limits that DESIGN 11.6 lists. |
  | Animation            | anim8 (built)        | `anim8.animation` beside `onlr.sprite`, which sets the sprite's `quad` each frame (DESIGN 11.5). Open: the limits that DESIGN 11.5 lists. |
  | Tile maps from Tiled | STI (built)          | `sti.map` on a node, which draws its layers where the node draws (DESIGN 11.7). `sti.bump` and `sti.physics` make the tiles that Tiled marks `collidable` collide, and `sti.objects` makes objects that name a node file into its instances. Open: the limits that DESIGN 11.7 lists, such as boxes that do not follow a moving map, and objects' properties given to their instances; and parallax. |
  | Tweens and timers    | flux and tick (built) | `flux.tweens` and `tick.timers` on a node, each a group of the library's own that ends with its node (DESIGN 11.8). tick, by flux's author, was chosen over a timer of ONLR's own and over hump's timer, which would bring hump's tweens beside flux. Open: the limits that DESIGN 11.8 lists. |
  | Input actions        | baton (built)        | `baton.input` on a node: its controls and pairs as properties, its joystick by number (DESIGN 11.9). Open: the limits that DESIGN 11.9 lists; the inspector listening for a key to bind. |
  | Scaling to the window | push (built)        | `push.screen`, a group on the top node that draws the game at a fixed size and scales it to the window (DESIGN 11.10). Open: the limits that DESIGN 11.10 lists; a camera under the screen could take the screen's size itself, without its `width` and `height`. |
  | Screen effects       | moonshine (built)    | `moonshine.chain`, a group, with an effect type of its own for each of moonshine's effects beside it, in `moonshine.effect`, applied in the chain's `order` (DESIGN 11.11). Open: the limits that DESIGN 11.11 lists, such as effects that measure with the window's size under `push.screen`, and a chain that covers what drew before it. |
  | Sound                | `love.audio` (built) | `audio.source`, a sound decoded whole or streamed, at a node, with a place in the world if mono; `audio.listener`, LÖVE's listener at its node or its camera's point (DESIGN 11.12). No library. Open: the limits that DESIGN 11.12 lists, such as a node that `setPaused` pauses playing on, and volumes by kind of sound, as ripple gives. |
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

- **Highdpi.** A window that the system scales, at a display scale above 100%, is stretched by the system and blurred, unless the manifest's `window` has `highdpi`. Not checked on the owner's computers: Windows and Linux at the owner's display scale.

## LÖVE

- **LÖVE 12.0.** It is not released. It changes the default font, removes functions that 11 deprecated, and builds on SDL3. When it is released: which versions a project may name, and whether the engine serves both.

## Tasks

- **Adding packages in the editor.** DESIGN 11.2 says that the editor copies a package into a project when the user adds it, offers a newer version, and deletes it when the user removes it. Only Scale to the window copies one, `push` (DESIGN 11.10); the user's guide, [GUIDE.md](GUIDE.md) 7, tells the user to copy a package's folder by hand. Open: where the list of packages shows, such as a panel of its own or a section of the project settings.
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
- **What OpenECS's dev of 2026-11-24 gives the editor.** OpenECS #276 to #320 and OpenECS-std up to f29a872 changed much that the editor stands on: Lua is LuaJIT 2.1 in place of Lua 5.5, C functions are called through LuaJIT's FFI, handles and structs are cdata, the title bar has menus, plugins add their own entries to a menu Tools and their own keys after the prefix, std's `keys` lists those keys, and the theme has new colours, JetBrains Mono at 13 and denser controls. The editor works on it; what it should use of it, each with its OpenECS section:
  - To use what it gives, most useful first:
    - **Panel types as classes** (OpenECS DESIGN 1.1, and its plugin skill). The node hierarchy, the history, the search and the three bars are classes; the inspector, the node view, the project settings and export still return plain tables with closures from `create` (`inspector.lua`, `nodeview.lua`, `settings.lua:118`, `export.lua:273`). Size: S.
    - **The link's bytes.** Each frame of the preview joins the chunks it read, cuts each block out with `sub`, and gives `gpu.texture` another copy (`runners.lua:528-553`, `link.lua:61-85`, `nodeview.lua:785`). A `string.buffer` reads the blocks in place, and a buffer may be a `string.buffer` or cdata (OpenECS DESIGN 10.7). Measure first. Size: M.
    - **The tests' checks.** `test.errors()` at the test's end checks that no plugin reported an error; `test.titleBar()` checks the title bar's menus once they are ONLR's (OpenECS DESIGN 17.5). Size: S.
    - **The profiler's functions.** `ecs.profile` now names the Lua functions that take the most time, in the profiler's Functions tab (OpenECS DESIGN 3.5): a check of the editor on a large node file needs no code. Size: S.
  - Still open from OpenECS's updates of 2026-11-15 to 18: the console's double click goes to a file and line, so the game's errors and `print`s name the project's file from the project's folder, `components/player.lua:12:` (DESIGN 12.2), to check with a stack's lines; the key list shows ONLR's functions by their names, so each name says what it does to a user; `ui.graph` could show the running game's frame times, sent through the link, for later.
- **What OpenECS-std needs.** The editor needs these of the standard plugins, which do not have them yet. ONLR's work makes them there, as CLAUDE.md says, when that is better than working around them:
  - fs: a file's permissions. Until it tells them, the Linux build marks as programs LÖVE's launcher, the files of `bin/` and the libraries.
  - fs: watching the folders inside a folder, for the project's folder, which also follows a folder that is removed and made again, as a checkout of git does, and reads a folder again after an overflow. The editor's own watching misses both (see [Review](#review), Editor), and the files panel watches the same folders.
  - The files panel: another plugin says how a kind of file opens, such as a node file in a node view, which new files it makes, such as a script from a template, and hears what it renames, moves and deletes, so the editor changes the paths that name them (DESIGN 13.7).
  - fs: moving a file to the system's trash, for the files panel.
  - video: Ogg Theora, which LÖVE plays, for later (see [Editor](#editor)).
  - gpu and ui: what the graph panel needs, milestones 3 to 5 of "Shaders and graphs" below.
  - ui: a field and a number field that tell when they lose the keys, so the inspector takes a typed value without Return; a click twice on a tree's node, apart from one click, so the files panel need not time a second click itself (DESIGN 13.7).
  - The tool's menu: entries that a plugin gives while it runs, for the projects opened last (DESIGN 13.2).
  - The core: a panel hears where dragged data is over it, so the node hierarchy shows a line where a dragged node will land. While data is dragged, the core gives no panel the pointer's moves (OpenECS DESIGN 7.9).
  - The test's `dropFiles` gives a node view a place 26 units above the pointer's, the height of a tab row then. Checked in `samples/editor/editortest.lua`, which drops an image at y 150 and gets 124. A tab row is 24 units now: check it again once the test runs on OpenECS's dev.
- **Shaders and graphs.** The milestones of DESIGN 6.7, 6.8, 10's `onlr.shader` and 13.9, in order: each builds on the ones before it, apart from 3 to 5, which are OpenECS-std's and can run beside 1 and 2. Each ends with its tests, its gallery room when a game shows it, GUIDE's steps checked in the editor, and screenshots, as CLAUDE.md says. Size: S is one small pull request, M one large or a few, L several.
  1. **Shaders in the engine.** `onlr.property.shader` of GLSL files; `onlr.shader` with `draws` and `picture`, its `values` read from the `extern`s, and `time`; the engine setting the shader back after each `draw` (DESIGN 6.3); a shader's errors with its file and line. A sample, `samples/shaders`, whose test checks both ways, the values a script sets, and the shader set back; a room of the gallery. Size: M.
  2. **Shaders in the editor.** The preview's answer of a shader's values and its check as GLSL ES (DESIGN 12.5); the inspector's rows of `values`; `drawTreeEditor` (DESIGN 6.5) and `time` while chosen; the console's warning of a shader that a phone cannot run; GLSL files opening in the code editor. An editor test that sets a value and checks the node file. Size: M.
  3. **OpenECS-std: gpu draws what ui needs.** Outlines, rounded rectangles and their outlines, circles, clipping and styled text, as draw has them, from C and Lua, with a test in OpenECS-examples. Size: M.
  4. **OpenECS-std: ui on a GPU surface.** ui draws with gpu when its panel's surface is a GPU one, and with draw otherwise, every frame whole on the GPU, with its popups still on pixels. A test in OpenECS-examples that shows one panel both ways, and a measure of a full panel's frame both ways with the profiler. Size: M to L.
  5. **OpenECS-std: ui's element of blocks and wires.** Blocks at places, holding ui's elements; pins and wires between them; moving the view, zooming, choosing with a click, Shift and a rectangle, dragging blocks, and drawing a wire from a pin. Its name is std's to choose: not `canvas`, LÖVE's word in ONLR's documents, nor `graph`, which ui has, so perhaps `ui.board`. From C and Lua, with a test in OpenECS-examples, and measured on a board of 200 blocks. Size: L.
  6. **Graphs: the file, the panel and the engine's builder.** The format (DESIGN 6.8); `library/graph.lua`, which builds code and names the block of a line; the preview's answers of the types of blocks; `plugins/onlr/graph.lua` (DESIGN 13.9) with the list of blocks, wires, the properties' list, the history, saving, and the files panel's New Ira-Script and New Ira-Shader. Tested with a few blocks of maths, before either kind is whole. Size: L.
  7. **The ira-shader.** Its blocks, `input`, `property`, `math` and `output`; building GLSL ES 1.00; the preview in the panel (`shaderView`, DESIGN 12.2); Copy as GLSL. A sample's test that builds a graph and compares its pixels with a GLSL file's, and a room of the gallery. Size: M.
  8. **The ira-script.** Graphs as component types in `ira-scripts/` (DESIGN 6.1); its blocks but `delay` and `every`; building Lua; errors that name the block, and the console's link to it; Copy as Lua Script. A sample's test of a graph and a script on one node, and a room of the gallery. Size: L.
  9. **Delays and timers.** `flow.delay` and `event.every`, which wait across frames, and wait while paused or off (DESIGN 6.8). Tests of a delay started twice, and of one whose node is paused. Size: M.
- **New Project has no test.** A test of OpenECS runs only functions that take nothing (`test.call`) and cannot answer the system's file dialogs, so `samples/editor` cannot make a new project and read its manifest (DESIGN 13.2). A `test.call` that passes arguments, or a test's answer to a file dialog, in OpenECS, would let it.
- **The gallery has no test of the editor.** `samples/gallery` is tested in LÖVE only. An editor test can click and read the files the editor writes, but cannot read the nodes that the preview draws, so it cannot check that each room opens and shows in a node view. A function of the test that returns the preview's nodes, or a screenshot compared with a saved one, would let it.
- **The editor on Windows is not tested.** The paths, the rename over a file when a data file is saved, and starting the runners were written on Linux.
- **What the editor does not do yet.** Offering to move a project that names another version of LÖVE (DESIGN 15.1) is not written.
- **The tests on Windows.** `shuild.c` runs them on Linux only: they need SDL's offscreen driver, and set variables as a POSIX shell does.
- **A warning when a popup opens.** On the owner's computer, a dropdown logs "[ecs] The GPU cannot present to a window (The GPU API doesn't support transparent windows)". It is OpenECS's, not ONLR's: its popups ask for a transparent window.
- **The next release.** It waits for OpenECS's next release, which holds the standard plugins' `files.reveal` and what OpenECS's `dev` of 2026-11-24 gave the editor (DESIGN 17). Then `.github/workflows/release.yml` and `README.md` name it.
- **The archive on Windows is not tested.** `ONLR.cmd`, the LÖVE in `love/` that the runners find, and `--install`'s shortcut were made on Linux. `ONLR.cmd` shows a console for a moment; a small program in its place, or OpenECS starting a preset beside its executable, would not.
- **The Linux runtime has no address.** DESIGN 15.2 downloads it from ONLR, which hosts the contents of LÖVE's AppImage as a `.tar.gz`. Nothing hosts it yet, so `plugins/onlr/runtimes.lua` has no address and no hash for it. Until then a Linux build uses the LÖVE that runs the preview and the game, when it is an unpacked AppImage, or the folder that `onlr.linuxRuntime` names. The AppImage's own SHA-256 hash is `65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00`.
- **Export on Windows is not tested.** The user's data folder there, `%APPDATA%`, and a Linux build made on Windows, which cannot find LÖVE's AppImage.
- **OpenECS's TODO.md** still lists this editor's open questions. Replace them there with a link to this repository.
- **Rulesets.** `.github/rulesets/` holds the rules of `dev` and `main`. The owner imports them in the repository's settings.

## Review

Recommendations from the review of 2026-11-24, by area, the most important first. P1 is a bug, or a design flaw that gets harder to fix with each feature; P2 is worth doing before ONLR's first release; P3 when the code is touched. Each was checked at the lines it names. Times are of OpenECS's Release build and LÖVE 11.5, run offscreen. Measured and fine: `samples/speed`'s 5000 sprites draw in one batched draw call, 2.81 ms a frame, with 0.79 ms of update.

**Engine**

- **P2 · Each change of the tree builds every list and draw group again.** `life.lua:68-72`, `:362-387`, `:498-544` Measured on `samples/speed`, middle of three: a frame takes 0.66 ms of update and 2.45 ms of draw; with 20 nodes spawned and 20 destroyed in each frame, 1.66 ms and 4.94 ms, and 0.50 ms at the frame's end, a quarter of it in three walks of the whole tree (`rebuildDraw`, `waiting` at `:298-318`, `rebuild`). One `setZ` a frame costs as much, since it marks the update lists too (`node.lua:280`). DESIGN 8.2 says only a list that changed is built again. A removed record is already passed over by `live` and `drawn`, so removing needs no build; `setZ` marks only the draw lists; a branch added last in the tree's order, as a spawn under the root is, joins the lists' ends. Size: M.
- **P3 · Shapes and fonts make garbage at each draw.** `components/shape.lua:35-60` builds an outline and a list of points for each shape at each draw, a rectangle too; `library/data.lua:161` makes a table and a key for each `data.load("font")`, which `font.sharp` (`font.lua:38`) calls for each scaled text at each frame. Not measured. Size: S.
- **P3 · Two errors mislead an author.** `tree.lua:159-163` `spawn` and `newNode` without a parent while the top node loads say "the parent is no node of the tree", not that the root is not loaded yet. Size: S.

**Runner and link**

- **P2 · Watching the running tree takes 14 ms four times a second.** `plugins/onlr/runner/game.lua:41-58`, `:183-191` Each quarter second the game makes a table for each node and writes the whole tree, to compare it with the last. Measured on `samples/speed`: 13.81 ms, middle of three, the first message 570 KB, against a frame of 3 ms; it also skews the frames a second that the tools show. Keep a number in `life` that each change of the tree raises, and write the tree only when it changed. Size: M.
- **P2 · The two ends write the link's messages each in its own way.** `plugins/onlr/runner/link.lua:159` and `plugins/onlr/link.lua:13` already differ (`%d` and `%.0f`). One file that both load, with the module of instances under Editor. Size: S.
- **P2 · The editor keeps every line a runner prints.** `plugins/onlr/runners.lua:519-523` A game that prints at each frame grows the editor's memory for its whole run, and a preview that ends shows every line since its start as errors (`:551-553`). Its two seconds of waiting are measured with `os.time()`, so 2 to 4 seconds (`:556`). Keep the last lines only, and a clock finer than a second. Size: S.
- **P3 · The preview makes much at each draw.** `preview.lua:49-68` `ordered()` makes a table for each node and sorts with a closure at each draw, twice when bounds are due (`:124`, `:178`); each node's parents are walked for the hidden ones (`:181-185`); a frame's header is joined to its whole block of pixels, another 8 MB copy for each frame (`:220`). Keep the order until the nodes change, and send the header and the block apart. Not measured. Size: S.

**Editor**

- **P2 · A change makes its file's tree and text again whole.** `project.lua` After the P1 of 2026-11-25 (DESIGN 13.1), a drag of one node of `samples/speed`'s 5000 takes about 115 ms (Release, middle of three): the node hierarchy makes the file's tree again (17 to 78 ms, by where the garbage collector runs), `refresh` writes the whole file, and the editor reads the preview's frames, each copied twice (`runners.lua:579-581`, `link.lua:76-78`; see P3 under Runner and link). A tree changed in place by the edit, and a frame read without joining, would take most of it. Size: M.
- **P2 · The node view's draw grows with the chosen nodes times the nodes.** `nodeview.lua:563` For each node, `isChosen` reads the chosen list, and `isMarked` (`:55-65`, 5% of the time above) walks up its parents through the settings; `hits` does so twice (`:349`), `outline` makes five tables for each chosen node at each draw (`:651-664`), and `startToolDrag` checks each chosen node's parents against the others (`:838-843`). With Ctrl+A on 5000 nodes, that is 25 million checks a frame. Keep a set of chosen paths and one of hidden or locked paths, with their children, made again when the choice, the settings or the nodes change. Size: S.
- **P2 · Data files can change the editor's `string`.** `plugins/onlr/format.lua:190-208` A node file's environment hides the editor's globals, but `getmetatable("").__index` is the editor's `string` table, so a file can remove `string.upper` for the whole editor; the engine's `packages/onlr/library/data.lua` has the same opening. DESIGN 4.1 says a file changes nothing outside it. Give a file's strings no way to the table, or check the file's text for `getmetatable` and `setmetatable` before it runs. Size: S.
- **P2 · The project's watching misses folders that go and come back.** `project.lua:640-659` std's `fs` reports `gone` and `overflow` with an empty name (OpenECS-std DESIGN 20); the editor takes them for a change of a file named `dir/`, keeps the folder's watch forever, and so never watches a folder that git removed and made again, and reads nothing again after an overflow. A watch that failed is hidden by `or true` (`:576-638`). Forget the watch on `gone` and read its parent again; read the folder again on `overflow`. Better, as the files panel watches the same folders: a watch of a folder and the folders in it in std's `fs` (see [Tasks](#tasks), "What OpenECS-std needs"). Size: M.
- **P2 · Unsaved changes are lost without asking when their file is deleted.** `project.lua:593-598` A node file with changes that is deleted on disk loses them and their records; DESIGN 13.6 says the editor asks when both sides changed. After "Keep the editor's" (`:607-608`), only `file.disk` is updated, and `handwritten` keeps the old text's value, so a later save may overwrite what a person wrote, without asking. Ask in both cases, and work `handwritten` out again from the new text. Size: S.
- **P2 · The editor repeats the engine's instances and data files.** `plugins/onlr/resolve.lua:166-370` repeats `packages/onlr/library/build.lua:85-190`, the same walk over the changes, and `format.lua:186-240` repeats `data.lua:10-62`. DESIGN 9 lives in two places that must agree. Both run on LuaJIT now, so the reason they were apart, DESIGN 4.1's two Luas, is gone. One module of `packages/onlr/library` that both load, which takes the editor's own maker of nodes. Also `inspector.lua:25-62` repeats `format.same` and `format.copy`. Size: L.
- **P2 · A right click in a node view whose file has an error raises one.** `nodeview.lua:1133`, `:1138` Both read `project.tree(view.file).first.path`, and `first` is nil when the file does not load, such as with git's conflict marks, which the view shows (DESIGN 4.2). Check it, as `drop` does (`:1054`). Size: S.
- **P2 · A drop on the inspector checks the wrong file, and drops of outside files do nothing.** `inspector.lua:828` A node dropped on a reference is looked for in `shared.file()`, not in the file of the inspector's nodes, so with the inspector locked on another file nothing happens and nothing says why. A file from outside the project dropped on a file's row is passed over (`:811-815`), though DESIGN 13.4 says it is copied in. Keep the file in each drop's entry, and bring an outside file in with `project.bringIn`. Size: S.
- **P3 · Delete runs `gio trash` and waits, on Linux only.** `project.lua:1887` On Windows and macOS a file goes to `.onlr/trash/`, though they have a trash (DESIGN 13.7). A trash in std's `fs` (see [Tasks](#tasks), "What OpenECS-std needs"). Size: S.
- **P3 · A tooltip and a comment name the wrong keys and tools.** `tools.lua:79-83` The tooltips of Play, Pause, Step and Stop name F5 to F8 and Shift+F5, which only the node view binds (`nodeview.lua:1665-1675`). `project.lua:2040` lists the tools as move, turn, scale or shape, without `rect`. Size: S.

**Export**

- **P2 · Getting a runtime breaks easily.** `plugins/onlr/runtimes.lua:159` Every download is unpacked as a zip, though the Linux runtime is a `.tar.gz`; a cut unpack is taken as whole for ever (`:87-90`); two clicks start two downloads into one folder. Unpack by format into a folder of its own, rename it into place, and run one download for each platform. Size: S.
- **P3 · Export holds the whole project in memory, on the editor's thread.** `export.lua:107`, `:189-216` The editor stops while it writes. OpenECS's workers now take buffers (OpenECS DESIGN 3.3), so an export can run beside the editor. Size: M.

**Packages**

- **P3 · bump's body and shadows' caster make outlines at each frame.** `bump/components/body.lua:75` and `shadows/components/caster.lua:256-262` call `onlr.shape:outline()`, which makes tables, at each frame, as physics did before 2026-11-25. Compare the shape's values in place, as `physics/find.lua`'s `start`, `note` and `finish` do. Not measured. Size: S.
- **P2 · A package's version is its library's.** `packages/bump/manifest.lua:8` A changed `bump.body` with the same bump 3.1.7 has the same version, so the editor cannot offer it (DESIGN 11.2), and nothing offers it yet (`project.lua:722-789`). Decide before the first release: ONLR's own version, with the library's in a field of its own. Size: S.
- **P2 · Some properties are read only at the start, unsaid.** `physics/components/world.lua:18-20` (`gravity`), `push/components/screen.lua:28-36`, `sti/components/bump.lua:155`, `sti/components/physics.lua:212-214`. Apply them as `physics.body` does, or write them into DESIGN 11's limits. Size: S.
- **P2 · The light's `arc` is in degrees.** `packages/shadows/components/light.lua:15-18` DESIGN 1 says angles are radians; it is the only property in degrees. Size: S.
- **P3 · Packages fail on the top node while it loads.** `bump/components/body.lua:18`, `physics/components/body.lua:38`, `shadows/components/world.lua:112` add their world to `onlr.tree.root`, nil then (DESIGN 5). Say it in DESIGN 11.3, or check it. Size: S.

**Samples and build**

- **P2 · Each sample's packages are listed in three places, already apart.** `shuild.c:38`, DESIGN 16, `.luarc.json:3`. DESIGN gives `tilemap` only sti. Glob `packages/*/library` in `.luarc.json` and let DESIGN name shuild's list. Size: S.
- **P2 · The editor's test depends on the computer.** `samples/editor/editortest.lua:1053-1068` The Linux build passes only when `LOVE` is an unpacked AppImage, as CI has it, and the Windows build downloads 10 MB into the user's own `~/.local/share/onlr`. Set `XDG_DATA_HOME` in shuild's tests, and say what the test needs in DESIGN 16. Size: S.
- **P3 · CI and releases.** `checks.yml:101` downloads LÖVE without checking its hash; `checks.yml:91` takes OpenECS's default branch, not the built commit; `release.yml` does not need the checks to have passed; `check.sh:49-57` ignores the Lua check's exit status. Size: S.

**Guide and keys**

- **P2 · The project opened last is forgotten.** `project.lua:2163-2172` keeps the open project and the projects opened last in the plugin's state, which OpenECS restores only with `ecs.keepSession`, off by default (OpenECS DESIGN 13.4); the preset does not set it. So DESIGN 13.2's "the editor starts with the project it was closed with" and the project settings' list of projects opened last do not hold, nor do the locks kept in the session (13.4, 13.7). Keep them in ONLR's own file in the user's data folder, or set the setting in the preset. Size: S.
- **P2 · GUIDE 1.4 misses Id and Game version** (`settings.lua:165-166`), and GUIDE 9 does not say that a Linux build needs LÖVE's unpacked AppImage until the Linux runtime has an address (`runtimes.lua:29`). Size: S.

**Runner and link, documents**

- **P2 · DESIGN 12.2's table of messages misses `halted` and `hello`**, which `plugins/onlr/runner/init.lua:76` and `runners.lua:430` send, and the fields `hidden` and `closed` of `view` and `tree` of `watch` (`runners.lua:222-223`, `:305`, `:489`). Size: S.
- **P2 · DESIGN 12 says what the code does not do yet.** Start the Preview Again has no button or menu, only the search and the key list (`nodeview.lua:1574`); the preview's printed lines reach the console only when it stops (`runners.lua:518-519`); the Linux runtime has no address, and would be unpacked as a zip (DESIGN 15.2); the offer to move a project to another LÖVE is not written (DESIGN 15.1). Write each as a limit where it is described. Size: S.
- **P2 · Colours are written out.** `#e06c75` and `#98c379` in the node hierarchy, the tools, the settings, the inspector and the node view, and the node view's grid in `#ffffff10` and `#ffffff60`, stay the same in OpenECS's light theme (OpenECS DESIGN 12.4). Use the theme's names where they exist, and check the light theme by a screenshot. Size: S.

**Releases and this file**

- **P3 · Items of this file that are done or out of date.** the files panel's handlers exist (`files.setHandlers`); the tool's menu takes plugins' entries now (`ecs.app.addMenuEntry`), though not ones that change while the tool runs; Libraries names `shadows.shape.box` and physics' folders, which are `shadows.caster` and flat now. Size: S.

**Engine, documents**

- **P2 · A kept node runs after the root.** `packages/onlr/library/node.lua:96-103` `node:setParent(onlr.tree.top)`, DESIGN 5's way to keep a node, puts it after the root, so it updates and draws after it; DESIGN 5 says the root is the top node's last child. Insert kept nodes before the root. Size: S.
- **P2 · DESIGN 11.11 and 11.12 say components run by their names.** `componentOrder` orders them now (DESIGN 5, `component.lua:365-399`); `audio/components/listener.lua:49` says the same. Size: S.
- **P3 · Smaller differences.** OVERVIEW 7 lists the tools without Rect and Shape and has no History panel; DESIGN 3.2's reversed-domain `id` against the folder's name that `project.lua:875` writes; DESIGN 8.3 misses `paint.lua`; DESIGN 10 says paint, follow and shake have `bounds`; DESIGN 6.4 says a new order waits for the next frame, which `life.lua:398-400` does not; DESIGN 11.6 and 11.9 miss `sizeVariation`, `spinVariation`, `getRaw` and `getJoystick`; DESIGN 14.2 against the tooltip "an AppImage" (`export.lua:287`); `samples/check.lua:1` and `samples/animation/test.lua:1` name the wrong script and section. Size: S.
