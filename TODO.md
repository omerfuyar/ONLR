# ONLR TODO

What is not decided yet, and work that is waiting. When an item is settled, write the decision into [OVERVIEW.md](OVERVIEW.md) or [DESIGN.md](DESIGN.md), where it belongs, and remove it from here.

## Next

What the owner wants worked on, in no fixed order.

- **The plan.** ONLR is being planned. No code is written until the owner says the plan is done.
- **The Windows experiment.** The owner runs it and reports what it prints (see [Tasks](#tasks)). Remind the owner of it.
- **To discuss with the owner.** What the edit player runs (see [Player and link](#player-and-link)), and one kind of file for scenes and prefabs (see [Engine](#engine)).
- **The engine's concepts first.** What is open under [Engine](#engine) is settled before a library's pack is designed, since packs are built on the engine.
- **Which libraries.** How a library meets the engine is designed (DESIGN 11). No library is chosen (see [Libraries](#libraries)).
- **Linux and the `.love` file first.** Windows follows. macOS and Android are noted for later (see [Export](#export)).

## Engine

- **The engine's components' properties.** DESIGN 10 names the four types. Their properties are not listed: a sprite's part of an image, its origin and its colour; a text's alignment and width; a shape's kinds and line width; a camera's zoom and limits.
- **Sound.** A component that plays a sound when its object loads, or when a script asks. Whether it is one of the engine's own, and how music that outlives a scene is played. Also open: whether a sound property gives a source that is decoded whole or one that is streamed, which LÖVE asks when it makes a source.
- **Animation.** A sprite that shows frames of a sheet in turn. Whether it is part of `onlr.sprite` or a type of its own, and where the frames' sizes and times are kept.
- **Physics and collision.** Components that give an object a body: where the world lives, how the body moves the object, how a child of a moving object behaves, and the name under which a contact reaches a script (DESIGN 7). Open: whether they use `love.physics`, a collision library such as bump, or both as separate packs (see [Libraries](#libraries)).
- **Particles and tile maps.** Whether the engine has components for LÖVE's particle systems, and for tile maps (see [Libraries](#libraries)).
- **The window and the game's size.** A project has one size (DESIGN 3.2). Open: what the game does when the window has another size or is resized, whether it scales with bars or shows more, and how fullscreen and high-density screens behave.
- **From the window to the world.** A callback such as `mousepressed` gives a point of the window, and an object's place is in the world, behind the camera. No function turns the one into the other, so a script cannot tell which object a click is on. Recommended: `onlr.scene.toWorld(x, y)` and `onlr.scene.toWindow(x, y)`, through the scene's camera.
- **Drawing in the window's space.** A component draws at its object, through the camera (DESIGN 6.3), and `love.draw` draws in the window's space (DESIGN 8.1). Open: a component that draws in the window's space, such as a score. `love.graphics.origin()` in its `draw` does it today, under LÖVE's own name. A mark on the object could do it too.
- **Order by y.** A game seen from above draws what is lower on the screen later. A script can set `z` from `y` each frame (DESIGN 5). Open: whether the engine does it for the children of an object that asks. It needs no library: LÖVE has nothing for it, and it is a sort of the list of `draw`.
- **More kinds of property.** A component of another object, such as a body. Whether a property can hold an object of another scene's prefab.
- **A property's name in the inspector.** The inspector shows the name as the script writes it (DESIGN 13). Open: an option for another label, and showing `cellSize` as "Cell size".
- **A component's values in a file.** A component's entry holds `type` and `enabled` beside the properties' values, so no property can have those names (DESIGN 6.2). Recommended: keep the taken names. The other way: the values in a table of their own, which frees every name and makes each entry one level deeper.
- **Components that need another.** A script that calls `self.object:get("bump.body")` needs the body on its object. Open: whether a type can say so, and the editor adds the other.
- **Finding objects.** `onlr.scene.find` gives the first object of a name, and `onlr.scene.get` the first component of a type. Open: finding all of them, and whether objects have tags.
- **Knowing that an object is gone.** A component may hold an object that was destroyed since (DESIGN 6.4). Open: a field that says so, such as `object.destroyed`.
- **How the engine learns of a change.** DESIGN 8.2 says three things that cannot all hold: a script sets `active`, `enabled`, `z` and `parent` as plain fields; the engine's lists follow them; and the engine walks no tree. The engine learns of a plain field's change only by looking at every object each frame. The same holds for an object's place and its world transform. And no function moves an object to another parent. Recommended: `x`, `y`, `rotation` and the scale stay plain fields, compared when the transform is used; what changes the lists goes through functions, such as `object:setActive`, `object:setParent`, `object:setZ` and `component:setEnabled`. The other way: objects are proxies that see every write, which costs a call for each.
- **Speed.** DESIGN 8.2 says how a scene is kept. A first measure, with 10,000 objects that each update and draw one image: walking the components' `update` takes a small part of the time that the calls into LÖVE for drawing take. So what is worth making faster is the number of calls into LÖVE for each drawn component, not how the engine keeps its data. A sample with thousands of objects stays as the measure.
- **How large a scene can be.** LuaJIT reads a file's table as one function, which holds at most 65,536 constants, and each object and component uses one. A scene of 30,000 objects with one component each loads, and one of 33,000 does not. Recommended: the editor warns well before that, and a tile map is one component, not an object for each tile.
- **Threads.** The engine runs on LÖVE's main thread, as a LÖVE game does, and a script may use `love.thread` as in any game. Open: reading and decoding a scene's images and sounds in a thread, so that loading does not stop the picture (see Loading).
- **Drawing state in the game.** In the scene view the engine saves and restores LÖVE's drawing state around each component (DESIGN 6.5). In the game it restores the transform only, as plain LÖVE code expects to manage its own colours. Open: whether the game restores all of it too, which is safer and costs time for every component.
- **Order of update.** Objects update in the tree's order (DESIGN 5). Whether a script needs a way to run before or after others.
- **The game's own loop.** The engine takes `love.run` (DESIGN 8.1), so a game cannot set its own, such as one with a fixed time step. Open: functions for the steps of the engine's loop, which a game's own loop calls.
- **Turning objects off and on.** Whether a component hears that its object became active or not. A library's body needs it, to leave its world while its object is off: `load` and `destroy` are called once, whatever the object is set to (DESIGN 6.4).
- **Keeping an object through a scene change.** What outlives a scene lives in the user's modules (OVERVIEW 5). Whether an object can be kept too, such as a music player.
- **Loading.** A scene's files are loaded when the scene loads. Open: big scenes, showing progress, and freeing what the next scene does not use.
- **One kind of file for scenes and prefabs.** A scene's file and a prefab's hold nearly the same: the running scene is already an object, the root, with components and children (DESIGN 5). Open: whether a prefab is only a scene that another scene holds as an object. Then there is one format and one loader, any scene can be placed in another, such as a room in a level, and `onlr.scene.spawn` takes any scene. Against it: a scene's own components, such as its world, come along into the scene that holds it, and the editor no longer tells by the file which scenes are made to be placed. Recommended: one kind of file.
- **Changes to a prefab's structure in an instance.** An instance changes values only (DESIGN 9). Whether it may add a component or a child. The format has room for both: an entry of a type that the prefab's object lacks, and `children` of the instance's own. Open: what such an entry means when the prefab later gets the same type.
- **A type's name is its file's path.** `components.player` is `components/player.lua` (DESIGN 5). A script that is renamed or moved outside the editor breaks every scene that names it, and a renamed property leaves its old values unused (DESIGN 6.2). Recommended: the inspector shows a type or a value that it does not know, with a way to give it to another type or property. The other way: a type has a name of its own, apart from its file's, which changes how scripts are found.
- **Code in a file that the editor writes.** A person may compute a file's table, and a save by the editor writes the values only (DESIGN 4.1, 4.2). So a manifest that computes loses its code when the project settings panel saves it. Recommended: the editor compares a file with what it would write itself, and asks before it replaces one that holds more.
- **How a file is written, exactly.** DESIGN 4.2 names the rules. Not written down: the order of the fields, how a number is written so that both Luas read the same value, an id's letters and length, the ends of lines, and the patterns that `exclude` takes.
- **The manifest's names.** In LÖVE's `conf.lua`, `t.version` is LÖVE's version and `t.identity` names the folder of saved files. The manifest has `love` for LÖVE's version, `version` for the game's, and `id` for the folder (DESIGN 3.2). Open: whether to take LÖVE's names, which someone who knows LÖVE expects.
- **Versions.** While ONLR is young, a new version may break projects, and nothing is kept for the old ones. Not designed: what happens to a project's files when a format changes.
- **Logic without code.** An idea for later: a panel in which the user connects nodes, as Unreal's Blueprints do, which writes a component. It needs nothing new from the engine if its output is a script.

## Player and link

- **The edit player on Windows.** SDL's offscreen driver gets OpenGL only through EGL, and LÖVE's package for Windows holds no `libEGL.dll`. So the edit player most likely does not start on Windows as DESIGN 12.1 starts it on Linux. The owner's experiment tells (see [Tasks](#tasks)). None of these ways is checked:
  - A normal window that the engine hides at once, with SDL's `SDL_HideWindow` through LuaJIT's FFI. The engine draws into a canvas, with the same OpenGL as the exported game. The window may flash when it opens. Recommended to try first.
  - A normal window that LÖVE's own functions move off the screen or minimize. It needs no FFI, and the window shows in the task bar.
  - ANGLE's `libEGL.dll` and `libGLESv2.dll` beside LÖVE's files in ONLR's archive. LÖVE itself stays unchanged. The edit player then draws with OpenGL ES over Direct3D, not with the OpenGL of the exported game, so a shader may look different in the scene view. The offscreen driver also asks EGL for its list of devices, which ANGLE may not give.
- **The offscreen driver elsewhere.** It is checked on Linux with an NVIDIA card, with the system's LÖVE 11.5 and with LÖVE's own AppImage, and on a computer with no display and no graphics card, where Mesa draws in software. It needs the system's EGL library. Not checked: Intel and AMD cards.
- **How fast frames travel.** Reading a 1280×720 frame back takes about 1.4 ms with a graphics card. Making a Lua string of it and sending it with LuaSocket take about 5 ms more, so the sending side passes 60 frames a second. Receiving a frame and showing it in a panel is not measured. Ways to make it cheaper: a texture of OpenECS-std's gpu plugin, which is uploaded once and scaled by the graphics card; sending straight from the frame's memory with LuaJIT's FFI, without the string; shared memory; sending only when the picture changed.
- **The pixels' order.** LÖVE gives a pixel as red, green, blue and alpha, and OpenECS's images hold blue, green, red and alpha. Where the change is made: a shader in the engine, the panel, or a texture that takes LÖVE's order.
- **Bounds in the link.** With each frame the engine sends every object's bounds as the view shows them (DESIGN 12.3), so moving the view sends them all again, and a turned object's bounds are no rectangle there. Recommended: bounds in the object's own space with the object's transform, sent when the scene changes; the panel places them in the view itself. It waits for the libraries, since their components give the bounds.
- **What the edit player runs.** To discuss with the owner. The edit player is LÖVE on the project's folder, so it runs `conf.lua`, the top of `main.lua`, and the top of each script that the editor asks about. It does not call `love.load`, nor a component's `load` or `update` (DESIGN 6.5). What follows for a game's author:
  - Code at the top of `main.lua` runs when the project opens, not only when the game plays. An error or an endless loop there leaves the scene view empty.
  - What a game sets in `love.load` is not set in the scene view. A game with pixel art calls `love.graphics.setDefaultFilter("nearest")` there, so its pictures are sharp in the game and blurred in the scene view.
  - Recommended: the manifest holds the settings that both need, the default filter first; while the edit player is down, the inspector shows the values that the scene's file holds, without their kinds; and the edit player starts again when any Lua file changes, which takes about a tenth of a second.
- **A player that does not answer.** The editor starts a player again when asked (DESIGN 12.1). Open: how the editor learns that a `drawEditor` never returns, and what keeps it from starting the same view again and again; and what the console shows for a game that fails before the engine loads.
- **The game in a panel.** Play shows the game in LÖVE's own window, and only what a mode draws into differs between the modes (DESIGN 12.1). Showing the game in a panel is an idea for later. What it needs:
  - Frames from the play player. `love.graphics.captureScreenshot` reads the window's picture, also when there is no window, so the game draws as always. Drawing into a canvas of the engine's instead would break a game that sets canvases of its own.
  - A pace. Without a window LÖVE does not wait for the screen, and runs hundreds of frames a second.
  - The panel's keys, text and pointer, sent to the game, and the engine answering for `love.keyboard.isDown`, `love.mouse.getPosition` and the like. Also the pointer's modes, gamepads, the desktop's size, and the keys that the editor takes before a panel gets them.
- **Looking into the running game.** Showing the running scene's objects and values in the objects panel and the inspector, and changing them while the game plays.
- **Reloading while playing.** A changed script or image takes effect in the running game without a restart. Open: what happens to the values a component keeps.
- **Pause and step.** Stopping the game's updates, and running one frame.
- **Sound in the edit player.** Whether the edit player opens a sound device at all.
- **Previews that move.** The edit player draws when asked and updates nothing (DESIGN 12.3). A preview of an animation or of particles needs time to pass. Open: whether a view can ask for updates of its own scene.
- **Files in the files panel.** A small picture of an image file could come from the edit player, as a view, or from OpenECS's own image reader, which is faster and is not what the game draws.
- **A debugger.** Stopping at a line and reading variables. Not planned; an error's file, line and stack are shown (DESIGN 12.2).

## Editor

- **The scene view's tools.** How objects are moved, turned and scaled; snapping to a grid; choosing many; choosing an object under another; what the view shows for an object with no `bounds`. The panel draws them over LÖVE's frame (DESIGN 12.3); a grid behind the objects needs the frame to keep its transparency.
- **A component's own handles.** A component draws its outline in the scene view with `drawEditor` (DESIGN 6.5). Open: changing its values there, such as dragging the corner of a body's box.
- **Copying objects.** Duplicate and paste give the copies new ids. A property that named a copied object names its copy.
- **The files panel.** What it does with files: rename and move, and whether paths in scenes follow; how an image or a sound is previewed.
- **Making a script.** A new script starts from a file with the common functions. Where that file is kept, and whether the user can change it.
- **Assets that are missing.** What the inspector and the scene view show for a path that no longer exists.
- **Many scenes open.** Whether two scenes can be open at once, each with an edit player, or one at a time.
- **Text scenes in git.** The editor writes files so that changes merge (DESIGN 4.2). Not checked on a real merge.
- **Git and the editor's folder.** `.onlr/` is not in git (DESIGN 3.1). Recommended: the editor writes a `.gitignore` that names it when it makes the project.
- **The engine in a project.** `lib/onlr/` is a copy (DESIGN 3.1), so it is in the user's git. Whether a project could name a shared engine instead. Lua's own `loadfile` reads outside the game's folder, which a player uses for its own files (DESIGN 12.1), but an exported game must hold the engine.
- **The split into plugins.** DESIGN 13 names four. It is checked again when the first is written.

## Export

- **Where an export is written.** An export inside the project's folder would be in the next export. Recommended: a folder that the user chooses, which the editor remembers for the project; one inside the project is left out as `exclude`'s files are.
- **The Linux package on a Windows host.** LÖVE's Linux release is an AppImage, which only Linux unpacks. A Windows host needs its contents another way: ONLR hosts them as an archive, or the editor reads the AppImage's file system itself.
- **The archive of a Linux build.** DESIGN 14.2 names a `.tar.gz` that keeps permissions. OpenECS-std's compress writes zip and gzip; writing tar is not there yet.
- **An AppImage as a Linux build.** One file is easier to hand out than an archive. Making it needs `appimagetool`, which runs on Linux only.
- **The Windows executable's icon and details.** Changing them means editing the executable's resources. On Linux that is done with a Windows tool under Wine today; a small writer of our own is the alternative.
- **Windows on 32 bits and on ARM.** LÖVE 11.5 has a 32-bit package. Not planned unless asked for.
- **macOS, for later.** LÖVE ships `love.app` in a zip; a build puts the `.love` file inside it and changes its `Info.plist`. Open: signing, which needs a Mac, and what an unsigned build shows its user. The editor itself runs on macOS when OpenECS does.
- **Android, for later.** LÖVE's Android project builds a package with the game inside. It needs a JDK, the Android SDK and Gradle on the user's computer. Open: whether the editor drives them, or only prepares the folder; touch input and screen sizes in the engine.
- **iOS, for later.** It needs Xcode on a Mac and a developer account.
- **The web.** love.js supports LÖVE 11 without LuaJIT, and is not maintained by LÖVE's team. Not planned until LÖVE has a web target of its own.
- **Leaving out what a game does not use.** An export holds every file of the project apart from `exclude`. Whether it could leave out assets that no scene and no script names.
- **Compiling scripts.** Whether an export may hold LuaJIT bytecode instead of source. Bytecode is tied to a LuaJIT version.

## Libraries

- **Which libraries.** None is chosen. The candidates, by the rule of OVERVIEW 9:
  - collision of boxes, through bump, which is its own small system and uses nothing of `love.physics`;
  - physics with forces and joints, through `love.physics`, which is part of LÖVE and so needs components only;
  - tile maps made with Tiled, through STI;
  - an interface inside the game, through one library such as SUIT or Slab, or components of the engine's own.
- **A bump pack's details.** DESIGN 11.3 shows its outline as a sample. Open if bump is chosen: a body on an object that is turned or scaled, since bump's boxes are not; which boxes a body passes through.
- **A pack's version.** A pack names its library's version (DESIGN 11.2). Open: how the editor offers a newer pack to a project that has an older one, and what happens to changes the user made in the project's copy.
- **A pack's hints.** A library needs definitions for the code editor, as LÖVE has (DESIGN 4.3). Most libraries ship none. Open: whether a pack holds them, and who writes them.
- **Packs from others.** A pack is a folder (DESIGN 11.2), so anyone can make one. Open: whether the editor adds a pack, or a plain library, from a folder or an address that the user gives.
- **What the engine covers itself.** Animation of sprites and a camera are small enough to be the engine's own, so no library is planned for them.

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
  - compress: writing tar (see [Export](#export)).
  - ui: a tree that chooses many nodes and drags them, for the objects panel.
  - fs: watching the folders inside a folder, for the project's folder.
- **The build files.** The template's plugins, preset, test, build script, submodules, checks and Claude Code settings were removed, since nothing is built yet. When code starts, take them fresh from [OpenECS-template](https://github.com/omerfuyar/OpenECS-template), which follows OpenECS's `dev`.
- **ONLR's archive.** How the one archive of OVERVIEW 2 is made: OpenECS's release, ONLR's plugins and preset, the engine, the player's files, and LÖVE's package for the host.
- **The hashes of LÖVE's packages.** DESIGN 15.2 checks downloads against hashes that ONLR ships. They are taken once from LÖVE's releases.
- **OpenECS's TODO.md** still lists this editor's open questions. Replace them there with a link to this repository.
- **Rulesets.** `dev` and `main` have no rules in this repository yet. The owner sets them when checks exist.
