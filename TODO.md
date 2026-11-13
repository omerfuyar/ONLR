# ONLR TODO

What is not decided yet, and work that is waiting. When an item is settled, write the decision into [OVERVIEW.md](OVERVIEW.md) or [DESIGN.md](DESIGN.md), where it belongs, and remove it from here.

## Next

What the owner wants worked on, in no fixed order.

- **The plan.** ONLR is being planned. No code is written until the owner says the plan is done.
- **The Windows experiment.** The owner runs it and reports what it prints (see [Tasks](#tasks)). Remind the owner of it.
- **To discuss with the owner.** Later, when the owner asks: names, the engine's namespaces, functions and names all together. Among them: the root, which is not the top of the tree (DESIGN 5).
- **The engine's concepts first.** What is open under [Engine](#engine) is settled before a library's pack is designed, since packs are built on the engine.
- **Which libraries.** How a library meets the engine is designed (DESIGN 11). The candidates are under [Libraries](#libraries); none is chosen.
- **Linux and the `.love` file first.** Windows follows. macOS and Android are noted for later (see [Export](#export)).

## Engine

- **From the window to the world.** The pointer's place, which `love.mouse.getPosition` and `mousepressed` give, is in the window's pixels. A node's place is in the world, which a camera moves, turns and zooms (DESIGN 10). To know which node a click is on, a script turns the pointer's place into the camera's group, and back for the other way. A camera library has such functions, such as gamera's `cam:toWorld`, and so does a scaling library, such as push's `push:toGame`. The camera's two functions wait for the talk on names.
- **Components for sound, animation and particles.** Ideas. Libraries come first (OVERVIEW 9): anim8, or peachy for Aseprite's files, to animate a sprite through its `quad` (DESIGN 10); ripple for sounds and their volumes; and LÖVE's own particle systems, whose settings Hot Particles edits. A sound property already streams with the option `stream` (DESIGN 6.2), and a node under the top node plays music for the whole game (DESIGN 5).
- **Tags.** A component type serves as a tag (DESIGN 7). An idea for later: tags or groups of their own. `onlr.node.findAll` and `findAllComponents` stay so that a function that finds by tag can join them.
- **Loading.** A root's files are loaded when the root loads, and those that the next root does not name are let go (DESIGN 6.2). An idea for later: reading a big root's images and sounds in a thread, while a picture of progress shows, as love-loader and lily do.

## Player and link

- **The edit player on Windows.** SDL's offscreen driver gets OpenGL only through EGL, and LÖVE's package for Windows holds no `libEGL.dll`. So the edit player most likely does not start on Windows as DESIGN 12.1 starts it on Linux. The owner's experiment tells (see [Tasks](#tasks)). None of these ways is checked:
  - A normal window that the engine hides at once, with SDL's `SDL_HideWindow` through LuaJIT's FFI. The engine draws into a canvas, with the same OpenGL as the exported game. The window may flash when it opens. Recommended to try first.
  - A normal window that LÖVE's own functions move off the screen or minimize. It needs no FFI, and the window shows in the task bar.
  - ANGLE's `libEGL.dll` and `libGLESv2.dll` beside LÖVE's files in ONLR's archive. LÖVE itself stays unchanged. The edit player then draws with OpenGL ES over Direct3D, not with the OpenGL of the exported game, so a shader may look different in the node view. The offscreen driver also asks EGL for its list of devices, which ANGLE may not give.
- **The offscreen driver elsewhere.** It is checked on Linux with an NVIDIA card, with the system's LÖVE 11.5 and with LÖVE's own AppImage, and on a computer with no display and no graphics card, where Mesa draws in software. It needs the system's EGL library. Not checked: Intel and AMD cards.
- **How fast frames travel.** Reading a 1280×720 frame back takes about 1.4 ms with a graphics card. Making a Lua string of it and sending it with LuaSocket take about 5 ms more, so the sending side passes 60 frames a second. Receiving a frame and showing it in a panel is not measured. Ways to make it cheaper: a texture of OpenECS-std's gpu plugin, which is uploaded once and scaled by the graphics card; sending straight from the frame's memory with LuaJIT's FFI, without the string; shared memory; sending only when the picture changed.
- **The game in a panel.** Play shows the game in LÖVE's own window, and only what a mode draws into differs between the modes (DESIGN 12.1). Showing the game in a panel is an idea for later. What it needs:
  - Frames from the play player. `love.graphics.captureScreenshot` reads the window's picture, also when there is no window, so the game draws as always. Drawing into a canvas of the engine's instead would break a game that sets canvases of its own.
  - A pace. Without a window LÖVE does not wait for the screen, and runs hundreds of frames a second.
  - The panel's keys, text and pointer, sent to the game, and the engine answering for `love.keyboard.isDown`, `love.mouse.getPosition` and the like. Also the pointer's modes, gamepads, the desktop's size, and the keys that the editor takes before a panel gets them.
- **Looking into the running game.** Showing the tree's nodes and values in the nodes panel and the inspector, and changing them while the game plays.
- **Reloading while playing.** A changed script or image takes effect in the running game without a restart. Open: what happens to the values a component keeps.
- **Previews that move.** The edit player draws when asked and updates nothing (DESIGN 12.3). A preview of an animation or of particles needs time to pass. Open: whether a view can ask for updates of its own nodes.
- **A debugger.** Stopping at a line and reading variables. Not planned; an error's file, line and stack are shown (DESIGN 12.2).

## Editor

- **A component's own handles.** A component draws its outline in the node view with `drawEditor` (DESIGN 6.5). Open: changing its values there, such as dragging the corner of a body's box.
- **Panels for later.** Ideas, each a panel type of a plugin (DESIGN 13): a node editor, in which the user connects nodes to write logic without code, as Unreal's Blueprints do, and whose output is a script, so the engine needs nothing new; a tile editor, which waits for the choice of a library for tile maps (see [Libraries](#libraries)).
- **Video in the asset viewer.** LÖVE plays Ogg Theora video, and OpenECS-std's video reads MPEG-1 only. Open: Theora in std's video, or the asset viewer without video at first.
- **A project's own script template.** A new script starts from ONLR's template (DESIGN 13). An idea for later: a project that keeps a template of its own.
- **Node files in git.** The editor writes files so that changes merge (DESIGN 4.2). Not checked on a real merge.
- **The split into plugins.** DESIGN 13 names four. It is checked again when the first is written.

## Export

- **The Linux package on a Windows host.** LÖVE's Linux release is an AppImage, which only Linux unpacks. A Windows host needs its contents another way: ONLR hosts them as an archive, or the editor reads the AppImage's file system itself.
- **An AppImage as a Linux build.** One file is easier to hand out than an archive. Making it needs `appimagetool`, which runs on Linux only.
- **The Windows executable's icon and details.** Changing them means editing the executable's resources. On Linux that is done with a Windows tool under Wine today; a small writer of our own is the alternative.
- **Windows on 32 bits and on ARM.** LÖVE 11.5 has a 32-bit package. Not planned unless asked for.
- **macOS, for later.** LÖVE ships `love.app` in a zip; a build puts the `.love` file inside it and changes its `Info.plist`. Open: signing, which needs a Mac, and what an unsigned build shows its user. The editor itself runs on macOS when OpenECS does.
- **Android, for later.** LÖVE's Android project builds a package with the game inside. It needs a JDK, the Android SDK and Gradle on the user's computer. Open: whether the editor drives them, or only prepares the folder; touch input and screen sizes in the engine.
- **iOS, for later.** It needs Xcode on a Mac and a developer account.
- **The web.** love.js supports LÖVE 11 without LuaJIT, and is not maintained by LÖVE's team. Not planned until LÖVE has a web target of its own.

## Libraries

- **Which libraries.** None is chosen. A library works in a project as it is, and a pack is made for it only when it is chosen (OVERVIEW 9). A library fits ONLR when:
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
  | Tile maps from Tiled        | STI; cartographer                              | STI draws a map through a canvas of its own, so a pack draws its layers itself, to follow the camera.   |
  | Animation of a sprite sheet | anim8; peachy                                  | anim8 gives a quad for each frame, which `onlr.sprite` takes. peachy reads Aseprite's files.           |
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

  Libraries of entities and of classes, such as tiny-ecs, Concord, middleclass and classic, overlap ONLR's own nodes and components. A user may still use them in scripts, and no pack is made for them.
- **A bump pack's details.** DESIGN 11.3 shows its outline as a sample. Open if bump is chosen: a body on a node that is turned or scaled, since bump's boxes are not; which boxes a body passes through.

## LÖVE

- **LÖVE 12.0.** It is not released. It changes the default font, removes functions that 11 deprecated, and builds on SDL3. When it is released: which versions a project may name, and whether the engine serves both.
- **Many versions of LÖVE.** A project names its version (DESIGN 3.2), and packages are kept by version (DESIGN 15.2). Whether the editor serves a project of another version than the one it ships.

## Tasks

- **The Windows experiment.** It tells whether LÖVE's package for Windows runs without a window (see [Player and link](#player-and-link)). The owner runs it:
  1. Unpack `love-11.5-win64.zip`, from LÖVE's releases, to `C:\love`.
  2. Make the file `C:\t\main.lua` with these lines:

     ``` lua
     io.stdout:setvbuf("no")
     print(love.graphics.getRendererInfo())
     print(love.window.getMode())
     love.event.quit()
     ```

  3. In the command prompt, run `set SDL_VIDEODRIVER=offscreen`, then `C:\love\lovec.exe C:\t`.
  4. In a new command prompt, run only `C:\love\lovec.exe C:\t`.
  5. Report everything that each run prints.
- **What OpenECS-std needs.** The editor needs these of the standard plugins, which do not have them yet. They are the owner's too, so they change when that is the better solution:
  - net: listening on one address, `127.0.0.1`, and telling the port that was chosen (DESIGN 12.2). It listens on every address today, and does not tell the port. Until it does, the engine could listen and print its port.
  - process: environment variables for the program it starts, for `SDL_VIDEODRIVER` (DESIGN 12.1). Until it has them, `env` starts the player on Linux and `cmd /c` on Windows.
  - compress: writing tar, for the Linux build's `.tar.gz` (DESIGN 14.2).
  - ui: a tree that chooses many nodes and drags them, for the nodes panel.
  - fs: watching the folders inside a folder, for the project's folder.
  - The files panel, the asset viewer and the console, as first-party plugins, as its settings window is (DESIGN 13).
  - fs: moving a file to the system's trash, for the files panel.
  - video: Ogg Theora, which LÖVE plays (see [Editor](#editor)).
  - ui: what the inspector and the nodes panel need and ui lacks, found when they are written.
- **The build files.** The template's plugins, preset, test, build script, submodules, checks and Claude Code settings were removed, since nothing is built yet. When code starts, take them fresh from [OpenECS-template](https://github.com/omerfuyar/OpenECS-template), which follows OpenECS's `dev`.
- **ONLR's archive.** How the one archive of OVERVIEW 2 is made: OpenECS's release, ONLR's plugins and preset, the engine, the player's files, and LÖVE's package for the host.
- **The hashes of LÖVE's packages.** DESIGN 15.2 checks downloads against hashes that ONLR ships. They are taken once from LÖVE's releases.
- **OpenECS's TODO.md** still lists this editor's open questions. Replace them there with a link to this repository.
- **Rulesets.** `dev` and `main` have no rules in this repository yet. The owner sets them when checks exist.
