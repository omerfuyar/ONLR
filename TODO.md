# ONLR TODO

What is not decided yet, and work that is waiting. When an item is settled, write the decision into [OVERVIEW.md](OVERVIEW.md) or [DESIGN.md](DESIGN.md), where it belongs, and remove it from here.

## Next

What the owner wants worked on, in no fixed order.

- **The plan.** ONLR is being planned. No code is written until the owner says the plan is done.
- **The engine's concepts first.** What is open under [Engine](#engine) is settled before a library's pack is designed, since packs are built on the engine.
- **Which libraries.** How a library meets the engine is designed (DESIGN 11). No library is chosen (see [Libraries](#libraries)).
- **Linux and the `.love` file first.** Windows follows. macOS and Android are noted for later (see [Export](#export)).

## Engine

- **The engine's components' properties.** DESIGN 10 names the four types. Their properties are not listed: a sprite's part of an image, its origin and its colour; a text's alignment and width; a shape's kinds and line width; a camera's zoom and limits.
- **Sound.** A component that plays a sound when its object loads, or when a script asks. Whether it is one of the engine's own, and how music that outlives a scene is played.
- **Animation.** A sprite that shows frames of a sheet in turn. Whether it is part of `onlr.sprite` or a type of its own, and where the frames' sizes and times are kept.
- **Physics and collision.** Components that give an object a body: where the world lives, how the body moves the object, how a child of a moving object behaves, and the name under which a contact reaches a script (DESIGN 7). Open: whether they use `love.physics`, a collision library such as bump, or both as separate packs (see [Libraries](#libraries)).
- **Particles and tile maps.** Whether the engine has components for LÖVE's particle systems, and for tile maps (see [Libraries](#libraries)).
- **The window and the game's size.** A project has one size (DESIGN 3.2). Open: what the game does when the window has another size or is resized, whether it scales with bars or shows more, and how fullscreen and high-density screens behave.
- **More kinds of property.** A component of another object, such as a body. Whether a property can hold an object of another scene's prefab.
- **A property's name in the inspector.** The inspector shows the name as the script writes it (DESIGN 13). Open: an option for another label, and showing `cellSize` as "Cell size".
- **Components that need another.** A script that calls `self.object:get("bump.body")` needs the body on its object. Open: whether a type can say so, and the editor adds the other.
- **Finding objects.** `onlr.scene.find` gives the first object of a name, and `onlr.scene.get` the first component of a type. Open: finding all of them, and whether objects have tags.
- **Speed.** DESIGN 8.2 says how a scene is kept. A first measure, with 10,000 objects that each update and draw one image: walking the components' `update` takes a small part of the time that the calls into LÖVE for drawing take. So what is worth making faster is the number of calls into LÖVE for each drawn component, not how the engine keeps its data. A sample with thousands of objects stays as the measure.
- **Threads.** The engine runs on LÖVE's main thread, as a LÖVE game does, and a script may use `love.thread` as in any game. Open: reading and decoding a scene's images and sounds in a thread, so that loading does not stop the picture (see Loading).
- **Drawing state in the game.** In the scene view the engine saves and restores LÖVE's drawing state around each component (DESIGN 6.4). In the game it restores the transform only, as plain LÖVE code expects to manage its own colours. Open: whether the game restores all of it too, which is safer and costs time for every component.
- **Order of update.** Objects update in the tree's order (DESIGN 5). Whether a script needs a way to run before or after others.
- **Turning objects off and on.** Whether a component hears that its object became active or not.
- **Keeping an object through a scene change.** What outlives a scene lives in the user's modules (OVERVIEW 5). Whether an object can be kept too, such as a music player.
- **Loading.** A scene's files are loaded when the scene loads. Open: big scenes, showing progress, and freeing what the next scene does not use.
- **How an instance names a component.** `overrides` names a component by its place in the prefab's object (DESIGN 9). Changing the order of a prefab's components would move the values to another component. Open: naming it by its type and its count among that type.
- **Changes to a prefab's structure in an instance.** An instance changes values only (DESIGN 9). Whether it may add a component or a child.
- **Logic without code.** An idea for later: a panel in which the user connects nodes, as Unreal's Blueprints do, which writes a component. It needs nothing new from the engine if its output is a script.

## Player and link

- **The offscreen driver elsewhere.** It is checked on Linux with an NVIDIA card, with the system's LÖVE 11.5 and with LÖVE's own AppImage. Not checked: Windows; Intel and AMD cards; a computer with no display at all.
- **How fast frames travel.** Reading a 1280×720 frame back takes about 1.4 ms. Sending it over TCP and showing it in a panel is not measured. If it is too slow: shared memory, sending only when the picture changed, or sending from a thread of the player.
- **The pixels' order.** OpenECS's images hold pixels in another order than LÖVE's canvas gives (DESIGN 12.4). Where the change is made: a shader in the engine, or the panel.
- **Gamepads and touch in the player.** DESIGN 12.5 covers the keyboard and the pointer. A gamepad could be read by the player itself, since SDL reads them without a window; this is not checked.
- **The pointer's modes.** A game that hides or grabs the pointer, or reads relative motion, in a panel.
- **Looking into the running game.** Showing the running scene's objects and values in the objects panel and the inspector, and changing them while the game plays.
- **Reloading while playing.** A changed script or image takes effect in the running game without a restart. Open: what happens to the values a component keeps.
- **Pause and step.** Stopping the game's updates, and running one frame.
- **Sound in the edit player.** Whether the edit player opens a sound device at all.
- **Previews that move.** The edit player draws when asked and updates nothing (DESIGN 12.3). A preview of an animation or of particles needs time to pass. Open: whether a view can ask for updates of its own scene.
- **Files in the files panel.** A small picture of an image file could come from the edit player, as a view, or from OpenECS's own image reader, which is faster and is not what the game draws.
- **A debugger.** Stopping at a line and reading variables. Not planned; an error's file, line and stack are shown (DESIGN 12.2).

## Editor

- **The scene view's tools.** How objects are moved, turned and scaled; snapping to a grid; choosing many; choosing an object under another; what the view shows for an object with no `bounds`. The panel draws them over LÖVE's frame (DESIGN 12.3); a grid behind the objects needs the frame to keep its transparency.
- **A component's own handles.** A component draws its outline in the scene view with `drawEditor` (DESIGN 6.4). Open: changing its values there, such as dragging the corner of a body's box.
- **The files panel.** What it does with files: rename and move, and whether paths in scenes follow; how an image or a sound is previewed.
- **Making a script.** A new script starts from a file with the common functions. Where that file is kept, and whether the user can change it.
- **Assets that are missing.** What the inspector and the scene view show for a path that no longer exists.
- **Many scenes open.** Whether two scenes can be open at once, each with an edit player, or one at a time.
- **Text scenes in git.** The editor writes files so that changes merge (DESIGN 4.2). Not checked on a real merge.
- **The engine in a project.** `lib/onlr/` is a copy (DESIGN 3.1), so it is in the user's git. Whether a project could name a shared engine instead while LÖVE 11.5 reads only the game's folder.
- **The split into plugins.** DESIGN 13 names four. It is checked again when the first is written.

## Export

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

- **The build files.** The template's plugins, preset, test, build script, submodules, checks and Claude Code settings were removed, since nothing is built yet. When code starts, take them fresh from [OpenECS-template](https://github.com/omerfuyar/OpenECS-template), which follows OpenECS's `dev`.
- **ONLR's archive.** How the one archive of OVERVIEW 2 is made: OpenECS's release, ONLR's plugins and preset, the engine, and LÖVE's package for the host.
- **The hashes of LÖVE's packages.** DESIGN 15.2 checks downloads against hashes that ONLR ships. They are taken once from LÖVE's releases.
- **OpenECS's TODO.md** still lists this editor's open questions. Replace them there with a link to this repository.
- **Rulesets.** `dev` and `main` have no rules in this repository yet. The owner sets them when checks exist.
