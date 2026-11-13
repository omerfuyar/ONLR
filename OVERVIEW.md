# ONLR Overview

This document explains what ONLR is, what it covers, what it leaves to LÖVE and to the user's code, and how it behaves to the user.

**See also:**

- How ONLR is built is in [DESIGN.md](DESIGN.md).
- Open questions and pending work are in [TODO.md](TODO.md).
- Terms used in this document are explained in the glossary at the end.

---

## Contents

1. Summary
2. Using ONLR
3. Scope
4. Projects
5. Scenes, objects and components
6. Scripts
7. The editor
8. Export
9. Libraries
10. Platforms
11. Principles

- Glossary

---

## 1. Summary

ONLR is an editor and an engine for 2D games that run on [LÖVE](https://love2d.org). LÖVE runs games written in Lua. It has no editor, and no scenes or objects: a game is code.

ONLR adds them. Its **engine** is a Lua library that gives a LÖVE game scenes, objects and components. Its **editor** is where the user arranges them, runs the game and exports it.

ONLR means "ONLR Not Love Runtime". LÖVE stays the runtime, and ONLR never changes it. A game made with ONLR is a `.love` file that any LÖVE runs.

## 2. Using ONLR

1. The user unpacks one archive and starts ONLR. Nothing else is installed: LÖVE is inside.
2. The user makes a project, or opens one.
3. The scene view shows the open scene. The user adds objects, moves them, and gives them components. The inspector shows the properties of each component of the chosen object, and changes them.
4. The user writes scripts in their own code editor. A script is a component. When the file is saved, the inspector shows the properties it declares.
5. Play runs the game in a window of its own. The console shows what the game prints, and its errors. An error names its file and line, and a click opens it in the user's code editor.
6. Export makes a `.love` file, or a build for a platform: the game with LÖVE inside, which runs with nothing installed.

## 3. Scope

### 3.1 What LÖVE provides

The window, drawing, sound, input, physics, files and the game's loop. ONLR replaces none of them, and brings no renderer, physics or sound of its own.

### 3.2 What the engine adds

- Scenes, objects and components, read from the project's files (5).
- The life of a component: when it loads, updates, draws and is destroyed (6).
- Prefabs, and making objects from them while the game runs.
- A few components of its own, for what almost every game shows: a sprite, a text, a shape and a camera.

### 3.3 What the editor provides

- Panels to arrange scenes, to change properties and to manage the project's files (7).
- Play: the game runs in its own window, and the editor shows what it prints and its errors (7).
- Export (8).

### 3.4 What stays in the user's code

All of the game's logic. A script may call any function of LÖVE (6).

### 3.5 Not in the design

- Changing LÖVE, or shipping a changed LÖVE.
- A code editor. Users write scripts in their own.
- Opening a game that was not made with ONLR as a project. Such a game has no scenes to edit.

## 4. Projects

- A project is a folder. ONLR opens projects, never single files.
- A project is a LÖVE game: LÖVE runs the folder as it is, without the editor. So a project works in git, on another computer and with any tool for LÖVE games.
- One folder of the project, `lib`, holds the engine, packs and libraries. The editor puts the engine there, and updates it when the user agrees. The user adds libraries to it, by hand or in the editor.
- Scripts are in one folder, `components`. Scenes, prefabs and assets are in any folders. A file's path in the project is its path in the game.
- The project's manifest holds what describes the whole game: its name, its version, its first scene, the size of its window, and the version of LÖVE it was made for.
- Every file that ONLR writes is a Lua file that returns a table. A person may write such a file too, and compute the table in it. ONLR ships definition files for them, so a code editor completes and checks them.

## 5. Scenes, objects and components

- A **scene** is a file that holds objects: a level, a menu, a screen. One scene runs at a time. Loading a scene ends the one that runs.
- An **object** has a name, a place (position, rotation and scale), a list of components, and children. A child's place is in its parent, so it moves, turns and scales with it.
- A **component** gives an object what it shows or does. Each has properties, such as a sprite's image or a player's speed. An object can have many components.
- Objects draw in the order of a number, `z`, the lowest first. A child's `z` is added to its parent's, so a child can draw behind its parent. Objects of the same `z` draw in the order of the scene's tree: a parent before its children, and siblings in their order.
- A **prefab** is an object, with its children, in a file of its own. A scene holds instances of it. An instance has its own place, and may change any value of the prefab's objects and components. A prefab may hold instances of other prefabs. A script makes instances while the game runs, such as bullets and enemies.
- A scene has components of its own too, for what the whole scene has one of, such as the world that its bodies collide in.
- What must outlive a scene, such as a score, lives in the user's own Lua modules, as in any LÖVE game.

## 6. Scripts

- A script is a Lua file that returns a component. The user attaches it to objects in the editor.
- Its functions have the names of LÖVE's callbacks, and get what LÖVE gives them: `load`, `update(dt)`, `draw`, `keypressed(key)` and every other one. Someone who knows LÖVE knows a script.
- A script may call any function of LÖVE: `love.graphics`, `love.keyboard`, `love.audio` and the rest work as in any game.
- A script declares its properties as its fields: each with a type and a default value. The inspector shows them, a scene keeps their values, and the script reads them under the same names.
- A property can be a number, a text, a choice or a pair of numbers, and also a file of the project, such as an image or a sound, or another object of the scene. Properties can be put in groups and in lists.
- LÖVE's own callbacks keep working. A game may still define `love.update` or `love.draw` in its `main.lua`, and the engine calls them too.
- A library for LÖVE works as in any game: the user copies it into the project's folder of libraries and loads it with `require`, under the name its author gives.

## 7. The editor

The editor is an OpenECS tool, so its panels can be arranged, grouped as tabs and moved into windows. Its panels:

| Panel            | Shows                                                                     |
| ---------------- | ------------------------------------------------------------------------- |
| Scene view       | The open scene. The user chooses objects, and moves, turns and scales them. |
| Objects          | The scene's tree of objects.                                              |
| Inspector        | The chosen object's components and their properties.                      |
| Files            | The project's folders and files.                                          |
| Console          | What the game prints, and its errors.                                     |
| Project settings | What the project's manifest holds.                                        |
| Export           | The targets, and the export's progress.                                   |

- LÖVE draws the scene view, as it draws the game. The editor has no renderer of its own for games.
- A component says what it shows in the scene view, in LÖVE code. The editor adds what belongs to its tools: the grid, the outline and handles of the chosen objects, and a marker for an object that shows nothing.
- The inspector lists a component's properties in the order its script declares them. Adding a component offers the engine's, those of the project's packs, and the project's scripts.
- The editor never runs the game's code. LÖVE does, and tells the editor what it needs, such as the properties a script declares.
- In the scene view nothing moves: the engine draws the scene and does not update it.
- Play saves the project, then runs the game from the open scene, in LÖVE's own window. Stop ends it, and so does closing the window. The console, the errors and their links to files work while it runs.
- A preview, such as of an image, a font or a prefab, is drawn by LÖVE as the scene view is.
- A game that fails, or never returns, does not stop the editor.
- Every change to a scene can be undone. The project has one history, whichever panel made the change.
- The editor saves when the user asks and when Play starts, and asks about unsaved work before it closes.
- When a file of the project changes outside the editor, such as a script that the user saves or a branch that git checks out, the editor reads it again.

## 8. Export

- A `.love` file holds the project's files. Any LÖVE of the project's version runs it, on any platform.
- A build runs with nothing installed, on its one platform.
- The user chooses the targets. LÖVE for the editor's own platform ships with ONLR; for another platform, ONLR downloads it at the first export.
- An export holds the licences that its parts ask for: LÖVE's in a build, and those of the engine and of the project's libraries.

## 9. Libraries

- Any library written for LÖVE works in a project (6).
- The engine knows no library, and a library does not know the engine. A script calls a library as the library's own documentation says.
- ONLR may include a library when it is widely used, simple to understand, and either maintained or small and finished. Fewer is better: each one included is one to keep working.
- A library that ONLR includes comes as a pack. The library in it is unchanged. Its components are written as scripts are, so a user can write the same for any other library.
- A pack's components are a help, not a wall. A script may use the library through them, call the library itself, or do both.
- A project chooses its packs. The editor copies a pack into the project, where it is the project's own.

## 10. Platforms

- The editor runs where OpenECS runs: Linux and Windows.
- A game is exported as a `.love` file, and as a build for Linux on x86_64 and for Windows.
- ONLR is made for LÖVE 11.5.

## 11. Principles

1. **LÖVE is unchanged.** ONLR uses LÖVE's own executables, and a game needs nothing else to run.
2. **A project is a LÖVE game.** LÖVE runs the folder without the editor.
3. **LÖVE stays in reach.** A script uses LÖVE's names and may call all of LÖVE.
4. **Data, not generated code.** The editor writes data, and a fixed engine reads it. The only code in a project is the user's and the engine's.
5. **One renderer.** LÖVE draws everything the user sees of a game, in the editor too.
6. **The engine's components are written as the user's are.** They use only what a script can use.
7. **Parts stand alone.** The engine knows no library and nothing of the editor, and a library does not know the engine. The editor knows a game by its files and by what LÖVE tells it.
8. **Files are Lua tables.** Every file of ONLR is a Lua file that returns a table, with definitions that guide a code editor.
9. **Few dependencies.** A library is included only when it earns its place (9).
10. **Easy to set up.** One archive holds everything that making and running a game needs.
11. **Do not lose what is not understood.** A field or a component that the editor does not know is kept when it writes a file.
12. **Composition, not inheritance.** An object is what its components make it, and a scene is made of objects and of instances of prefabs. No component type inherits another.

## Glossary

**Asset.** A file of a project that a game shows or plays, such as an image, a sound or a font.

**Build.** A game with LÖVE inside, for one platform.

**Callback.** A function that a game defines and LÖVE calls, such as `love.update`.

**Component.** A part of an object that gives it what it shows or does, with its own properties.

**Definition file.** A file that tells a code editor the fields of a table or the parameters of a function.

**Editor.** The half of ONLR in which the user arranges scenes, runs the game and exports it.

**Engine.** The half of ONLR that runs inside the game: a Lua library that adds scenes, objects and components to LÖVE.

**Inspector.** The panel that shows and changes the properties of the chosen object's components.

**Instance.** An object in a scene that was made from a prefab.

**LÖVE.** A free framework that runs 2D games written in Lua.

**`.love` file.** An archive of a game's files, which LÖVE runs.

**Manifest.** A data file that describes the folder it is in: the project's, which describes the whole game, and one for the engine and for each pack.

**Object.** A thing in a scene, with a name, a place, components and children.

**OpenECS.** The program that provides the editor's windows, panels and plugins.

**Pack.** A library as ONLR includes it: the library, its licence, and the components that show it in the inspector.

**Panel.** A rectangular area of the editor's window.

**Prefab.** An object, with its children, kept in a file of its own, from which scenes and scripts make instances.

**Project.** The folder of a game made with ONLR.

**Property.** A named, typed value of a component, which the inspector shows and a scene keeps.

**Scene.** A file that holds the objects of one part of a game, such as a level or a menu.

**Script.** A Lua file, written by the user, that returns a component.

**Target.** What an export makes: a `.love` file, or a build for one platform.
