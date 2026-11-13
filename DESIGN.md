# ONLR Technical Design

This document explains how ONLR is built: its parts, the project's files, the engine, the link between editor and game, and export. Read [OVERVIEW.md](OVERVIEW.md) first; this document uses its words and does not repeat it.

**How to read it:**

- Everything here is decided. Open questions and pending work are in [TODO.md](TODO.md).
- Code samples are only illustrations of a file or an interface.
- Samples that need a library use bump, a library for collision. It stands for any library: this document chooses none.
- Technical terms are explained in the glossary at the end.
- "OpenECS DESIGN" names [OpenECS's DESIGN.md](https://github.com/omerfuyar/OpenECS/blob/dev/DESIGN.md), and "OpenECS-std DESIGN" [OpenECS-std's](https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md). OpenECS changes often, so this document links to them and repeats nothing of theirs. Only the editor depends on OpenECS: section 13, and what sections 1, 2.2 and 16 say of the editor.

---

## Contents

1. Conventions
2. Parts
3. Projects
4. Data files
5. Nodes
6. Components
7. The engine's functions
8. The loop
9. Instances
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
- Lua names use camelCase: `onlr.node.loadRoot`, `startNode`. Files and folders have lowercase names.
- A node's place has short names, since scripts write them most: `posX`, `posY`, `rot`, `sclX` and `sclY`.
- Functions of one kind share a namespace, such as `onlr.node`. What acts on a node or a component is its method.
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
| 3. The engine      | Nodes, components, properties and the loop (5 to 9).                              | ONLR                               | LÖVE                           |
| 4. Components      | What nodes show and do: the engine's own (10), a pack's (11.2) and the user's scripts (6). | ONLR, a pack's author, the user | The engine, LÖVE and libraries |
| 5. The game's data | The project's manifest and node files, which name component types and hold their values (3, 4). | The user, through the editor | Component types, by name       |

- The engine and the libraries do not know each other. A component is where they meet: it is called by the engine, and it calls a library.
- All three kinds of component are the same thing to the engine. The engine's own and a pack's can do nothing that a script cannot.
- The editor is not a layer of the game. It is another program: it reads and writes the game's data, and asks the player (12) what the components declare and how the nodes look.

### 2.2 In this repository

| Part           | In this repository       | Is                                                                                | Runs in |
| -------------- | ------------------------ | --------------------------------------------------------------------------------- | ------- |
| Engine         | `engine/`                | The Lua library that every project holds a copy of, as `lib/onlr/`.               | LÖVE    |
| Player's files | `player/`                | The Lua code that the engine loads when the editor starts it: the link and the views (12). No project holds it. | LÖVE    |
| Editor         | `plugins/`, `preset.lua` | OpenECS plugins and their preset (13).                                            | OpenECS |
| Samples        | `samples/`               | Small projects, which are the tests (16).                                         | Both    |

## 3. Projects

### 3.1 The folder

``` text
mygame/
  main.lua                  starts the engine
  conf.lua                  gives LÖVE the project's settings
  manifest.lua              the project's manifest
  components/               the scripts: the component types that the user writes
    coin.lua                  the type coin
    player/                   the type player, with modules of its own
      init.lua
      states.lua
  shared/                   the user's Lua code that components share
    score.lua
  lib/                      the engine, packs and libraries
    onlr/                     the engine
    bump/                     a pack
  nodes/                    the node files
    level.lua
    coin.lua
  images/                   assets, in any folders of any name
    player.png
  .onlr/                    the editor's own files for this project
  .luarc.json               tells a code editor where the definitions are
```

- LÖVE's file functions and its `require` read a game's files only from the game's own folder. So the engine and the files that start it are in the project, and `love mygame` runs it.
- The editor writes `main.lua` and `conf.lua` once, when it makes the project. They are the user's afterwards:

  ``` lua
  -- main.lua
  require("lib.onlr").start()
  ```

  ``` lua
  -- conf.lua
  function love.conf(t)
    require("lib.onlr").conf(t)
  end
  ```

- `onlr.conf` sets what the project's manifest holds: the window's size, the game's name and the folder of its saved files. A user who wants more of LÖVE's settings sets them in `conf.lua`, after that line.
- Both files load the engine as `lib.onlr`, which LÖVE finds in the project's folder as it is. When the engine loads, it adds `lib/` to the places where `require` looks, and answers to the name `onlr` too. LÖVE reads `conf.lua` before any other file of the game, so from then on a script writes `require("onlr")`, and a library is loaded by the name its author gives (11.1).
- `components/` holds the scripts. The editor offers them when the user adds a component, and makes new scripts there. Inside it:
  - A Lua file is a component type: `components/coin.lua` is `coin`.
  - A folder with an `init.lua` is one component type, and the other files in it are that component's own modules, which the editor does not offer: `components/player/init.lua` is `player`, and it loads `components.player.states` with `require`.
  - A folder without an `init.lua` only groups what is in it: `components/enemies/bat.lua` is `enemies.bat`.
- `nodes/` holds the node files (5). Every Lua file in it, in any folder of it, is one: `nodes/level.lua`.
- `shared/` holds the user's Lua code that is not a component and that components share: what keeps a value when the root changes, such as a score, and functions that many scripts use. The engine does not read it: scripts load it with `require`, as in any LÖVE game. Its name is not taken; a new project has it.
- `lib/` holds what the game uses and was not made for this game alone, each in a folder of its own: the engine in `lib/onlr/`, packs, and libraries. The user adds to it, by hand or in the editor.
- `lib/onlr/` is the engine's. The editor replaces it when it updates the engine (3.3), so the user does not edit it.
- `.onlr/` holds what the editor keeps for this project on this computer, such as LÖVE's definitions (4.3). It is not in git and not exported.
- The names `main.lua`, `conf.lua`, `manifest.lua`, `components/`, `nodes/`, `lib/` and `.onlr/` are taken. Every other name is the user's.

### 3.2 The project's manifest

``` lua
---@type onlr.Project
return {
  format = 1,
  name = "My game",
  id = "org.example.mygame",
  gameVersion = "0.1.0",
  loveVersion = "11.5",
  startNode = "nodes/menu.lua",
  window = {
    width = 1280,
    height = 720,
  },
  exclude = {
    "notes/*",
  },
}
```

| Field             | Holds                                                                           |
| ----------------- | ------------------------------------------------------------------------------- |
| `format`          | The version of this file's format.                                              |
| `name`            | The game's name: its window's title, and the name of its exports.               |
| `id`              | A reversed domain that names the game to the system, such as its saved files' folder. |
| `gameVersion`     | The game's own version.                                                         |
| `loveVersion`     | The version of LÖVE the game is made for.                                       |
| `startNode`       | The node file that the game starts with, as its root (5).                       |
| `window`          | The game's window, in the names of LÖVE's `t.window`: its `width` and `height`, in pixels. |
| `exclude`         | Patterns of files that an export leaves out.                                    |

- The window's size is here, and not only in `conf.lua`, since two things need it: LÖVE, before it opens the window, and the project settings panel, to show and change it. The editor does not run `conf.lua`, which is the game's code.

### 3.3 Updating the engine

- The editor ships one version of the engine, and works on a project that holds that version. The engine's manifest in `lib/onlr/` names its version (8.3).
- When the editor opens a project that holds another version, it asks the user, then replaces `lib/onlr/`. If the user declines, the project stays closed.

## 4. Data files

### 4.1 Rules

- Every file that ONLR writes is a Lua file that returns one table: manifests and node files.
- The table is plain data: numbers, texts, booleans and tables, and no function.
- The engine and the editor each read a file by running it, with their own Lua: LuaJIT in the game, and the editor's Lua. The file runs with Lua's basic functions and its `string`, `table` and `math` libraries, and nothing else. It cannot reach LÖVE, the engine, the editor or another file.
- So a file that a person writes may compute its table, such as a manifest that works out the window's size. Its code must be Lua that both run.
- A file's kind is known by its folder, without reading it: a node file is in `nodes/`, as a script is in `components/` (3.1). No file's name has a second ending.
- Each file has a `format` number. The engine and the editor refuse a newer format than they know, and say so.

### 4.2 How the editor writes them

- A node file is the editor's to read and to write, and its format is made for that. A node is named by its id and a component by its type's name, so each change names what it changes, wherever that has moved since.
- The editor writes data only: the table's values. A save writes the whole file again, so code and comments that a person wrote in it are not kept.
- So the editor asks before it replaces such a file. It knows one when it reads it: the file's text differs from what the editor would write for the same table.
- A file is written beside the old one and then renamed over it, so it is never left half-written.
- Fields are written in a fixed order, one on each line, and each item of a list starts on its own line. So two changes to different nodes merge in git.
- A value that equals its default is left out, so a file holds only what the user set. In an instance, the value in the instance's node file is the default (9).
- A node's `id` is a short random text, which the editor gives once. Nodes are named by id wherever one refers to another, never by their place in a list.
- A field or a component type that the editor does not know is kept as it is, and written back.

### 4.3 Definitions

- The first line of each file names its type, such as `---@type onlr.NodeFile`, so a code editor with the Lua language server completes and checks its fields.
- The types are in the engine's source, in the project's `lib/onlr/` (1). LÖVE's own definitions, from [LuaCATS/love2d](https://github.com/LuaCATS/love2d), are copied into `.onlr/`.
- The editor writes `.luarc.json` once, when it makes the project. It names LuaJIT as the Lua version, `.onlr/` as a library, and `lib/` as a place where `require` looks (11.1):

  ``` json
  {
    "runtime.version": "LuaJIT",
    "runtime.path": ["?.lua", "?/init.lua", "lib/?.lua", "lib/?/init.lua"],
    "workspace.library": [".onlr"]
  }
  ```

- A script names its type with an annotation, under the type's name: `---@class player : onlr.Component`.
- The editor writes a definition of `node.components` (6.1) into `.onlr/`, with a field for each component type of the project, and writes it again when a type is added or removed. So a code editor knows what `self.node.components.player` is.

## 5. Nodes

``` lua
-- nodes/level.lua
---@type onlr.NodeFile
return {
  format = 1,
  id = "l3v1",
  name = "Level",
  components = {
    bump = {
      world = {
        cellSize = 32,
      },
    },
  },
  children = {
    {
      id = "k3f9",
      name = "Player",
      posX = 100,
      posY = 200,
      components = {
        onlr = {
          sprite = {
            image = "images/player.png",
          },
        },
        player = {
          speed = 250,
        },
      },
      children = {
        {
          id = "p7c2",
          name = "Shadow",
          posY = 12,
          z = -1,
          components = {
            onlr = {
              sprite = {
                image = "images/shadow.png",
              },
            },
          },
        },
      },
    },
  },
}
```

- A node file returns one node, with `format` beside the node's own fields (4.1). Every other node of the file is under that one: its child, or a child of one of those.

| Field of a node    | Holds                                                                         | Default |
| ------------------ | ----------------------------------------------------------------------------- | ------- |
| `id`               | Its id, unique in its file.                                                   |         |
| `instance`         | The node file it is an instance of (9).                                       |         |
| `name`             | Its name. Names need not be unique.                                           |         |
| `posX`, `posY`     | Its position in its parent, in pixels.                                        | 0       |
| `rot`              | Its angle in its parent, clockwise.                                           | 0       |
| `sclX`, `sclY`     | Its scale in its parent.                                                      | 1       |
| `z`                | Its order in drawing, added to its parent's.                                  | 0       |
| `active`           | Whether it and its children update, draw and get events.                      | true    |
| `components`       | Its components, by their types' names (6.1). Each is a table of its properties' values, and of `enabled`, which is true when left out. | |
| `children`         | Its children, nodes too.                                                      |         |
| `overrides`        | In an instance, what differs in the nodes under it (9).                       |         |

- The game runs one node at a time, with all that is under it. That node is the root, which `onlr.node.root` gives, and the root with the nodes under it is the tree.
- The game starts with the node file that the manifest names (3.2), and `onlr.node.loadRoot` puts another in its place (7). A level and a coin are node files alike: the game loads the level as its root, and the level holds the coin as an instance (9).
- What the whole tree has one of, such as the world that its bodies collide in, is a component of the root. No node is made only to hold one.
- Nodes update, and get events, in the order of the tree: a parent, then its children, and siblings in the order of their list. `z` plays no part in it.
- Nodes draw by `z`, the lowest first. A node's z is its own added to its parent's, so a child with a negative `z` draws behind its parent. Nodes of the same z draw in the order of the tree.
- A node's components load, update and draw in the order of their names, and each after those that it needs (6.6).
- The engine keeps each node's place in the world, from its own and its parents', as a LÖVE transform.

## 6. Components

### 6.1 A component type

A component type is a Lua file that returns a table. A script is one:

``` lua
local onlr = require("onlr")

---@class player : onlr.Component
local Player = {}

Player.speed = onlr.property.number(200, { description = "Pixels a second" })
Player.image = onlr.property.image()

function Player:load()
  self.jumps = 0
end

function Player:update(dt)
  if love.keyboard.isDown("right") then
    self.node.posX = self.node.posX + self.speed * dt
  end
end

function Player:draw()
  love.graphics.draw(self.image)
end

function Player:keypressed(key)
  if key == "space" then
    onlr.node.spawn("nodes/bullet.lua", self.node.posX, self.node.posY)
  end
end

return Player
```

- A type's name says where its file is:

  | Type                | Its name                                   | Its file                    |
  | ------------------- | ------------------------------------------ | --------------------------- |
  | A script            | Its path in `components/`: `player`, `enemies.bat`. | `components/player.lua` (3.1) |
  | A pack's            | The pack's name, then its file's: `bump.body`. | `lib/bump/body.lua` (11.2) |
  | The engine's own    | `onlr.`, then its file's: `onlr.sprite`.   | `lib/onlr/sprite.lua` (10)  |

- The engine looks for a type in `components/` first, then in `lib/`. So a script cannot have the name of the engine or of a pack, and the editor says so.
- A node has at most one component of a type. Giving it a second is an error.
- A node keeps its components in `components`, by their types' names. A dot in a name is a table in a table: `bump.body` is `components.bump.body`. A node file writes them so (5), and a script reads them so: `self.node.components.bump.body`.
- Each component of a node is a table of its own, which finds its functions in its type. So `self` is the component, and what a function keeps in `self` belongs to that one node.
- `self.node` is the node, and `self.enabled` turns the component off and on.
- A type does not inherit another. What two types share is a module that both load (3.1), or a component of its own that both find on the node.

### 6.2 Properties

- A type declares a property as a field, with a function of `onlr.property`: `Player.speed = onlr.property.number(200)`.
- When the engine loads a type, it reads these declarations, then puts each property's default in the declaration's place. From then on `Player.speed` is 200, and a property without a default is `nil`.
- A component reads a property under the same name: `self.speed`. It holds the values that its node file gives, which the engine sets before `load`, and finds the others in its type. A default that is a table, such as a colour, is copied into each component, so changing one changes no other.
- Each function takes the default value, then optionally a table of options: a `description`, which the inspector shows, and what the table below names. A kind that names a file or a node has no default and takes the options only, and `vector` takes its two numbers.
- Each declaration gets a number when its function is called. The inspector shows a type's properties by that number, which is the order its file declares them in.
- Each function's annotation names what the component gets, so a code editor knows that `self.speed` is a number.
- A property cannot be named `enabled`, `node` or `needs`, which a component or its type has (6.1, 6.6), or as a function of its type.

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
| `nodeFile`                  | A node file of the project.                       | Its path.                                    |
| `node`                      | A node of the same file.                          | The node.                                    |
| `vector`                    | Two number fields in one row.                     | A table with `x` and `y`.                    |
| `group`                     | The properties it holds, under one heading.       | A table with a field for each.               |
| `list`                      | Rows of one kind, which the user adds and removes. | A list of what that kind gives.             |

- `group` and `list` take other properties: `onlr.property.group({ width = onlr.property.number(32), height = onlr.property.number(32) })` is read as `self.box.width`, and `onlr.property.list(onlr.property.image())` as `self.frames[1]`.

- A node file keeps a file as its path, and a node as its id, or as a path of ids when the node is inside an instance (9).
- The engine loads each file once, and components that name the same file share it. A sound is the exception: each component gets its own source, so two can play at once.
- A value of a property that the type no longer declares is kept in the node file (4.2), and the component does not get it.

### 6.3 Functions

The engine calls the functions that a type has. All are optional.

| Function             | The engine calls it                                                                                   |
| -------------------- | ----------------------------------------------------------------------------------------------------- |
| `load()`             | Once, when its node enters the tree. The properties are set, and every node that enters with it exists. The component makes here what it holds. |
| `enable()`           | When the component starts to run: after `load`, and each time it is turned on again.                 |
| `start()`            | Once, before the component's first `update`. Every `load` before it is done, so the component looks at others here. |
| Any callback of LÖVE | When LÖVE sends the event, with what LÖVE gives: `keypressed(key, scancode, isrepeat)`, `mousepressed(x, y, button)` and every other one. |
| `update(dt)`         | Each frame, with the seconds since the last one.                                                      |
| `lateUpdate(dt)`     | Each frame, after every `update`. What follows another node, such as a camera, moves here.           |
| `draw()`             | Each frame, with the node's place applied, so drawing at 0, 0 draws at the node.                     |
| `disable()`          | When the component stops running: each time it is turned off, and before `destroy`.                  |
| `destroy()`          | Once, when its node is destroyed, or the root is replaced.                                            |
| `bounds()`           | When the editor asks for the rectangle that the component covers, in the node's own space. The node view uses it to choose nodes (12.3). |
| `drawEditor(chosen)` | In the node view, in place of `draw`, with whether the component's node is chosen (6.5).              |

- The engine passes on every event that LÖVE has, by its name, so it needs no list of them, and an event of a newer LÖVE reaches scripts too. So a type's function with the name of one of LÖVE's callbacks, such as `focus` or `resize`, is called for that event.
- A type may have more functions of its own, which other components call: `self.node.components.bump.body:move(x, y)`.

### 6.4 When functions are called

- A component's life is `load`, `enable`, `start`, then each frame its events, `update`, `lateUpdate` and `draw`, and at its end `disable` and `destroy`.
- A component runs while it is `enabled`, and its node and every node above that are `active`. Only a component that runs gets `start`, events, `update`, `lateUpdate` and `draw`.
- `load` and `destroy` are called once each, whatever the node and the component are set to. They make and free what the component holds.
- `enable` and `disable` are called each time the component starts and stops running, so every `enable` has its `disable`. What a component gives to others while it runs, such as a body's box in its world, is given in `enable` and taken back in `disable`.
- `start` is called once, in the first frame in which the component runs, before that frame's `update`.
- In a frame, each function is called for the whole tree before the next one is (8.1). It goes through the tree in the tree's order, and through a node's components in theirs (5). `draw` goes in the order of drawing.
- When a root loads, the engine makes all its nodes, then calls `load` and `enable` of each component.
- What a script makes exists at once: an instance from `onlr.node.spawn`, a node from `onlr.node.add`, and a component from `node:add` (7). `onlr.node.find`, `onlr.node.findComponent`, `children` and `components` give it, and its `load` and `enable` are called before the function that made it returns. Its `start` and its other functions are called from the next frame on. So a script sets values on what it made, and `start` finds them.
- `node:destroy()` marks the node. It stays in the tree, and its functions are called, until the frame ends. Then the engine calls `disable` and `destroy` of its children's components, then of its own, and takes them out of the tree.
- `onlr.node.loadRoot` does the same to every node of the tree when the frame ends. Then it makes the new root.
- What a function returns is not used. `quit` is the exception: as in LÖVE, the game does not quit when `love.quit` or a component's `quit` returns true.

### 6.5 In the node view

- The node view shows nodes that do not run: no `load`, `update` or event reaches a component.
- There the engine calls `drawEditor` in place of `draw`. A type that looks the same in the editor as in the game says so: `Sprite.drawEditor = Sprite.draw`. The engine's own components do.
- `drawEditor` also draws what only the editor shows, such as the outline of a body or the frame of a camera. It is LÖVE code, written with the component by its author.
- A type without `drawEditor` shows nothing in the node view. Its `draw` is not called there, since it may need what `load` or `update` sets.
- A `drawEditor` that fails marks its node in the view, and the rest draws on.
- `drawEditor` is code, so it can do anything. The node view is kept safe from it:
  - The engine saves all of LÖVE's drawing state before each `drawEditor` and restores it after, so a colour or a shader that one component sets does not reach the next.
  - The engine's functions that change the tree (7) change nothing there, and report an error.
  - The edit player's nodes are a copy. The editor holds the node file and only sends it (12.2), so nothing that a component does there reaches the project's files.
  - A `drawEditor` that never returns stops the edit player only, which the editor starts again (12.1).

### 6.6 Types that need others

``` lua
Player.needs = { "bump.body" }
```

- A type names the types that its components need on their node, in `needs`.
- The script's author writes `needs`. The engine does not work it out from the script's code.
- A node that gets a component gets those that it needs too, each with its defaults, when the node lacks them: in the editor, when a node file loads, and at `node:add`.
- The editor does not remove a component that another of the node needs. It names the other.
- A component loads, updates and draws after those that it needs (5). So its `load` finds them loaded, and `self.node.components.bump.body` is there without a check.
- Types cannot need each other in a circle. The engine refuses such a type, and says so.

## 7. The engine's functions

These are the engine's functions for scripts. The rest is LÖVE. The engine's source documents each.

| Function                               | Does                                                                                |
| -------------------------------------- | ----------------------------------------------------------------------------------- |
| `onlr.start()`                         | Starts the engine, from `main.lua` (8).                                             |
| `onlr.conf(t)`                         | Sets LÖVE's settings from the project's manifest, from `conf.lua` (3.1).            |
| `onlr.node.root`                       | The root (5).                                                                       |
| `onlr.node.loadRoot(path)`             | Ends the root and loads another node file as the root, when the current frame ends. |
| `onlr.node.find(name)`                 | Gives the tree's first node of that name.                                           |
| `onlr.node.findComponent(type)`        | Gives the tree's first component of a type, in the tree's order, the root's first.  |
| `onlr.node.spawn(path, x, y, parent)`  | Makes an instance of a node file at a place in its parent, and returns it (9).      |
| `onlr.node.add(name, parent)`          | Makes an empty node in its parent, and returns it.                                  |
| `node:add(type, values)`               | Gives the node a component of a type that it lacks, and returns it.                 |
| `node:send(name, ...)`                 | Calls the function of that name in each of the node's components that has it.       |
| `node:destroy()`                       | Destroys the node and its children, when the current frame ends.                    |
| `node:toWorld(x, y)`, `node:toLocal(x, y)` | Turn a point of the node's space into the world's, and back.                    |
| `node:setWorldPosition(x, y)`          | Moves the node to a point of the world, whatever its parents' places are.           |

- A node's fields are those of section 5, with `parent` and `children` as nodes, and `components` as the components themselves (6.1). A script reads and sets them: `self.node.posX = 10`. No function stands before a component: `self.node.components.onlr.sprite`.
- A `parent` that is left out is the root.
- When each function takes effect is in section 6.4.
- The functions that declare properties are in `onlr.property` (6.2).
- A function takes a type's name as one text, dots and all: `onlr.node.findComponent("bump.world")`.
- `onlr.node.findComponent` finds what the tree has one of. A component that many others need, such as the world that bodies collide in, is a component of the root (5), and the others find it by its type.
- `node:send` is how a component makes an event of its own. The engine calls `keypressed` in every component when LÖVE reports a key; in the same way, a component that finds a contact calls `self.node:send("contact", other)`, and every component of that node that defines `contact(other)` is called. The name is agreed between the two components, and the engine does not know it.

## 8. The loop

### 8.1 A frame

- `onlr.start` sets `love.run`, LÖVE's own loop, which a game may replace. The engine's loop does what LÖVE's does, and adds the tree:
  1. It calls `love.load`, if the game defines it, then loads the manifest's start node as the root.
  2. For each event, it calls the game's own callback, such as `love.keypressed`, then the components' function of that name.
  3. It calls `start` of the components that run and have not had it.
  4. It calls `love.update(dt)`, then the components' `update`, then their `lateUpdate`.
  5. It clears the window, calls the components' `draw` through the camera (10), in the order of drawing (5), then `love.draw()`, which draws over the nodes in the window's own space.
  6. It shows the frame.
  7. It takes out what was destroyed, and loads a new root if a script asked for one (6.4).
- So code written for plain LÖVE in `main.lua` keeps working beside the nodes, such as an interface drawn in `love.draw`.
- An error is LÖVE's: the game stops and LÖVE's error handler shows it, as in any game. A game may set its own handler, as LÖVE allows.
- In an exported game the loop does this and nothing else. What serves the editor is not in the project: the engine loads it from ONLR's own folder, and only when the editor starts it (12.1).

### 8.2 How the tree is kept

- A node is a Lua table with the fields of section 5. A component is a Lua table of its own values, which finds its type's functions and defaults through a metatable. A script reads and sets both as plain fields; no call stands between.
- For each function name, the engine keeps one flat list of the tree's components that have that function, in the order of the tree. The list of `draw` is in the order of drawing instead (5). A frame walks the list of `update` and the list of `draw`, and an event walks the list of its name. So the engine walks no tree and asks no component what it has while the game runs, and a node costs a frame nothing for what its components do not define.
- The lists change only when a node or a component is added, removed, turned on or off, or moved in the tree, or when a `z` changes. The engine makes such changes when the frame ends.
- Each node keeps its place in the world as a LÖVE transform. The engine works it out again only for a node whose place, or whose parent's, differs from the one it used last.

### 8.3 The engine's files

Each file of the engine holds one thing:

| In `lib/onlr/`                                      | Holds                                                                               |
| --------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `manifest.lua`                                      | The engine's name, its version and its component types, as a pack's does (11.2).    |
| `init.lua`                                          | What `require("onlr")` gives: `start`, `conf`, and the namespaces of the files below. It joins them, sets where `require` looks (3.1), and does nothing else. |
| `loop.lua`                                          | The loop (8.1).                                                                     |
| `tree.lua`                                          | `onlr.node`: the root, the tree and its lists (8.2).                                |
| `node.lua`                                        | Nodes and their functions (7).                                                    |
| `property.lua`                                      | `onlr.property` (6.2).                                                              |
| `data.lua`                                          | Reading data files (4), and loading the files that properties name.                 |
| `sprite.lua`, `text.lua`, `shape.lua`, `camera.lua` | The engine's components (10), one in each file.                                     |

- The engine is in `lib/` as a pack is, with a manifest that names its component types. So the editor finds the engine's components and a pack's in one way.
- `conf.lua` loads the engine before LÖVE has loaded its modules for drawing, input and the rest (3.1): only its file functions are sure to be there. So no file of the engine uses another part of LÖVE while it loads, only when its functions run.

## 9. Instances

``` lua
-- nodes/coin.lua
---@type onlr.NodeFile
return {
  format = 1,
  id = "c0in",
  name = "Coin",
  components = {
    coin = {},
    onlr = {
      sprite = {
        image = "images/coin.png",
      },
    },
  },
  children = {
    {
      id = "g1nt",
      name = "Glint",
      posX = 4,
      posY = -4,
      components = {
        onlr = {
          sprite = {
            image = "images/glint.png",
          },
        },
      },
    },
  },
}
```

``` lua
-- in nodes/level.lua: an instance that is twice as large, worth more, and without its glint
{
  id = "t1r6",
  instance = "nodes/coin.lua",
  name = "Big coin",
  posX = 700,
  posY = 540,
  sclX = 2,
  sclY = 2,
  components = {
    coin = {
      worth = 5,
    },
  },
  overrides = {
    g1nt = {
      active = false,
    },
  },
},
```

- A node file holds another as an instance: a node with `instance`, the other file's path, and an `id` of its own. Any node file can be held so, as any can be loaded as the root (5).
- The instance is the other file's node with the instance's entry laid over it: what the entry writes replaces the node's, and what it leaves out is the node's.

  | In the instance's entry                                            | Is laid over                                                                             |
  | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
  | `name`, `posX`, `posY`, `rot`, `sclX`, `sclY`, `z` and `active`    | The same field of the file's node.                                                       |
  | `components`                                                       | The node's components, name by name: each value that the entry writes replaces that property's. |
  | `children`                                                         | Nothing: they are nodes of the instance's own, added after the children of the file's node. |
  | `overrides`                                                        | The nodes under the file's node. Each field is the id of one of them, in its file, and holds an entry that is laid over that node as this table says. |

- In the sample, the entry's own fields change the coin itself: its name, its place and its worth. `g1nt` is the id of the coin's glint, a node under the coin, so `overrides` turns that one node off.
- A value replaces a property whole. A group is the exception (6.2): it is laid over field by field.
- An instance changes values, and adds children. It adds no component, and removes nothing: what a node is made of is said in one place, its own file. A component in the entry that the file's node does not have is kept in the entry (4.2) and not used.
- A node under an instance may be an instance too. The outer instance reaches into it through the `overrides` of an entry in its own `overrides`. A node file cannot hold itself, directly or through another.
- An id is read in the file that writes it:
  - A property that names a node holds an id of its own file. In a file that is held, it gives each instance's own node.
  - A node inside an instance is named by a path: the instance's id, a slash, and the node's id in its own file, such as `t1r6/g1nt`.
- A change to a node file reaches every instance of it, apart from what the instance's entry writes.
- An instance's nodes are nodes of the tree as the others are: `onlr.node.find` and `onlr.node.findComponent` look through them too.
- `onlr.node.spawn` makes an instance while the game runs, and calls `load` and `enable` of its components before it returns (6.4).

## 10. The engine's components

The engine has four component types. They are written as scripts are, with the functions of section 7 and LÖVE alone.

| Type          | Is                                                                                                  |
| ------------- | --------------------------------------------------------------------------------------------------- |
| `onlr.sprite` | An image, or a part of one.                                                                         |
| `onlr.text`   | A text in a font.                                                                                   |
| `onlr.shape`  | A rectangle, a circle, a line or a polygon, filled or as an outline.                                |
| `onlr.camera` | The view of the tree: its node's place is what the window's centre shows, turned and scaled as the node is. |

- The tree draws through its first camera that runs (6.4), in the tree's order. A tree without one draws as plain LÖVE does, with 0, 0 at the window's top left.

## 11. Libraries

### 11.1 Using a library

- A library is Lua code that its author wrote for LÖVE games. The engine does not know it, and it does not know the engine (2.1).
- A project keeps its libraries in `lib/`, where `require` looks (3.1), so a script loads a library by the name its author gives:

  ``` lua
  local bump = require("bump")
  ```

- `require("bump")` finds `lib/bump.lua` or `lib/bump/init.lua`. A library that the user copies in works the same way, with or without a pack.
- The file's name is what `require` looks for. A library whose repository is a folder with its file inside, such as `bump.lua/bump.lua`, is copied so that the file is `lib/bump.lua`.
- A script calls the library as the library's own documentation says. ONLR puts nothing between them and renames nothing.

### 11.2 Packs

A pack is a folder in `lib/`, named as the library is loaded.

| In `lib/bump/`          | Is                                                              | Read by                                   |
| ----------------------- | --------------------------------------------------------------- | ----------------------------------------- |
| `manifest.lua`          | The manifest, which describes the pack (4.1).                   | The editor. The game never loads it.      |
| `init.lua`              | Code: one line that returns the library.                        | The game, at `require("bump")`.           |
| `library/`              | The library's own files, unchanged, with its licence.           | The game, through `init.lua`.             |
| `world.lua`, `body.lua` | Component types, one in each file: `bump.world` and `bump.body`. | The game, when a node file names the type. |

``` lua
---@type onlr.Pack
return {
  format = 1,
  name = "bump",
  description = "Collision of boxes",
  version = "3.1.7",
  source = "https://github.com/kikito/bump.lua",
  license = "MIT",
  components = {
    "world",
    "body",
  },
}
```

- The manifest and `init.lua` stay two files. The editor reads the manifest as any data file (4.1), which cannot load the library. So the manifest describes the pack and holds none of its code.
- `library/` holds what the library's author ships. A newer version of the library replaces that folder and nothing else.
- A component type is one file, since its name is its file's (6.1). The names start with the pack's: `bump.body` is `lib/bump/body.lua`. The types are written as scripts are (6).
- `components` names the types that the editor offers (13), by their files' names: inside the pack, its own name is not repeated. A node file and a script name a type in full, as `bump.body`, since they are read outside the pack.
- A pack adds nothing to the engine and changes nothing in it. A game uses a pack's library with its components, without them, or both.
- The editor copies a pack into a project when the user adds it, and deletes its folder when the user removes it. In the project, the pack is the project's own copy, and an export holds it.

### 11.3 A pack's components

A pack's components show a library in the inspector. The sample is a pack for bump, a library that keeps boxes in a world of its own and tells which ones a moving box hits. bump's world is not the tree: it is bump's own list of boxes, and it knows nothing of nodes.

``` lua
-- lib/bump/body.lua: a box that collides
local onlr = require("onlr")

---@class bump.body : onlr.Component
local Body = {}

Body.width = onlr.property.number(32)
Body.height = onlr.property.number(32)

function Body:load()
  local world = onlr.node.findComponent("bump.world") or onlr.node.root:add("bump.world")
  self.world = world:get()
end

function Body:enable()
  self.x, self.y = self.node:toWorld(0, 0)
  self.world:add(self, self.x, self.y, self.width, self.height)
end

function Body:disable()
  self.world:remove(self)
end

function Body:move(x, y)
  local hits
  self.x, self.y, hits = self.world:move(self, x, y)
  self.node:setWorldPosition(self.x, self.y)
  for _, hit in ipairs(hits) do
    self.node:send("contact", hit.other.node, hit.normal.x, hit.normal.y)
    hit.other.node:send("contact", self.node, -hit.normal.x, -hit.normal.y)
  end
end

function Body:update()
  local x, y = self.node:toWorld(0, 0)
  if x ~= self.x or y ~= self.y then
    self.x, self.y = x, y
    self.world:update(self, x, y)
  end
end

function Body:bounds()
  return 0, 0, self.width, self.height
end

function Body:drawEditor()
  love.graphics.rectangle("line", 0, 0, self.width, self.height)
end

return Body
```

``` lua
-- lib/bump/world.lua: the tree's one world
local onlr = require("onlr")
local bump = require("bump")

---@class bump.world : onlr.Component
local World = {}

World.cellSize = onlr.property.number(64)

function World:get()
  self.world = self.world or bump.newWorld(self.cellSize)
  return self.world
end

return World
```

``` lua
-- components/player.lua: the user's script, which needs a bump.body on its node
---@class player : onlr.Component
local Player = {}

Player.needs = { "bump.body" }

function Player:load()
  self.body = self.node.components.bump.body
end

function Player:update(dt)
  local x, y = self.node:toWorld(0, 0)
  if love.keyboard.isDown("right") then
    x = x + 200 * dt
  end
  self.body:move(x, y)
end

function Player:contact(other)
  print("hit " .. other.name)
end

return Player
```

What the sample shows of every pack:

- **What the tree has one of** is a component of the root (5): here `bump.world`. It is made with the root and ends with it, so each root has its own, and its node file keeps its settings. It is not a module that lives through the whole game. A component that needs it finds it with `onlr.node.findComponent`, and adds it to the root when the tree has none.
- **What the library must be told** is told by the component, in its `enable` and `disable` (6.4). bump asks for each box to be added to its world; the body does that while it runs, so the user does not, and a node that is turned off collides with nothing.
- **Where a node is** has one truth: the node's own place (5). A library that keeps a place of its own, as bump does for each box, holds a copy, and the pack's component keeps the copy in step. After `move`, the node takes the library's answer. When a script sets the node's place itself, the component tells the library, in its `update`.
- **What a script asks of the library** is a function of the component: `body:move(x, y)`. The script names the body in `needs` (6.6), so its node always has one.
- **What the library reports** reaches scripts with `node:send`, as a function that the script defines: `contact(other)`. Both nodes of a contact are told.
- **What the editor shows** is `bounds`, for choosing the node, and `drawEditor`, for the outline.

## 12. The player and the link

### 12.1 The player

- The editor starts LÖVE itself, unchanged, as a program of its own on the project's folder. Arguments tell the engine that the editor started it, the mode, where the editor listens, and where the player's files are.
- The player's files are the Lua code that serves the editor: the link and the views. They are in ONLR's own folder, and no project holds them. The engine loads them with Lua's own `loadfile`, which reads any path, where LÖVE's file functions read only the game's folder (3.1). So a project and its exports hold nothing of the editor, and both ends of the link are of one version of ONLR.
- A player runs in one of two modes:

  | Mode | Runs                                        | Draws into                                     |
  | ---- | ------------------------------------------- | ---------------------------------------------- |
  | Edit | Views: node files drawn and not updated (12.3). | Frames for the node view and previews (12.4). |
  | Play | The game.                                   | LÖVE's own window.                             |

- The edit player runs while a project is open, and has no window. On Linux the editor starts it with SDL's offscreen video driver, `SDL_VIDEODRIVER=offscreen`, so it opens no window and still draws with the graphics card.
- Play saves the project (13), then starts a second player with the open node file as its root, or with the manifest's start node when none is open. Stop ends it, and so does closing its window.
- The play player is LÖVE as an exported game runs it: the window, the keyboard, the pointer, the gamepads and the sound are LÖVE's own, and the engine stands in for nothing.
- What a mode draws into is the one difference between the modes. Starting a player, the link, the console and the errors are the same code for both, so the editor's other parts do not know where the game is drawn.
- A player is another program, so a game that fails or never returns leaves the editor running. The editor shows what happened, and starts the player again when asked.
- The editor reads what a player prints, and shows it in the console. In a player, the engine turns off the buffer of the game's output, so each line shows when it is printed.

### 12.2 The link

- The link is a TCP connection on this computer: the editor listens on a free port of `127.0.0.1`, and the engine connects to it with LuaSocket, which LÖVE ships. Each player has a link of its own.
- A message is a Lua table written as text, and may carry a block of bytes after it, such as a frame's pixels. Each message starts with the sizes of both.

| The editor sends | To              | For                                                                                                                |
| ---------------- | --------------- | ------------------------------------------------------------------------------------------------------------------ |
| A file           | The edit player | A node file as the editor holds it, saved or not. The edit player reads it in place of the project's file.         |
| A change         | The edit player | One edit of such a file, such as a moved node or a new value.                                                    |
| A view           | The edit player | Which node file to draw, from where, and at what size (12.3).                                                        |
| Shown            | The edit player | The editor has shown the last frame (12.4).                                                                        |
| A question       | The edit player | What a component type declares (12.5).                                                                             |
| Reload           | The edit player | A file of the project changed.                                                                                     |
| Stop             | The play player | The game ends.                                                                                                     |

| The engine sends | From            | For                                                            |
| ---------------- | --------------- | -------------------------------------------------------------- |
| A frame          | The edit player | The picture of a view, and the nodes' bounds with it (12.3). |
| An answer        | The edit player | A type's properties, or why its file does not load (12.5).     |
| An error         | Both players    | A message with its file, line and stack.                       |

### 12.3 Views

- The edit player only draws, and what it draws are views.
- The node view is a view of the open node file, and a preview of a node file is a view of it. A preview of anything else is a view of a node that the editor makes up, such as one with one sprite. So a preview of an image, a font or a component needs no drawing code of its own, in the editor or in the engine.
- The edit player draws a view when the editor asks: after a change, or when the view moves. It runs no loop of frames, so it uses the processor only when something changed.
- What is drawn is split by what it depends on:

  | Drawn by                    | What                                                                  | Because                                                       |
  | --------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------- |
  | The edit player, in LÖVE    | Each component's `drawEditor` (6.5): its picture, and its own outlines. | It depends on the component, and its author writes LÖVE code. |
  | The panel, over the frame   | The grid, the outline of the chosen nodes, and their handles.        | It depends on the pointer and the tool, and is the same for every component. |

- With each frame of a view, the engine sends every node's `bounds` (6.3) as the view shows them. The panel draws its part from them and finds the node under the pointer from them. So its outlines never part from the picture, and a click needs no answer from the player.
- A node without `bounds` covers no rectangle, such as one whose only component is a script. The panel draws a small marker at its place, so it can be seen and chosen.

### 12.4 Frames

- The engine draws a view into a canvas of the view's size, reads the canvas back, and sends its pixels.
- The engine sends a frame only when the editor has shown the last one, so a slow panel never fills the link.

### 12.5 What the editor learns from LÖVE

- The editor never loads a script. To show a type's properties, it asks the edit player, which loads the file as the game would and answers with the type's properties (6.2): their names, kinds, defaults and options, in their order. It answers with the types that the type needs too (6.6).
- When a script changes on disk, the edit player loads it again, and the editor asks again.

## 13. The editor

- The editor is an OpenECS tool: a preset and plugins, in Lua unless a part needs C. The user never sees or writes them.
- It builds on OpenECS's standard plugins (OpenECS-std DESIGN): process starts the players, net carries the link, fs watches the project, compress and hash serve export, web downloads LÖVE, and ui and draw make the panels.

| Plugin         | Does                                                                                          |
| -------------- | --------------------------------------------------------------------------------------------- |
| `onlr_project` | Holds the open project: its manifest, its node files, the chosen nodes and the history. It reads and writes the files, and watches the folder. |
| `onlr_player`  | Starts the players and speaks the link. It gives the node view, and the functions Play and Stop. |
| `onlr_views`   | The other panels of OVERVIEW 7.                                                               |
| `onlr_export`  | Export (14), and LÖVE's packages (15).                                                        |

- The inspector shows the chosen node's place, then each of its components under its type's name. A component has one row for each property: the property's name, and the control of its kind (6.2).
- The types that adding a component offers come from three places: the engine's manifest (8.3), the manifests of the project's packs (11.2), and the Lua files of `components/` (3.1).
- The nodes panel shows the open node file's tree, from its first node.
- The project's data lives in `onlr_project`, not in a panel (OpenECS OVERVIEW 9.2). Panels show it, change it through its functions, and hear of changes through its events. So two panels never differ.
- Each change of a node file is a record that can be undone. `onlr_project` keeps them in one history for the project.
- A node file with changes marks its panel as unsaved, so OpenECS asks before it closes (OpenECS OVERVIEW 5.5).
- Play saves every node file with changes, and the manifest, before it starts the play player (12.1). So the game that plays is the project's files, and the play player is sent none.
- A file of the project that changes on disk is read again. When the editor's copy has unsaved changes too, the editor asks which to keep.
- Opening a file at a line in the user's code editor runs a command that is a setting.

## 14. Export

### 14.1 The `.love` file

- A `.love` file is a zip archive of the project's folder, with `main.lua` at its root.
- It leaves out every file and folder whose name starts with a dot, such as `.onlr/` and `.luarc.json`, and what `exclude` in the project's manifest names.
- The licences travel with their parts: the engine's is in `lib/onlr/`, and a library's is in the library's folder.

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

- ONLR's archive holds the package of the editor's own platform, which the players run. On Linux it is the contents of LÖVE's AppImage, unpacked, so it runs without the system's AppImage support.
- The package of another platform is downloaded from LÖVE's releases at the first export for it. The editor checks it against SHA-256 hashes that ONLR ships, and keeps it in the user's data folder, by version and platform.
- A setting names a folder to use as a package instead, such as a LÖVE the user built.

## 16. Tests

- The samples are the tests. A sample is a small project that shows one part of ONLR, and it has one test.
- A sample's test of the engine runs the sample in LÖVE with the offscreen driver; the sample checks itself and ends with a status.
- A sample's test of the editor is an OpenECS test (OpenECS DESIGN 17.5): it opens the sample, acts as a user would, and checks the files that the editor writes.
- A change that breaks a sample changes the sample in the same piece of work.

## 17. Versions and branches

- The engine uses semantic versioning. Its manifest names its version (8.3).
- A file's `format` is a number that changes when an older engine or editor cannot read the newer file (4.1).
- `dev` is the default branch, where work is merged. `main` holds what is stable: it changes only through a pull request from `dev`, which the owner merges.

## Glossary

**AppImage.** A way to ship a Linux program as one file. LÖVE's Linux release is one.

**Canvas.** A picture in the graphics card's memory that LÖVE draws into instead of the window.

**Component type.** A Lua file that returns a table with a component's properties and functions.

**Definition.** A LuaLS annotation that tells a code editor a type's fields or a function's parameters.

**Edit player.** The player that draws views for the editor.

**Entry.** The table that a node file holds for one node or one component.

**Frame.** One picture that LÖVE draws: of the game, or of a view.

**Library.** Lua code that its author wrote for LÖVE games to use.

**Link.** The connection between the editor and a player.

**LuaJIT.** The implementation of Lua that LÖVE runs. Its language is Lua 5.1 with additions.

**LuaLS.** The Lua language server, which completes and checks Lua code in code editors.

**LuaSocket.** A Lua library for network connections, which LÖVE ships.

**Metatable.** A table that tells Lua where to look when another table lacks a field.

**Offscreen driver.** A video driver of SDL that opens no window.

**Pack.** A library made ready for ONLR, with component types that show it in the inspector.

**Package.** LÖVE for one version and one platform, as files in a folder.

**Play player.** The player that runs the game when the user plays it.

**Player.** LÖVE, started by the editor on the project.

**Plugin.** A module that gives OpenECS panels and functions.

**Preset.** The file that tells OpenECS which plugins and panels a tool starts with.

**Root.** The node that the game runs, with the tree's other nodes under it.

**SDL.** The library through which LÖVE and OpenECS use windows, input and graphics.

**Transform.** LÖVE's object for a position, a rotation and a scale together.

**Tree.** The nodes that the game runs: the root and all that is under it.

**View.** A node file as the edit player draws it: seen from a point, at a zoom and a size.
