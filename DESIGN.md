# ONLR Technical Design

This document explains how ONLR is built: its parts, the project's files, the engine, the link between editor and game, and export. Read [OVERVIEW.md](OVERVIEW.md) first; this document uses its words and does not repeat it.

**How to read it:**

- Everything here is decided. Open questions and pending work are in [TODO.md](TODO.md).
- Code samples are only illustrations of a file or an interface.
- Technical terms are explained in the glossary at the end.
- "OpenECS DESIGN" names [OpenECS's DESIGN.md](https://github.com/omerfuyar/OpenECS/blob/dev/DESIGN.md), and "OpenECS-std DESIGN" [OpenECS-std's](https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md). OpenECS changes often, so this document links to them and repeats nothing of theirs. Only section 13 depends on OpenECS.

---

## Contents

1. Conventions
2. Parts
3. Projects
4. Data files
5. Scenes and objects
6. Components
7. The engine's functions
8. The loop
9. Prefabs
10. The engine's components
11. Libraries
12. The player and the link
13. The editor
14. Export
15. LÖVE
16. Tests
17. Versions and branches

- Glossary

---

## 1. Conventions

- The engine is Lua for LuaJIT, which LÖVE runs: Lua 5.1 with LuaJIT's additions. It uses no library but LÖVE.
- The editor's plugins follow OpenECS's conventions (OpenECS DESIGN 1, OpenECS-std DESIGN 1.3).
- Lua names use camelCase: `onlr.scene.load`, `scaleX`. Files and folders have lowercase names.
- Functions of one kind share a namespace, such as `onlr.scene`. What acts on an object or a component is its method.
- The engine sets no global. A script gets it with `local onlr = require("onlr")`.
- Every public function, type and file format of the engine has LuaLS annotations in the engine's source. They are the definitions that guide a code editor (4.3), so the source and the hints cannot differ.
- A path in a project uses `/` and starts at the project's folder, as LÖVE's paths do: `images/player.png`.
- Angles are radians, colours are tables of red, green, blue and alpha from 0 to 1, and y grows down, as in LÖVE.

## 2. Parts

### 2.1 Layers

A game made with ONLR is built in layers. Each uses only the layers above it in this table:

| Layer              | Is                                                                                  | Written by                         | Uses                           |
| ------------------ | ----------------------------------------------------------------------------------- | ---------------------------------- | ------------------------------ |
| 1. LÖVE            | The runtime: the window, drawing, sound, input, physics and files.                  | LÖVE's authors                     |                                |
| 2. Libraries       | Lua code for LÖVE games, such as a library for collision (11).                      | Their authors                      | LÖVE, or nothing               |
| 3. The engine      | Scenes, objects, components, properties and the loop (5 to 9).                      | ONLR                               | LÖVE                           |
| 4. Components      | What objects show and do: the engine's own (10), a pack's (11.2) and the user's scripts (6). | ONLR, a pack's author, the user | The engine, LÖVE and libraries |
| 5. The game's data | The project file, scenes and prefabs, which name component types and hold their values (3, 4). | The user, through the editor | Component types, by name       |

- The engine and the libraries do not know each other. A component is where they meet: it is called by the engine, and it calls a library.
- All three kinds of component are the same thing to the engine. The engine's own and a pack's can do nothing that a script cannot.
- The editor is not a layer of the game. It is another program: it reads and writes the game's data, and asks the player (12) what the components declare and how the scene looks.

### 2.2 In this repository

| Part    | In this repository | Is                                                              | Runs in |
| ------- | ------------------ | --------------------------------------------------------------- | ------- |
| Engine  | `engine/`          | The Lua library that every project holds a copy of, as `onlr/`. | LÖVE    |
| Editor  | `plugins/`, `preset.lua` | OpenECS plugins and their preset (13).                    | OpenECS |
| Samples | `samples/`         | Small projects, which are the tests (16).                       | Both    |

### 2.3 Contracts

Four contracts connect the parts. Each has a version, so a part can change without the others guessing:

| Contract            | Between                    | Version                                         |
| ------------------- | -------------------------- | ----------------------------------------------- |
| The project's files | The editor and the engine  | `format`, a number in each file (4)             |
| The engine's functions | The engine and scripts  | The engine's version, in the project file (3.2) |
| The link            | The editor and the player  | A number that both send when they connect (12.2) |
| A pack              | A pack and the editor      | `format`, a number in the pack's file (11.2)    |

## 3. Projects

### 3.1 The folder

``` text
mygame/
  main.lua        starts the engine
  conf.lua        gives LÖVE the project's settings
  project.lua     the project file
  onlr/           the engine
  lib/            libraries and packs
  .onlr/          the editor's own files for this project
  .luarc.json     tells a code editor where the definitions are
  ...             the user's scenes, prefabs, scripts and assets, in any folders
```

- LÖVE 11.5 reads a game's files only from the game's own folder. So the engine and the files that start it are in the project, and `love mygame` runs it.
- The editor writes `main.lua` and `conf.lua` once, when it makes the project. They are the user's afterwards:

  ``` lua
  -- main.lua
  require("onlr").start()
  ```

  ``` lua
  -- conf.lua
  function love.conf(t)
    require("onlr").conf(t)
  end
  ```

- `onlr.conf` sets what the project file holds: the window's size, the game's name and the folder of its saved files. A user who wants more of LÖVE's settings sets them in `conf.lua`, after that line.
- `onlr/` is the engine's. The editor replaces it when it updates the engine (3.3), so the user does not edit it.
- `.onlr/` holds what the editor keeps for this project on this computer, such as LÖVE's definitions (4.3). It is not in git and not exported.
- `lib/` holds the libraries that the game uses (11). It is the user's: they put their own there too.
- The names `main.lua`, `conf.lua`, `project.lua`, `onlr/`, `lib/` and `.onlr/` are taken. Every other name is the user's.

### 3.2 The project file

``` lua
---@type onlr.Project
return {
  format = 1,
  name = "My game",
  id = "org.example.mygame",
  version = "0.1.0",
  love = "11.5",
  engine = "0.1.0",
  scene = "scenes/menu.scene.lua",
  width = 1280,
  height = 720,
  exclude = { "notes/*" },
}
```

| Field             | Holds                                                                           |
| ----------------- | ------------------------------------------------------------------------------- |
| `format`          | The version of this file's format.                                              |
| `name`            | The game's name: its window's title, and the name of its exports.               |
| `id`              | A reversed domain that names the game to the system, such as its saved files' folder. |
| `version`         | The game's own version.                                                         |
| `love`            | The version of LÖVE the game is made for.                                       |
| `engine`          | The version of the engine in `onlr/`.                                           |
| `scene`           | The scene that the game starts with.                                            |
| `width`, `height` | The size of the game's window, in pixels.                                       |
| `exclude`         | Patterns of files that an export leaves out.                                    |

### 3.3 Updating the engine

- The editor ships one version of the engine. When it opens a project whose `engine` is older, it asks the user, then replaces `onlr/` and sets `engine`.
- A project whose engine is newer than the editor's opens for reading only.
- An update that changes a file format rewrites the project's files in the new format in the same step.

## 4. Data files

### 4.1 Rules

- Every file that ONLR writes is a Lua file that returns one table: the project file, scenes and prefabs.
- Such a file is plain data: numbers, texts, booleans and tables. It holds no function and computes nothing. So LuaJIT in the game and OpenECS's Lua in the editor both read it, though they are different Luas.
- A scene's file ends with `.scene.lua`, and a prefab's with `.prefab.lua`, so the editor knows them without reading them.
- Each file has a `format` number. The engine and the editor refuse a newer format than they know, and say so.

### 4.2 How the editor writes them

- Fields are written in a fixed order, one on each line, and each item of a list starts on its own line. So two changes to different objects merge in git.
- A value that equals its default is left out, so a file holds only what the user set.
- An object's `id` is a short random text, which the editor gives once. Objects are named by id wherever one refers to another, never by their place in a list.
- A field or a component type that the editor does not know is kept as it is, and written back.

### 4.3 Definitions

- The first line of each file names its type, such as `---@type onlr.Scene`, so a code editor with the Lua language server completes and checks its fields.
- The types are in the engine's source, in the project's `onlr/` (1). LÖVE's own definitions, from [LuaCATS/love2d](https://github.com/LuaCATS/love2d), are copied into `.onlr/`.
- The editor writes `.luarc.json` once, when it makes the project. It names LuaJIT as the Lua version, `.onlr/` as a library, and `lib/` as a place where `require` looks (11.1).

## 5. Scenes and objects

``` lua
---@type onlr.Scene
return {
  format = 1,
  objects = {
    {
      id = "k3f9",
      name = "Player",
      x = 100,
      y = 200,
      components = {
        { type = "onlr.sprite", image = "images/player.png" },
        { type = "scripts.player", speed = 250 },
      },
      children = {
        { id = "p7c2", name = "Shadow", y = 12, components = { { type = "onlr.sprite", image = "images/shadow.png" } } },
      },
    },
  },
}
```

| Field of an object        | Holds                                                             | Default |
| ------------------------- | ----------------------------------------------------------------- | ------- |
| `id`                      | Its id, unique in its file.                                       |         |
| `name`                    | Its name. Names need not be unique.                               |         |
| `x`, `y`                  | Its position in its parent, in pixels.                            | 0       |
| `rotation`                | Its angle in its parent, clockwise.                               | 0       |
| `scaleX`, `scaleY`        | Its scale in its parent.                                          | 1       |
| `z`                       | Its order among its siblings.                                     | 0       |
| `active`                  | Whether it and its children update, draw and get events.          | true    |
| `components`              | Its components, each a table of its `type` and its properties' values. |    |
| `children`                | Its children, objects too.                                        |         |
| `prefab`                  | The prefab it is an instance of (9).                              |         |

- A scene's `objects` are its roots. Objects update and draw in the order of the tree: a parent, then its children. Siblings go by `z`, the lowest first, then by their order in the list.
- An object's components update and draw in their order.
- A component's `type` is a Lua module name, as `require` takes it: `scripts.player` is `scripts/player.lua`. The engine's own types start with `onlr.` (10).
- The engine keeps each object's place in the world, from its own and its parents', as a LÖVE transform.

## 6. Components

### 6.1 A component type

A component type is a Lua file that returns a table. A script is one:

``` lua
local onlr = require("onlr")

---@class Player : onlr.Component
local Player = {}

Player.speed = onlr.property.number(200, { description = "Pixels a second" })
Player.image = onlr.property.image()

function Player:load()
  self.jumps = 0
end

function Player:update(dt)
  if love.keyboard.isDown("right") then
    self.object.x = self.object.x + self.speed * dt
  end
end

function Player:draw()
  love.graphics.draw(self.image)
end

function Player:keypressed(key)
  if key == "space" then
    onlr.scene.spawn("prefabs/bullet.prefab.lua", self.object.x, self.object.y)
  end
end

return Player
```

- Each component of an object is a table of its own, which finds its functions in its type. So `self` is the component, and what a function keeps in `self` belongs to that one object.
- `self.object` is the object, and `self.enabled` turns the component off and on.

### 6.2 Properties

- A type declares a property as a field, with a function of `onlr.property`: `Player.speed = onlr.property.number(200)`. A component reads it under the same name: `self.speed`. The engine sets the fields before `load`.
- Each function takes the default value, then optionally a table of options: a `description`, which the inspector shows, and what the table below names. A kind that names a file or an object has no default and takes the options only, and `vector` takes its two numbers.
- The inspector shows a type's properties in the order its file declares them.
- Each function's annotation names what the component gets, so a code editor knows that `self.speed` is a number.
- A property with no value and no default reads as `nil`.

| Function of `onlr.property` | The inspector shows                               | The component gets                           |
| --------------------------- | ------------------------------------------------- | -------------------------------------------- |
| `bool`                      | A toggle.                                         | A boolean.                                   |
| `integer`, `number`         | A number field, kept in `min` and `max` if given. | A number.                                    |
| `string`                    | A text field.                                     | A text.                                      |
| `choice`                    | One of its `choices`.                             | The chosen text.                             |
| `color`                     | A colour.                                         | A table that `love.graphics.setColor` takes. |
| `image`                     | An image file of the project.                     | A LÖVE image.                                |
| `sound`                     | A sound file of the project.                      | A LÖVE source of its own.                    |
| `font`                      | A font file of the project and a size.            | A LÖVE font.                                 |
| `file`                      | Any file of the project.                          | Its path.                                    |
| `scene`, `prefab`           | A scene or a prefab of the project.               | Its path.                                    |
| `object`                    | An object of the same scene.                      | The object.                                  |
| `vector`                    | Two number fields in one row.                     | A table with `x` and `y`.                    |
| `group`                     | The properties it holds, under one heading.       | A table with a field for each.               |
| `list`                      | Rows of one kind, which the user adds and removes. | A list of what that kind gives.             |

- `group` and `list` take other properties: `onlr.property.group({ width = onlr.property.number(32), height = onlr.property.number(32) })` is read as `self.box.width`, and `onlr.property.list(onlr.property.image())` as `self.frames[1]`.

- A scene keeps a file as its path and an object as its id.
- The engine loads each file once, and components that name the same file share it. A sound is the exception: each component gets its own source, so two can play at once.
- A value of a property that the type no longer declares is kept in the scene (4.2), and the component does not get it.

### 6.3 Functions

The engine calls the functions that a type has. All are optional.

| Function            | The engine calls it                                                                                   |
| ------------------- | ----------------------------------------------------------------------------------------------------- |
| `load()`            | Once, when its object enters the running scene. Every object of the scene exists then, and the properties are set. |
| `update(dt)`        | Each frame, with the seconds since the last one.                                                      |
| `draw()`            | Each frame, with the object's place applied, so drawing at 0, 0 draws at the object.                  |
| `destroy()`         | When its object is destroyed, or the scene ends.                                                      |
| Any callback of LÖVE | When LÖVE sends the event, with what LÖVE gives: `keypressed(key, scancode, isrepeat)`, `mousepressed(x, y, button)` and every other one. |
| `bounds()`          | When the editor asks for the rectangle that the component covers, in the object's own space. The scene view uses it to choose objects (12.3). |
| `drawEditor(chosen)` | In the scene view, in place of `draw`, with whether the component's object is chosen (6.4).          |

- The engine passes on every event that LÖVE has, by its name, so it needs no list of them, and an event of a newer LÖVE reaches scripts too.
- A function of an object that is not `active`, or of a component that is not `enabled`, is not called.
- A type may have more functions of its own, which other components call: `self.object:get("bump.body"):move(x, y)`.

### 6.4 In the scene view

- The scene view shows a scene that does not run: no `load`, `update` or event reaches a component.
- There the engine calls `drawEditor` in place of `draw`. A type that looks the same in the editor as in the game says so: `Sprite.drawEditor = Sprite.draw`. The engine's own components do.
- `drawEditor` also draws what only the editor shows, such as the outline of a body or the frame of a camera. It is LÖVE code, written with the component by its author.
- A type without `drawEditor` shows nothing in the scene view. Its `draw` is not called there, since it may need what `load` or `update` sets.
- A `drawEditor` that fails marks its object in the view, and the rest draws on.
- `drawEditor` is code, so it can do anything. The scene view is kept safe from it in four ways:
  - The engine saves all of LÖVE's drawing state before each `drawEditor` and restores it after, so a colour or a shader that one component sets does not reach the next.
  - The engine's functions that change a scene (7) change nothing there, and report an error.
  - The edit player's scene is a copy. The editor holds the scene and only sends it (12.2), so nothing that a component does there reaches the project's files.
  - A `drawEditor` that never returns stops the edit player only, which the editor starts again (12.1).

## 7. The engine's functions

The engine gives scripts few functions; the rest is LÖVE. The engine's source documents each.

| Function                                 | Does                                                                         |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| `onlr.start()`                           | Starts the engine, from `main.lua` (8).                                      |
| `onlr.conf(t)`                           | Sets LÖVE's settings from the project file, from `conf.lua` (3.1).           |
| `onlr.scene.load(path)`                  | Ends the running scene and loads another, when the current frame ends.       |
| `onlr.scene.find(name)`                  | Gives the first object of that name.                                         |
| `onlr.scene.get(type)`                   | Gives the scene's first component of a type, in the tree's order.            |
| `onlr.scene.spawn(prefab, x, y, parent)` | Makes an instance of a prefab in the running scene (9).                      |
| `onlr.scene.add(name, parent)`           | Makes an empty object.                                                       |
| `object:get(type)`                       | Gives the object's first component of a type.                                |
| `object:add(type, values)`               | Gives the object a component, and returns it.                                |
| `object:send(name, ...)`                 | Calls the function of that name in each of the object's components that has it. |
| `object:destroy()`                       | Destroys the object and its children, when the current frame ends.           |
| `object:toWorld(x, y)`, `object:toLocal(x, y)` | Turn a point of the object's space into the world's, and back.         |
| `object:setWorldPosition(x, y)`          | Moves the object to a point of the world, whatever its parents' places are.  |

- An object's fields are those of section 5, with `parent` and `children` as objects. A script reads and sets them: `self.object.x = 10`.
- The functions that declare properties are in `onlr.property` (6.2).
- `onlr.scene.get` finds what a scene has one of. A component that many others need, such as the world that bodies collide in, is a component on one object, and the others find it by its type.
- `object:send` is how a component makes an event of its own. The engine calls `keypressed` in every component when LÖVE reports a key; in the same way, a component that finds a contact calls `self.object:send("contact", other)`, and every component of that object that defines `contact(other)` is called. The name is agreed between the two components, and the engine does not know it.

## 8. The loop

### 8.1 A frame

- `onlr.start` sets `love.run`, LÖVE's own loop, which a game may replace. The engine's loop does what LÖVE's does, and adds the scene:
  1. It calls `love.load`, if the game defines it, then loads the project's first scene.
  2. For each event, it calls the game's own callback, such as `love.keypressed`, then the components' function of that name.
  3. It calls `love.update(dt)`, then the components' `update`.
  4. It clears the window, calls the components' `draw` through the camera (10), then `love.draw()`, which draws over the scene in the window's own space.
  5. It shows the frame.
- So code written for plain LÖVE in `main.lua` keeps working beside the scene, such as an interface drawn in `love.draw`.
- An error is LÖVE's: the game stops and LÖVE's error handler shows it, as in any game. A game may set its own handler, as LÖVE allows.
- In an exported game the loop does this and nothing else. What serves the editor is in `onlr/editor/`, which the engine loads only when the editor starts it (12), and which an export leaves out (14).

### 8.2 How a scene is kept

- An object is a Lua table with the fields of section 5. A component is a Lua table of its own values, which finds its type's functions through a metatable. A script reads and sets both as plain fields; no call stands between.
- For each function name, the engine keeps one flat list of the running scene's components that have that function, in the order of the tree. A frame walks the list of `update` and the list of `draw`, and an event walks the list of its name. So the engine walks no tree and asks no component what it has while the game runs, and an object costs a frame nothing for what its components do not define.
- The lists change only when an object or a component is added, removed, turned on or off, or moved in the tree. The engine makes such changes when the frame ends.
- Each object keeps its place in the world as a LÖVE transform. The engine works it out again only for an object whose place, or whose parent's, differs from the one it used last.

## 9. Prefabs

- A prefab's file returns one object, with its components and children, in the format of section 5, under the type `onlr.Prefab`.
- An instance in a scene is an object with `prefab`, the prefab's path. It has its own `id`, `name` and place. `overrides` holds the property values that differ from the prefab's, by the id of the object in the prefab and the component's place in it.
- An instance changes values only. It adds and removes no component and no child of the prefab's; such a change is made in the prefab.
- A change to a prefab reaches every instance, apart from the values an instance overrides.
- `onlr.scene.spawn` makes an instance while the game runs, and calls `load` of its components before it returns.

## 10. The engine's components

The engine has four component types. They are written as scripts are, with the functions of section 7 and LÖVE alone.

| Type          | Is                                                                                                  |
| ------------- | --------------------------------------------------------------------------------------------------- |
| `onlr.sprite` | An image, or a part of one.                                                                         |
| `onlr.text`   | A text in a font.                                                                                   |
| `onlr.shape`  | A rectangle, a circle, a line or a polygon, filled or as an outline.                                |
| `onlr.camera` | The view of the scene: its object's place is what the window's centre shows, turned and scaled as the object is. |

- A scene draws through its first camera that is active and enabled, in the order of the tree. A scene without one draws as plain LÖVE does, with 0, 0 at the window's top left.

## 11. Libraries

### 11.1 Using a library

- A library is Lua code that its author wrote for LÖVE games. The engine does not know it, and it does not know the engine (2.1).
- A project keeps its libraries in `lib/`. The engine adds that folder to the places where `require` looks, so a script loads a library by the name its author gives:

  ``` lua
  local bump = require("bump")
  ```

- `require("bump")` finds `lib/bump.lua` or `lib/bump/init.lua`. A library that the user copies in works the same way, with or without a pack.
- A script calls the library as the library's own documentation says. ONLR puts nothing between them and renames nothing.

### 11.2 Packs

A pack is a library made ready for ONLR: a folder in `lib/`, named as the library is loaded.

| In `lib/bump/`          | Is                                                              | Read by                                   |
| ----------------------- | --------------------------------------------------------------- | ----------------------------------------- |
| `pack.lua`              | The pack file: data that describes the pack (4.1).              | The editor. The game never loads it.      |
| `init.lua`              | Code: one line that returns the library.                        | The game, at `require("bump")`.           |
| `library/`              | The library's own files, unchanged, with its licence.           | The game, through `init.lua`.             |
| `world.lua`, `body.lua` | Component types, one in each file: `bump.world` and `bump.body`. | The game, when a scene names the type.   |

``` lua
---@type onlr.Pack
return {
  format = 1,
  name = "bump",
  description = "Collision of boxes",
  version = "3.1.7",
  source = "https://github.com/kikito/bump.lua",
  license = "MIT",
  components = { "bump.world", "bump.body" },
}
```

- The pack file and `init.lua` stay two files. The editor reads the pack file, and the editor's Lua cannot run the game's code, so the pack file holds data only (4.1).
- `library/` holds what the library's author ships. A newer version of the library replaces that folder and nothing else.
- A component type is one file, since its name is its file's (5). The names start with the pack's: `bump.body` is `lib/bump/body.lua`. The types are written as scripts are (6).
- `components` names the types that the editor offers (13).
- A pack adds nothing to the engine and changes nothing in it. A game uses a pack's library with its components, without them, or both.
- The editor copies a pack into a project when the user adds it, and deletes its folder when the user removes it. In the project, the pack is the project's own copy, and an export holds it.

### 11.3 A pack's components

A pack's components show a library in the inspector. The sample is a pack for bump, a library that keeps boxes in a world of its own and tells which ones a moving box hits. bump's world is not the scene: it is bump's own list of boxes, and it knows nothing of objects.

``` lua
-- lib/bump/body.lua: a box that collides
local onlr = require("onlr")

local Body = {}

Body.width = onlr.property.number(32)
Body.height = onlr.property.number(32)

function Body:load()
  local world = onlr.scene.get("bump.world") or onlr.scene.add("World"):add("bump.world")
  self.world = world:get()
  self.x, self.y = self.object:toWorld(0, 0)
  self.world:add(self, self.x, self.y, self.width, self.height)
end

function Body:move(x, y)
  local hits
  self.x, self.y, hits = self.world:move(self, x, y)
  self.object:setWorldPosition(self.x, self.y)
  for _, hit in ipairs(hits) do
    self.object:send("contact", hit.other.object, hit.normal.x, hit.normal.y)
    hit.other.object:send("contact", self.object, -hit.normal.x, -hit.normal.y)
  end
end

function Body:update()
  local x, y = self.object:toWorld(0, 0)
  if x ~= self.x or y ~= self.y then
    self.x, self.y = x, y
    self.world:update(self, x, y)
  end
end

function Body:destroy()
  self.world:remove(self)
end

function Body:bounds()
  return 0, 0, self.width, self.height
end

function Body:drawEditor()
  love.graphics.rectangle("line", 0, 0, self.width, self.height)
end

return Body
```

What the sample shows of every pack:

- **What a scene has one of** is a component of an object, as any other: here `bump.world`, on an object named World. It is made with the scene and ends with it, so each scene has its own, and the scene's file keeps its settings. It is not a module that lives through the whole game. A component that needs it finds it with `onlr.scene.get`, and makes it when the scene has none.
- **What the library must be told** is told by the component, in its `load` and `destroy`. bump asks for each box to be added to its world; the body does that, so the user does not.
- **Where an object is** has one truth: the object's own place (5). A library that keeps a place of its own, as bump does for each box, holds a copy, and the pack's component keeps the copy in step. After `move`, the object takes the library's answer. When a script sets the object's place itself, the component tells the library, in its `update`.
- **What a script asks of the library** is a function of the component: `body:move(x, y)`.
- **What the library reports** reaches scripts with `object:send`, as a function that the script defines: `contact(other)`. Both objects of a contact are told.
- **What the editor shows** is `bounds`, for choosing the object, and `drawEditor`, for the outline.

## 12. The player and the link

### 12.1 The player

- The player is LÖVE itself, unchanged, which the editor starts as a program of its own on the project's folder. An argument tells the engine that the editor started it, the mode, and where the editor listens.
- The editor starts it with SDL's offscreen video driver, `SDL_VIDEODRIVER=offscreen`, so it opens no window and still draws with the graphics card.
- A player runs in one of two modes:

  | Mode | Runs                                               | Shown in                    |
  | ---- | -------------------------------------------------- | --------------------------- |
  | Edit | Views: scenes drawn and not updated (12.3).        | The scene view and previews |
  | Play | The game.                                          | The game panel              |

- The edit player runs while a project is open. Play starts a second player and Stop ends it.
- The player is another program, so a game that fails or never returns leaves the editor running. The editor shows what happened, and starts the player again when asked.
- The player plays the game's sound itself.
- The editor reads what the player prints, and shows it in the console.

### 12.2 The link

- The link is a TCP connection on this computer: the editor listens on a free port of `127.0.0.1`, and the engine connects to it with LuaSocket, which LÖVE ships.
- Both send the link's version first. Versions that differ end the link with a message that says so.
- A message is a Lua table written as text, and may carry a block of bytes after it, such as a frame's pixels. Each message starts with the sizes of both.

| The editor sends     | For                                                                          |
| -------------------- | ---------------------------------------------------------------------------- |
| A scene              | The scene to show or to run: the editor's own copy, saved or not.            |
| A change             | One edit of a scene in the edit player, such as a moved object or a new value. |
| A view               | Which scene to draw, from where, and at what size (12.3).                    |
| Input                | In play mode: the panel's key, text, pointer and wheel events.               |
| A question           | What a component type declares.                                              |
| Reload               | A file of the project changed.                                               |

| The engine sends     | For                                                                          |
| -------------------- | ---------------------------------------------------------------------------- |
| A frame              | The picture to show. In edit mode, the objects' bounds with it (12.3).       |
| An answer            | A type's properties, or why its file does not load.                          |
| An error             | A message with its file, line and stack.                                     |

### 12.3 Views

- The edit player only draws. It draws views: a view is a scene, the point and the zoom it is seen from, and a size.
- The scene view is a view of the open scene. A preview is a view of a scene that the editor makes up, such as one object with one sprite. So a preview of an image, a font, a prefab or a component needs no drawing code of its own, in the editor or in the engine.
- The edit player draws a view when the editor asks: after a change, or when the view moves. It runs no loop of frames, so it uses the processor only when something changed.
- What is drawn is split by what it depends on:

  | Drawn by                    | What                                                                  | Because                                                       |
  | --------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------- |
  | The edit player, in LÖVE    | Each component's `drawEditor` (6.4): its picture, and its own outlines. | It depends on the component, and its author writes LÖVE code. |
  | The panel, over the frame   | The grid, the outline of the chosen objects, and their handles.        | It depends on the pointer and the tool, and is the same for every component. |

- With each frame of a view, the engine sends every object's `bounds` (6.3) as the view shows them. The panel draws its part from them and finds the object under the pointer from them. So its outlines never part from the picture, and a click needs no answer from the player.
- An object without `bounds` covers no rectangle, such as one whose only component is a script. The panel draws a small marker at its place, so it can be seen and chosen.

### 12.4 Frames

- In the player, the engine draws into a canvas instead of the window, reads the canvas back, and sends its pixels.
- In edit mode the canvas has the view's size. In play mode it has the project's `width` and `height`, and the panel shows it scaled to fit, with its proportions kept.
- The engine sends the pixels as OpenECS's images hold them, so the panel shows a frame without work on each pixel.
- The engine sends a frame only when the editor has shown the last one, so a slow panel never fills the link.

### 12.5 Input

- The game panel sends its events. The engine gives them to the loop as LÖVE's events, so `keypressed` and the others run as in a window.
- In the player, the engine also answers LÖVE's questions about the keyboard and the pointer, such as `love.keyboard.isDown` and `love.mouse.getPosition`, from what the panel sent. This is the one place where the engine stands in for functions of LÖVE, and it does so only in the player.

### 12.6 What the editor learns from LÖVE

- The editor never loads a script. To show a type's properties, it asks the edit player, which loads the file as the game would and answers with its `properties`.
- When a script changes on disk, the edit player loads it again, and the editor asks again.

## 13. The editor

- The editor is an OpenECS tool: a preset and plugins, in Lua unless a part needs C. The user never sees or writes them.
- It builds on OpenECS's standard plugins (OpenECS-std DESIGN): process starts the player, net carries the link, fs watches the project, compress and hash serve export, web downloads LÖVE, and ui and draw make the panels.

| Plugin         | Does                                                                                          |
| -------------- | --------------------------------------------------------------------------------------------- |
| `onlr_project` | Holds the open project: its file, its scenes and prefabs, the chosen objects and the history. It reads and writes the files, and watches the folder. |
| `onlr_player`  | Starts the players and speaks the link. It gives the scene view and the game panel.           |
| `onlr_views`   | The other panels of OVERVIEW 7.                                                               |
| `onlr_export`  | Export (14), and LÖVE's packages (15).                                                        |

- The inspector shows the chosen object's place, then each of its components under its type's name. A component has one row for each property, in the order its type declares them: the property's name, and the control of its kind (6.2).
- Adding a component offers the engine's types (10), the types that the project's packs name (11.2), and any Lua file of the project as a script.
- The project's data lives in `onlr_project`, not in a panel (OpenECS OVERVIEW 9.2). Panels show it, change it through its functions, and hear of changes through its events. So two panels never differ.
- Each change of a scene or a prefab is a record that can be undone. `onlr_project` keeps them in one history for the project.
- A scene or a prefab with changes marks its panel as unsaved, so OpenECS asks before it closes (OpenECS OVERVIEW 5.5).
- A file of the project that changes on disk is read again. When the editor's copy has unsaved changes too, the editor asks which to keep.
- Opening a file at a line in the user's code editor runs a command that is a setting.

## 14. Export

### 14.1 The `.love` file

- A `.love` file is a zip archive of the project's folder, with `main.lua` at its root.
- It leaves out `.onlr/`, `.luarc.json`, `onlr/editor/`, every file and folder whose name starts with a dot, and what the project file's `exclude` names.
- The licences travel with their parts: the engine's is in `onlr/`, and a library's is in the library's folder.

### 14.2 Builds

A build is made from the `.love` file and LÖVE's package for the platform (15.2), by copying and joining files. It runs no tool of the target's platform.

| Target        | The build                                                                                                         |
| ------------- | ----------------------------------------------------------------------------------------------------------------- |
| Linux x86_64  | LÖVE's files, with the `.love` file joined to the end of LÖVE's executable, in a `.tar.gz` archive that keeps the files' permissions. A launcher named after the game starts it. |
| Windows x86_64 | `love.exe` with the `.love` file joined to its end, named after the game, beside LÖVE's libraries, in a zip archive. |

- LÖVE runs a `.love` file that is joined to the end of its executable.
- A build holds LÖVE's `license.txt`, which lists the licences of LÖVE and of the libraries inside it.

## 15. LÖVE

### 15.1 Version

- ONLR is made for LÖVE 11.5, and a project names the version it is made for (3.2).
- The engine avoids the functions that LÖVE's development version, 12.0, removes or renames, so the move to it stays small.

### 15.2 Packages

- A package is LÖVE for one version and one platform, as files in a folder.
- ONLR's archive holds the package of the editor's own platform, which the player runs. On Linux it is the contents of LÖVE's AppImage, unpacked, so it runs without the system's AppImage support.
- The package of another platform is downloaded from LÖVE's releases at the first export for it. The editor checks it against SHA-256 hashes that ONLR ships, and keeps it in the user's data folder, by version and platform.
- A setting names a folder to use as a package instead, such as a LÖVE the user built.

## 16. Tests

- The samples are the tests. A sample is a small project that shows one part of ONLR, and it has one test.
- A sample's test of the engine runs the sample in LÖVE with the offscreen driver; the sample checks itself and ends with a status.
- A sample's test of the editor is an OpenECS test (OpenECS DESIGN 17.5): it opens the sample, acts as a user would, and checks the files that the editor writes.
- A change that breaks a sample changes the sample in the same piece of work.

## 17. Versions and branches

- The engine uses semantic versioning. A project names the engine's version it holds (3.2).
- A file format's `format` and the link's version are numbers that change on their own, when an older part cannot read the newer.
- `dev` is the default branch, where work is merged. `main` holds what is stable: it changes only through a pull request from `dev`, which the owner merges.

## Glossary

**AppImage.** A way to ship a Linux program as one file. LÖVE's Linux release is one.

**Canvas.** A picture in the graphics card's memory that LÖVE draws into instead of the window.

**Component type.** A Lua file that returns a table with a component's properties and functions.

**Definition.** A LuaLS annotation that tells a code editor a type's fields or a function's parameters.

**Edit player.** The player that draws views for the editor.

**Frame.** One picture of the game.

**Link.** The connection between the editor and a player.

**Library.** Lua code that its author wrote for LÖVE games to use.

**LuaJIT.** The implementation of Lua that LÖVE runs. Its language is Lua 5.1 with additions.

**LuaLS.** The Lua language server, which completes and checks Lua code in code editors.

**LuaSocket.** A Lua library for network connections, which LÖVE ships.

**Offscreen driver.** A video driver of SDL that opens no window.

**Package.** LÖVE for one version and one platform, as files in a folder.

**Pack.** A library made ready for ONLR, with component types that show it in the inspector.

**Player.** LÖVE, started by the editor on the project, without a window.

**SDL.** The library through which LÖVE and OpenECS use windows, input and graphics.

**Transform.** LÖVE's object for a position, a rotation and a scale together.

**View.** A scene as the edit player draws it: seen from a point, at a zoom and a size.
