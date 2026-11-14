# ONLR TODO

What is not decided yet, and work that is waiting. When an item is settled, write the decision into [OVERVIEW.md](OVERVIEW.md) or [DESIGN.md](DESIGN.md), where it belongs, and remove it from here.

## Next

What the owner wants worked on, in this order.

1. **One plugin.** `onlr_project`, `onlr_player`, `onlr_views` and `onlr_export` become one plugin, `onlr`, with a file for each part. The plugins that know nothing of ONLR stay apart, and move to OpenECS-std (see [Tasks](#tasks)). DESIGN 13.1 changes with it.
2. **Menus, not rows of buttons.** A right click opens a menu in the files panel, the nodes panel, the inspector and the node view, and it takes the place of the buttons there. Every control has a tooltip. The tool's menu holds only what belongs to the whole project, such as New Project, Open Project, Save All and Play; what belongs to one panel is in that panel's menu.
3. **The editor's look and use.** The owner's wishes are under [Editor](#editor).
4. **The Windows experiment.** The owner runs it later, and reports what it prints (see [Tasks](#tasks)). Until then, the edit player on Windows is built as DESIGN 12.1 says, and not tested.
5. **Which libraries.** How a library meets the engine is designed (DESIGN 11). The candidates are under [Libraries](#libraries); none is chosen.
6. **Linux and the `.love` file first.** Windows follows. macOS and Android are noted for later (see [Export](#export)).

## Engine

- **Components for sound, animation and particles.** Ideas. Libraries come first (OVERVIEW 9): anim8, or peachy for Aseprite's files, to animate a sprite through its `quad` (DESIGN 10); ripple for sounds and their volumes; and LÖVE's own particle systems, whose settings Hot Particles edits. A sound property already streams with the option `stream` (DESIGN 6.2), and a node under the top node plays music for the whole game (DESIGN 5).
- **Tags.** A component type serves as a tag (DESIGN 7). An idea for later: tags or groups of their own. `onlr.tree.findAll` and `findAllComponents` stay so that a function that finds by tag can join them.
- **Loading.** A root's files are loaded when the root loads, and those that the next root does not name are let go (DESIGN 6.2). An idea for later: reading a big root's images and sounds in a thread, while a picture of progress shows, as love-loader and lily do.

## Player and link

- **The edit player on Windows.** SDL's offscreen driver gets OpenGL only through EGL, and LÖVE's runtime for Windows holds no `libEGL.dll`. The owner's experiment showed it, with LÖVE 11.5 and an NVIDIA card: with the offscreen driver LÖVE stops with "Could not initialize OpenGL / GLES library", and shows a message box that waits for a click; with SDL's normal driver it gets OpenGL 3.3. So the edit player does not start on Windows as DESIGN 12.1 starts it on Linux.

  The second experiment checked a normal window that the engine hides at once, with SDL's `SDL_HideWindow` through LuaJIT's FFI: LÖVE reports it hidden, it draws into a canvas, and reads the canvas back right. DESIGN 12.1 takes this way. But a black window shows for a moment, between LÖVE opening it and the engine hiding it, and the edit player starts again at every change of a script (DESIGN 12.5). The next experiment opens the window outside the screen, borderless and one pixel wide, then hides it (see [Tasks](#tasks)). If it still shows:
  - ANGLE's `libEGL.dll` and `libGLESv2.dll` beside LÖVE's files in ONLR's archive. LÖVE itself stays unchanged. The edit player then draws with OpenGL ES over Direct3D, not with the OpenGL of the exported game, so a shader may look different in the node view. The offscreen driver also asks EGL for its list of devices, which ANGLE may not give.
- **The offscreen driver elsewhere.** It is checked on Linux with an NVIDIA card, with the system's LÖVE 11.5 and with LÖVE's own AppImage, and on a computer with no display and no graphics card, where Mesa draws in software. It needs the system's EGL library. Not checked: Intel and AMD cards.
- **How fast frames travel.** Reading a 1280×720 frame back takes about 1.4 ms with a graphics card on Linux, and 0.7 ms on Windows with an NVIDIA card. Making a Lua string of it and sending it with LuaSocket take about 5 ms more, so the sending side passes 60 frames a second. Receiving a frame and showing it in a panel is not measured. Ways to make it cheaper: a texture of OpenECS-std's gpu plugin, which is uploaded once and scaled by the graphics card; sending straight from the frame's memory with LuaJIT's FFI, without the string; shared memory; sending only when the picture changed.
- **The game in a panel.** Play shows the game in LÖVE's own window, and only what a mode draws into differs between the modes (DESIGN 12.1). Showing the game in a panel is an idea for later. What it needs:
  - Frames from the play player. `love.graphics.captureScreenshot` reads the window's picture, also when there is no window, so the game draws as always. Drawing into a canvas of the engine's instead would break a game that sets canvases of its own.
  - A pace. Without a window LÖVE does not wait for the screen, and runs hundreds of frames a second.
  - The panel's keys, text and pointer, sent to the game, and the engine answering for `love.keyboard.isDown`, `love.mouse.getPosition` and the like. Also the pointer's modes, gamepads, the desktop's size, and the keys that the editor takes before a panel gets them.
- **Reloading while playing.** For later. A changed script or image takes effect in the running game without a restart. Open: what happens to the values a component keeps.
- **Previews of node files.** For later. A small picture of a node file, such as in the files panel, would be a view that the edit player draws (DESIGN 12.3). No panel shows one: the files panel and the asset viewer know nothing of ONLR. The edit player draws when asked and updates nothing, so a preview of an animation or of particles would stand still.
- **A debugger.** Stopping at a line and reading variables. Not planned; an error's file, line and stack are shown (DESIGN 12.2).

## Editor

- **A number that a drag changes.** A drag over a number field's label, or over the field, changes the number, as in Unity. It belongs in OpenECS-std's ui, as a property of its number field, so every tool gets it.
- **Undo of what is chosen.** Choosing nodes is a record of the history too, so undo gives the last chosen nodes back. Open: whether such a record stands between the records of changes, as in Unity, or in a history of its own. Between them is simpler to use: one key walks back through everything that the user did. A record of choosing never marks a file as unsaved.
- **The files panel's views.** Icons for kinds of files, small pictures of images, and a view of a folder as a grid, as a file manager shows it, beside the tree. It belongs to the files panel that moves to OpenECS-std.
- **The console's entries.** Each entry is a box of its own, with its level's colour, its time and its place. Equal entries stack with a count. The console clears when the game plays, as a toggle, and filters by level. It belongs to the console that moves to OpenECS-std.
- **More hints for errors.** The hints are a list of patterns (DESIGN 13.1). To add: errors of LÖVE's own functions, and a hint that names the node and the component that the error came from, with a click that chooses the node.
- **From Unity.** What its editor has that ONLR's lacks, as candidates. None is decided.
  - The node view: handles that move along one axis, and a rectangle tool that sizes a node by its corners; a key that fits the view to the chosen nodes; a switch between each node's own place and the middle of the chosen ones as the pivot; a key that holds snapping; marks for nodes that draw nothing, with a toggle; a picture of what each camera sees.
  - The nodes panel: a search by name and by component type; a drag that moves a node in the tree; choosing many nodes; renaming with F2; an eye that hides a node in the node view only, and a lock that keeps it from being chosen there; a mark and another colour for an instance; a button that opens the instance's node file.
  - The inspector: a lock that keeps its node while another is chosen; folding, reordering, copying and pasting a component's values; Add Component as a search; sums in number fields, such as `32*4`; a round button that picks a node or a file for a reference; a colour picker with a pipette; a list of an instance's changes, to keep or drop them all. A property's declaration could name a range, which shows a slider, a tooltip, and a heading above it.
  - The files panel: a search by name and kind; favourite folders; the path as a row of folders to click; Show in the file manager; Find what names this file.
  - The console: a click on an entry chooses the node that the error came from; a pane with the stack of the chosen entry; a search; Pause on Error.
  - Playing: a tint over the editor while the game plays; the count of frames a second and the time of update and draw, from the play player; sizes of the window to choose from, such as a phone's; values that were changed in the running game, with a way to keep them.
  - The editor: a list of the history's records, to jump back to one; a search over every function, node and file with one key; a window for keys.
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

- **Which libraries.** None is chosen. A library works in a project as it is, and a package is made for it only when it is chosen (OVERVIEW 9). A library fits ONLR when:
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
  | Debugging                   | lovebird; lurker                               | lurker swaps changed files in a running game, which may clash with the engine's loaded types (see [Player and link](#player-and-link), reloading while playing). |

  Whichever library gives bodies, its world is a component of what a root has one of, and contacts reach scripts with `node:send`, as DESIGN 11.3 shows.

  hump, HC and moonshine name no licence that GitHub reads. It is checked before one is chosen.

  Libraries of entities and of classes, such as tiny-ecs, Concord, middleclass and classic, overlap ONLR's own nodes and components. A user may still use them in scripts, and no package is made for them.
- **A bump package's details.** DESIGN 11.3 shows its outline as a sample, and `samples/coinrun` holds one that works: its body has `solid`, and other bodies pass through one that is not solid. Open if bump is chosen as a package of ONLR's own: a body on a node that is turned or scaled, since bump's boxes are not.

## LÖVE

- **LÖVE 12.0.** It is not released. It changes the default font, removes functions that 11 deprecated, and builds on SDL3. When it is released: which versions a project may name, and whether the engine serves both.

## Tasks

- **The edit player's hidden window on Windows is not tested.** `player/edit.lua` hides LÖVE's window with `SDL_HideWindow` through LuaJIT's FFI, as DESIGN 12.1 says. It was written on Linux, where the offscreen driver is used, and never run on Windows.
- **The Windows experiment.** It tells whether the edit player's window can open on Windows without showing for a moment (see [Player and link](#player-and-link)). The owner runs it in the command prompt:
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
- **What OpenECS-std needs.** The editor needs these of the standard plugins, which do not have them yet. They are the owner's too, so they change when that is the better solution:
  - net: listening on one address, `127.0.0.1`, and telling the port that was chosen (DESIGN 12.2). It listens on every address today, and does not tell the port. Until it does, the engine could listen and print its port.
  - process: environment variables for the program it starts, for `SDL_VIDEODRIVER` (DESIGN 12.1). Until it has them, `env` starts the player on Linux and `cmd /c` on Windows.
  - compress: writing and reading tar, for the Linux build's `.tar.gz` (DESIGN 14.2) and the Linux runtime (DESIGN 15.2). Until it does, `plugins/onlr_export/tar.lua` writes one.
  - fs: a file's permissions. Until it tells them, the Linux build marks as programs LÖVE's launcher, the files of `bin/` and the libraries.
  - ui: a tree that chooses many nodes and drags them, for the nodes panel.
  - fs: watching the folders inside a folder, for the project's folder.
  - The files panel: another plugin says how a kind of file opens, such as a node file in a node view, which new files it makes, such as a script from a template, and hears what it renames, moves and deletes, so the editor changes the paths that name them (DESIGN 13.7).
  - fs: moving a file to the system's trash, for the files panel.
  - video: Ogg Theora, which LÖVE plays, for later (see [Editor](#editor)).
  - ui: a menu that a right click opens, from a list of entries, and a number field that a drag changes (see [Next](#next) and [Editor](#editor)).
  - ui: a field and a number field that tell when they lose the keys, so the inspector takes a typed value without Return; a click twice on a tree's node, apart from one click, so the files panel opens a file only then; a control for a colour.
  - The tool's menu: entries that a plugin gives while it runs, for the projects opened last (DESIGN 13.2).
  - The test's `dropFiles` gives a node view a place 26 units above the pointer's, the height of a tab row. Checked in `samples/editor/editortest.lua`, which drops an image at y 150 and gets 124.
- **Move to OpenECS-std: the files panel.** `plugins/files` knows nothing of ONLR (DESIGN 13.1).
- **Move to OpenECS-std: the asset viewer.** `plugins/viewer` knows nothing of ONLR.
- **Move to OpenECS-std: the console.** `plugins/console` knows nothing of ONLR.
- **The editor on Windows is not tested.** The paths, the rename over a file when a data file is saved, and starting the players were written on Linux.
- **What the editor does not do yet.** Dragging a node in the nodes panel to move it in the tree, and choosing many nodes there, wait for ui's tree. Copying LÖVE's definitions into a new project's `.onlr/` takes them from `build/love2d/`, until ONLR's archive holds them. Offering to move a project that names another version of LÖVE (DESIGN 15.1) is not written.
- **OpenECS as a submodule.** A question for the owner (see the report of the session that added `shuild.c`). Today OpenECS's release is unpacked into `OpenECS/` by hand, and the checks build OpenECS's newest `dev`. With a submodule at a fixed commit, `shuild.c` would build it, and the checks would test against the same OpenECS as everyone.
- **The tests on Windows.** `shuild.c` runs them on Linux only: they need SDL's offscreen driver, and set variables as a POSIX shell does.
- **A warning when a popup opens.** On the owner's computer, a dropdown logs "[ecs] The GPU cannot present to a window (The GPU API doesn't support transparent windows)". It is OpenECS's, not ONLR's: its popups ask for a transparent window.
- **ONLR's archive.** How the one archive of OVERVIEW 2 is made: OpenECS's release, ONLR's plugins and preset, the engine, the player's files, and LÖVE's runtime for the host, and the Linux runtime that ONLR hosts (DESIGN 15.2).
- **The Linux runtime has no address.** DESIGN 15.2 downloads it from ONLR, which hosts the contents of LÖVE's AppImage as a `.tar.gz`. Nothing hosts it yet, so `plugins/onlr_export/runtimes.lua` has no address and no hash for it. Until then a Linux build uses the LÖVE that runs the players, when it is an unpacked AppImage, or the folder that `onlr_export.linuxRuntime` names. Unpacking a `.tar.gz` also waits for compress to read tar. The AppImage's own SHA-256 hash is `65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00`.
- **Export on Windows is not tested.** The user's data folder there, `%APPDATA%`, and a Linux build made on Windows, which cannot find LÖVE's AppImage.
- **OpenECS's TODO.md** still lists this editor's open questions. Replace them there with a link to this repository.
- **Rulesets.** `.github/rulesets/` holds the rules of `dev` and `main`. The owner imports them in the repository's settings.
