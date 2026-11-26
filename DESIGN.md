# ONLR Technical Design

This document explains how ONLR is built: its parts, the project's files, the engine, the link between editor and game, and export. Read [OVERVIEW.md](OVERVIEW.md) first; this document uses its words and does not repeat it.

**How to read it:**

- Everything here is decided. Open questions and pending work are in [TODO.md](TODO.md).
- Code samples are only illustrations of a file or an interface.
- Samples that need a library use bump, a library for collision. It stands for any library: this document chooses none.
- Technical terms are explained in the glossary at the end.
- "OpenECS DESIGN" names [OpenECS's DESIGN.md](https://github.com/omerfuyar/OpenECS/blob/dev/DESIGN.md), and "OpenECS-std DESIGN" [OpenECS-std's](https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md). OpenECS changes often, so this document links to them and repeats nothing of theirs. Only the editor depends on OpenECS: section 13, and what sections 1, 2.2, 12.4 and 16 say of the editor.

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
12. The runner and the link
13. The editor
14. Export
15. LÖVE
16. Tests
17. Versions and releases

- Glossary

---

## 1. Conventions

- The engine is Lua for LuaJIT, which LÖVE runs: Lua 5.1 with LuaJIT's additions. It uses no library but LÖVE.
- The editor's plugins follow OpenECS's conventions (OpenECS DESIGN 1, OpenECS-std DESIGN 1.3).
- Lua names use camelCase: `onlr.tree.loadRoot`, `startNode`. Files and folders have lowercase names.
- A node's place has short names, since scripts write them most: `posX`, `posY`, `rot`, `sclX` and `sclY`.
- Functions of one kind share a namespace, such as `onlr.tree`. What acts on a node or a component is its method.
- The engine sets no global. A script gets it with `local onlr = require("onlr")`.
- Every public function, type and file format of the engine has LuaLS annotations in the engine's source. They are the definitions that guide a code editor (4.3), so the source and the hints cannot differ.
- A path in a project uses `/` and starts at the project's folder, as LÖVE's paths do: `images/player.png`.
- Angles are radians, colours are tables of red, green, blue and alpha from 0 to 1, and y grows down, as in LÖVE. The inspector shows and takes angles in degrees (6.2, 13.4), and the node files and scripts keep radians.

## 2. Parts

### 2.1 Layers

A game made with ONLR is built in layers. Each uses only the layers above it in this table:

| Layer              | Is                                                                                              | Written by                      | Uses                           |
| ------------------ | ----------------------------------------------------------------------------------------------- | ------------------------------- | ------------------------------ |
| 1. LÖVE            | The runtime: the window, drawing, sound, input, physics and files.                              | LÖVE's authors                  |                                |
| 2. Libraries       | Lua code for LÖVE games, such as a library for collision (11).                                  | Their authors                   | LÖVE, or nothing               |
| 3. The engine      | Nodes, components, properties and the loop (5 to 9).                                            | ONLR                            | LÖVE                           |
| 4. Components      | What nodes show and do: the engine's own (10), a package's (11.2), and the user's scripts (6) and graphs (6.8). | ONLR, a package's author, the user | The engine, LÖVE and libraries |
| 5. The game's data | The project's manifest and node files, which name component types and hold their values (3, 4). | The user, through the editor    | Component types, by name       |

- The engine and the libraries do not know each other. A component is where they meet: it is called by the engine, and it calls a library.
- All three kinds of component are the same thing to the engine. The engine's own and a package's can do nothing that a script cannot.
- The editor is not a layer of the game. It is another program: it reads and writes the game's data, and asks the runner (12) what the components declare and how the nodes look.

### 2.2 In this repository

| Part           | In this repository       | Is                                                                                                              | Runs in |
| -------------- | ------------------------ | --------------------------------------------------------------------------------------------------------------- | ------- |
| Engine         | `packages/onlr/`         | The Lua library that every project holds a copy of, as `packages/onlr/` (8.3).                                  | LÖVE    |
| Packages       | `packages/`              | The packages that ONLR ships, each in a folder of its own beside the engine, such as `packages/bump/` (11.2).   | LÖVE    |
| Editor         | `plugins/`, `preset.lua` | OpenECS plugins and their preset (13).                                                                          | OpenECS |
| Runner's files | `plugins/onlr/runner/`   | The Lua code that the engine loads when the editor starts it: the link and the views (12). No project holds it. | LÖVE    |
| Samples        | `samples/`               | Small projects, which are the tests (16).                                                                       | Both    |

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
  ira-scripts/              the ira-scripts: graphs that are component types (6.8)
    door.lua                  the type door
  ira-shaders/              the ira-shaders: graphs that are shaders (6.8)
    water.lua
  shared/                   the user's Lua code that components share
    score.lua
  packages/                 the engine, packages and libraries
    onlr/                     the engine
    bump/                     a package
  nodes/                    the node files
    level.lua
    coin.lua
  images/                   assets, in any folders of any name
    player.png
  .onlr/                    the editor's own files for this project
  .gitignore                keeps .onlr/ out of git
  .luarc.json               tells a code editor where the definitions are
```

- LÖVE's file functions and its `require` read a game's files only from the game's own folder. So the engine and the files that start it are in the project, and `love mygame` runs it.
- The editor writes `main.lua` and `conf.lua` once, when it makes the project. They are the user's afterwards:

  ``` lua
  -- main.lua
  -- Code outside functions runs in the editor too, when it draws the node view.
  -- The game's own start goes in love.load.
  require("packages.onlr").start()
  ```

  ``` lua
  -- conf.lua
  function love.conf(t)
    require("packages.onlr").conf(t)
  end
  ```

- `onlr.conf` gives LÖVE the settings that the project's manifest holds (3.2). So LÖVE's settings are changed in the manifest, by the project settings panel or by hand, and neither the user nor the editor changes `conf.lua`.
- Both files load the engine as `packages.onlr`, which LÖVE finds in the project's folder as it is. When the engine loads, it adds `packages/` to the places where `require` looks, and answers to the name `onlr` too. LÖVE reads `conf.lua` before any other file of the game, so from then on a script writes `require("onlr")`, and a library is loaded by the name its author gives (11.1).
- `components/` holds the scripts. The editor offers them when the user adds a component, and makes new scripts there. Inside it:
  - A Lua file is a component type: `components/coin.lua` is `coin`.
  - A folder with an `init.lua` is one component type, and the other files in it are that component's own modules, which the editor does not offer: `components/player/init.lua` is `player`, and it loads `components.player.states` with `require`.
  - A folder without an `init.lua` only groups what is in it: `components/enemies/bat.lua` is `enemies.bat`.
  - A file and a folder of one name cannot be side by side, such as `enemies.lua` and `enemies/`, since the name would be a type and a group at once (6.1). The editor says so, and the engine refuses both.
- `nodes/` holds the node files (5). Every Lua file in it, in any folder of it, is one: `nodes/level.lua`.
- `ira-scripts/` holds the ira-scripts, each a component type named by its path, as a script is in `components/`: `ira-scripts/door.lua` is `door` (6.8). `ira-shaders/` holds the ira-shaders, each a Lua file. A GLSL file is in any folder, as an image is (6.7).
- `shared/` holds the user's Lua code that is not a component and that components share: what keeps a value when the root changes, such as a score, and functions that many scripts use. The engine does not read it: scripts load it with `require`, as in any LÖVE game. Its name is not taken; a new project has it.
- `packages/` holds what the game uses and was not made for this game alone, each in a folder of its own: the engine in `packages/onlr/`, packages, and libraries. The user adds to it, by hand or in the editor.
- `packages/onlr/` is the engine's. The editor replaces it when it updates the engine (3.3), so the user does not edit it. Each project holds its own copy, so `love mygame` runs it and an export holds it.
- `.onlr/` holds what the editor keeps for this project on this computer, such as LÖVE's definitions (4.3). It is not exported, and not in git: when the editor makes the project, it writes a `.gitignore` that names it.
- The names `main.lua`, `conf.lua`, `manifest.lua`, `components/`, `ira-scripts/`, `nodes/`, `packages/`, `ira-shaders/` and `.onlr/` are taken. Every other name is the user's.

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
  topNode = "nodes/game.lua",
  window = {
    height = 1080,
    width = 1920,
  },
  defaultFilter = "nearest",
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
| `topNode`         | The node file of the top node, which the game loads once and keeps, and under which each root runs (5). An empty node when left out. |
| `window`          | The game's window, as LÖVE's `t.window`, with its names: `width` and `height` in pixels, and any other field of it, such as `resizable`, `fullscreen` or `highdpi`. The engine adds none of its own. LÖVE draws a game at its own pixels from the window's top left, so a window that the user makes larger, or a full screen, shows empty space around the game; a `push.screen` on the top node scales the game to the window (11.10), which the project settings set up in one click. |
| `modules`, `audio`, `console` and LÖVE's other settings | As in LÖVE's `t`, under LÖVE's names. LÖVE's `identity` is `id`, and its `version` is `loveVersion`. |
| `defaultFilter`   | How images are scaled, as `love.graphics.setDefaultFilter` takes it: `linear`, LÖVE's default, or `nearest`, which keeps pixel art sharp. The engine sets it in both players, before anything loads (12.1). With `linear`, an image that is scaled by a number that is not whole, or drawn between two pixels, blends its neighbouring pixels, which blurs small pictures; a game of pixel art names `nearest`. A new project names `nearest` (13.2), since a game of small pictures is the common case for LÖVE, and pixel art blurred by `linear` looks broken, while a large image scaled down with `nearest` only looks rough; a game of large or smooth pictures sets `linear` in the project settings. |
| `fixedRate`       | How many times a second `fixedUpdate` is called (6.3). 60 when left out.        |
| `exclude`         | Patterns of files that an export leaves out. A pattern names a path from the project's folder, part by part: in a part, `*` stands for any part of a name; a part `**` stands for any folders, or none, so `**/notes.txt` names `notes.txt` in every folder; and a pattern that ends with `/` names a folder, with all that it holds. |

- LÖVE's settings are here, and not in `conf.lua`, since two things need them: LÖVE, before it opens the window, and the project settings panel, to show and change them. The editor does not run `conf.lua`, which is the game's code.

### 3.3 Updating the engine

- The editor ships one version of the engine, and works on a project that holds that version. The engine's manifest in `packages/onlr/` names its version (8.3).
- When the editor opens a project that holds another version, or no engine, it asks the user, then replaces `packages/onlr/`. If the user declines, the project stays closed.

## 4. Data files

### 4.1 Rules

- Every data file that ONLR writes is a Lua file that returns one table: the manifests, the node files and the graphs (6.8).
- The table is plain data: numbers, texts, booleans and tables, and no function.
- The engine and the editor read a file in one way, by running it with the engine's `library/data.lua`, with LuaJIT: LÖVE's in the game, and OpenECS's in the editor, which loads that file from ONLR's own engine (13.1). The file runs with Lua's basic functions and its `string`, `table` and `math` libraries, and nothing else. It cannot reach LÖVE, the engine, the editor or another file.
- The basic functions are those that compute: `assert`, `error`, `getmetatable`, `ipairs`, `next`, `pairs`, `pcall`, `rawequal`, `rawget`, `rawset`, `select`, `setmetatable`, `tonumber`, `tostring`, `type`, `unpack` and `xpcall`. Those that load code or reach outside are left out, such as `require`, `load`, `dofile` and `print`. Each file gets its own copies of the three libraries, so it changes nothing for another file. `getmetatable` gives nothing for a text, since every text shares one metatable, whose `__index` is the real `string` of the game or the editor.
- So a file that a person writes may compute its table, such as a manifest that works out the window's size. Its code must be LuaJIT 2.1's Lua without the syntax that OpenECS's LuaJIT takes from LuaJIT 3.0, such as `+=`, which LÖVE 11.5's lacks.
- A file's kind is known by its folder, without reading it: a node file is in `nodes/`, a script in `components/`, an ira-script in `ira-scripts/` and an ira-shader in `ira-shaders/` (3.1). No file's name has a second ending.
- Each file has a `format` number. The engine and the editor read only the one that they know, and say so of another (17).

### 4.2 How the editor writes them

- A node file is the editor's to read and to write, and its format is made for that. A node is named by its id and a component by its type's name, so each change names what it changes, wherever that has moved since.
- The editor writes data only: the table's values. A save writes the whole file again, so code and comments that a person wrote in it are not kept.
- So the editor asks before it replaces such a file. It knows one when it reads it: the file's text differs from what the editor would write for the same table. The ends of lines are not compared, so a file whose line ends git changed on Windows is not taken for one that a person wrote.
- A file is written beside the old one and then renamed over it, so it is never left half-written.
- A file is written in one way only, so the same table always gives the same text, and changes to different nodes, or to fields on lines apart, merge in git:
  - One field on each line, indented by two spaces, and each item of a list on its own line. Lines end with LF.
  - A node's fields in the order of section 5's table, after `format`, and so are the fields of an instance's change (9). A manifest's fields are in the order of section 3.2's table, with LÖVE's other settings in the order of their names. The fields of every other table, such as a node's components and a component's values, are in the order of their names.
  - A key that is a name in Lua is written as it is, and any other in brackets. The keys of an instance's `changes` are paths of ids (9), and are always in brackets: `["c0in7x"] = {` and `["ch3st9/g1nt4k"] = {`.
  - A whole number from -2^53 to 2^53 without a point, such as `250`. Any other number with the fewest digits that read back as the same number, such as `0.1`, and an endless one as `math.huge`, and one that is no number as `0/0`. So the game and the editor read the same value.
  - A text in double quotes, with `\\`, `\"` and `\n`, and every other byte below 32 as three digits, such as `\009`. So the game and the editor read the same text.
- A value that equals its default is left out, so a file holds only what the user set. In an instance, the value in its base is the default (9).
- A node's `id` is six random characters, lowercase letters and digits, such as `c0in7x`. The editor gives it once. Nodes are named by id wherever one refers to another, never by their place in a list.
- An id is unique in its file, and no further. When a file holds an id twice, such as after a merge in git, the editor gives one of the two nodes a new id, and says so.
- Two changes on neighbouring lines, such as a node's `name` and its `posX`, and two nodes added at the end of one list of children conflict in git, as in any text. A node file with git's marks of a conflict does not load: the node view shows the error, and the user resolves it in a text editor.
- A field or a component type that the editor does not know is kept as it is, and written back. A node's field that section 5 does not name is written after those it names, in the order of the names.
- LuaJIT cannot read a node file of much more than 30,000 nodes. The editor warns well before a file gets there. A tile map is one component, not a node for each tile.

### 4.3 Definitions

- The first line of each file names its type, such as `---@type onlr.NodeFile`, so a code editor with the Lua language server completes and checks its fields.
- The types are in the engine's source, in the project's `packages/onlr/` (1). LÖVE's own definitions, from [LuaCATS/love2d](https://github.com/LuaCATS/love2d), are a submodule of ONLR's repository, in `dependencies/love2d/`. The editor copies them into `.onlr/love2d/` when it makes a project, and when it opens one whose `.onlr/` lacks them, as a cloned project's does, since git ignores `.onlr/`. So a code editor completes and checks LÖVE's functions in a project's scripts.
- The editor writes `.luarc.json` once, when it makes the project. It names LuaJIT as the Lua version, `.onlr/` as a library, and `packages/` as a place where `require` looks (11.1). It turns off the warning of a file that is loaded by two names, since `conf.lua` and `main.lua` load the engine as `packages.onlr` and scripts as `onlr` (3.1):

  ``` json
  {
    "runtime.version": "LuaJIT",
    "runtime.path": ["?.lua", "?/init.lua", "packages/?.lua", "packages/?/init.lua"],
    "workspace.library": [".onlr"],
    "diagnostics.disable": ["different-requires"]
  }
  ```

- A script names its type with an annotation, under the type's name: `---@class player : onlr.Component`.
- The editor writes a definition of `node.components` (6.1) into `.onlr/components.lua`, with a field for each component type of the project, and writes it again when a type is added or removed. So a code editor knows what `self.node.components.player` is.

## 5. Nodes

``` lua
-- nodes/level.lua
---@type onlr.NodeFile
return {
  format = 1,
  id = "l3v1q0",
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
      id = "k3f9pl",
      name = "Player",
      posX = 100,
      posY = 500,
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
          id = "p7c2sh",
          name = "Shadow",
          posY = 44,
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
| `instance`         | In an instance, its base and its changes (9). Such a node has `id` and `instance`, and no other field. | |
| `name`             | Its name. Names need not be unique.                                           |         |
| `posX`, `posY`     | Its position in its parent, in pixels.                                        | 0       |
| `rot`              | Its angle in its parent, clockwise.                                           | 0       |
| `sclX`, `sclY`     | Its scale in its parent.                                                      | 1       |
| `z`                | Its order in drawing, added to its parent's.                                  | 0       |
| `active`           | Whether it and its children update, draw and get events.                      | true    |
| `componentOrder`   | The order of its components: the names of their types. Types that it does not name come after those it names, in the order of their names. Left out, the order is the names'. | |
| `components`       | Its components, by their types' names (6.1). Each is a table of its properties' values, and of `enabled`, which is true when left out. | |
| `children`         | Its children, nodes too.                                                      |         |

- The game runs one root at a time: a node, with all that is under it, which `onlr.tree.root` gives. The game starts with the manifest's start node (3.2), and `onlr.tree.loadRoot` puts another in its place (7). A level and a coin are node files alike: the game loads the level as its root, and the level holds the coin as an instance (9).
- Above the root is the top node: the node of the node file that the manifest names (3.2), which the game loads once, before the first root, and keeps for the whole game. What outlives the root is under it, such as a music player or a pause menu, and the root runs as its last child. When the manifest names none, the top node is an empty node. While the top node loads, there is no root yet: `onlr.tree.root` is `nil` until the first root loads. So `onlr.tree.spawn` and `onlr.tree.newNode` without a parent, called then, fail with an error that says the root is not loaded yet: a script of the top node gives them `onlr.tree.top`, or a node of its own, as the parent.
- The top node, with all under it, is the tree. So the tree has one top, and a group on the top node holds the whole game, such as a library that scales the game to the window.
- A script keeps a node of the root when the root changes by moving it under the top node, or under a node of the top node's own (7). Moved there without an index, it goes before the root, so it updates before the root, and draws before it at the same `z`, as the top node's other nodes do. So does a node that `onlr.tree.spawn` or `onlr.tree.newNode` puts under the top node.
- What a root has one of, such as the world that its bodies collide in, is a component of the root. No node is made only to hold one.
- Nodes update, and get events, in the order of the tree: a parent, then its children, and siblings in the order of their list, so the top node's own nodes before the root. `z` plays no part in it. So what must update before every other node, such as what reads the input for the whole game, is a component of the top node.
- Nodes draw by `z`, the lowest first. A node's z is its own added to its parent's, so a child with a negative `z` draws behind its parent. Nodes of the same z draw in the order of the tree.
- The engine does not order by y. A game seen from above, which draws what is lower on the screen later, sets a node's `z` from its `posY` in a script, and the next draw follows it (6.4).
- A node can draw as a **group**, when one of its components has the function `drawTree(draw)` (6.3). Then the node and all under it draw together, at the node's place in the order of drawing, and by `z` among themselves. The engine calls `drawTree` in place of drawing them, and gives it `draw`, which draws them. So the component sets something up before they draw and ends it after: a camera's view (10), a canvas, a shader, or a library that works in the same way.
- Any node can be a group, at any depth, and a group can hold others. A group's nodes draw nowhere else, whatever their `z`: a child with a `z` of 100 draws over the rest of its group, not over what is outside it.
- `drawTree` may call `draw` more than once, such as once for each half of the window in a game for two players, or not at all. Each call draws the group's nodes once, so a group costs what drawing its nodes that many times costs, and one call costs no more than drawing them without a group.
- A node with two such components draws through both, the first in its components' order outermost.
- A node's components load, update and draw in the node's order, `componentOrder`, and each after those that it needs (6.6). The inspector shows them in that order, and moves them (13.4), so what the author sees from the top down is the order in which they run, as in Unity. The field stays out of the file until the user moves a component. A component added later, by the editor or by a script, goes where its name sorts among those that the list does not name. What must draw in another order than its node's other components is a child with a `z` of its own.
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
    onlr.tree.spawn("nodes/bullet.lua", self.node.posX, self.node.posY)
  end
end

return Player
```

- A type's name says where its file is:

  | Type                | Its name                                   | Its file                    |
  | ------------------- | ------------------------------------------ | --------------------------- |
  | A script            | Its path in `components/`: `player`, `enemies.bat`. | `components/player.lua` (3.1) |
  | An ira-script      | Its path in `ira-scripts/`: `door`.             | `ira-scripts/door.lua` (6.8)     |
  | A package's         | The package's name, then its path in the package's `components/`: `bump.body`. | `packages/bump/components/body.lua` (11.2) |
  | The engine's own    | `onlr.`, then its path in the engine's `components/`: `onlr.sprite`. | `packages/onlr/components/sprite.lua` (10) |

- The engine looks for a type in the project's `components/` and `ira-scripts/` first, then in the packages'. So a script or a graph cannot have the name of the engine or of a package, and a script and a graph cannot have one name: the editor says so, and the engine refuses both.
- Each part of a type's name is a name in Lua, since a script reads it so: `components.enemies.bat`. The editor makes no file or folder in `components/` whose name is not one, and the engine refuses such a type.
- A node has at most one component of a type. Giving it a second is an error.
- The engine loads a type's file with `require`, under the name that its path gives: `components.player`, or `packages.bump.components.body`. So a script that loads a type's file the same way gets the same table. A graph's type is built from its file instead (6.8).
- A node keeps its components in `components`, by their types' names. A dot in a name is a table in a table: `bump.body` is `components.bump.body`. A node file writes them so (5), and a script reads them so: `self.node.components.bump.body`.
- In the game, `components` holds a table for the engine's name, for each package's and for each folder of `components/`, also on a node that has none of their types. Such a table is empty and cannot be changed. Reading any other name from `components`, or from one of its tables, is an error. So `self.node.components.bump.body` is `nil` on a node without a body, and a misspelt name, such as `components.plyer` or `components.bmup.body`, is an error.
- Each component of a node is a table of its own, which finds its functions in its type. So `self` is the component, and what a function keeps in `self` belongs to that one node.
- `self.node` is the node. `self:setEnabled(false)` turns the component off, and `self:isEnabled()` says whether it is on (6.4). The engine gives every type these two functions.
- A type does not inherit another. What two types share is a module that both load (3.1), or a component of its own that both find on the node.

### 6.2 Properties

- A type declares a property as a field, with a function of `onlr.property`: `Player.speed = onlr.property.number(200)`.
- When the engine loads a type, it reads these declarations, then puts each property's default in the declaration's place. From then on `Player.speed` is 200, and a property without a default is `nil`.
- A component reads a property under the same name: `self.speed`. It holds the values that its node file gives, which the engine sets before `load`, and finds the others in its type. A default that is a table, such as a colour, is copied into each component, so changing one changes no other.
- A property is a plain field of the component, so another component reads and sets it the same way: `self.node.components.player.speed`, or another node's `other.components.coin.worth`.
- Each function takes the default value, then optionally a table of options (below). A default that is left out is false for `bool`, 0 for a number, an empty text for `string`, the first choice for `choice`, white for `color` and an empty list for `list`. A kind that names a file, a node or a component has no default and takes the options only. `component` takes the type's name first, `vector` its two numbers, `group` a table of properties, and `list` one property.
- Each declaration gets a number when its function is called. The inspector shows a type's properties by that number, which is the order its file declares them in.
- Each function's annotation names what the component gets, so a code editor knows that `self.speed` is a number.
- A property cannot be named `enabled`, `node` or `needs`, which a component or its type has (6.1, 6.6), or as a function of its type. Nor can it have the name of a function that the engine calls (6.3, 6.5), such as `update`, or of one of LÖVE's callbacks, every key of `love.handlers`, such as `focus` or `visible`: its default would stand where the engine looks for the function. The engine refuses such a type when it loads it, with an error that names the file and the property, and it calls only what is a function.

| Function of `onlr.property` | The inspector shows                               | The component gets                           |
| --------------------------- | ------------------------------------------------- | -------------------------------------------- |
| `bool`                      | A toggle.                                         | A boolean.                                   |
| `integer`, `number`         | A number field, kept in `min` and `max` if given, and a slider beside it when both are. | A number.              |
| `string`                    | A text field.                                     | A text.                                      |
| `choice`                    | One of its `choices`.                             | The chosen text.                             |
| `color`                     | A colour.                                         | A table that `love.graphics.setColor` takes. |
| `image`                     | An image file of the project.                     | A LÖVE image.                                |
| `sound`                     | A sound file of the project, and whether LÖVE streams it. | A LÖVE source of its own.            |
| `font`                      | A font file of the project and a size.            | A LÖVE font. Without a file, LÖVE's default font at that size. |
| `shader`                    | A shader of the project: a GLSL file or an ira-shader (6.7). | A LÖVE shader.                   |
| `file`                      | A file of the project, of the endings in `extensions` if given. | Its path.                      |
| `nodeFile`                  | A node file of the project.                       | Its path.                                    |
| `node`                      | A node of the same file.                          | The node.                                    |
| `component`                 | A node of the same file that has a component of the type. | That component.                      |
| `vector`                    | Two number fields in one row.                     | A table with `x` and `y`.                    |
| `group`                     | The properties it holds, under one heading.       | A table with a field for each.               |
| `list`                      | Rows of one kind, which the user adds and removes. | A list of what that kind gives.             |

- A kind is a value or a reference. A value is held in the node file as it is: `bool`, `integer`, `number`, `string`, `choice`, `color`, `vector`, `group` and `list`. A reference names something else of the project: `image`, `sound`, `font`, `shader`, `file`, `nodeFile`, `node` and `component`.
- `group` and `list` take other properties: `onlr.property.group({ width = onlr.property.number(32), height = onlr.property.number(32) })` is read as `self.box.width`, and `onlr.property.list(onlr.property.image())` as `self.frames[1]`.
- The options:

  | Option        | Taken by                  | Is                                                                                       |
  | ------------- | ------------------------- | ---------------------------------------------------------------------------------------- |
  | `description` | Every kind                | A text that the inspector shows with the property.                                       |
  | `label`       | Every kind                | What the inspector shows in place of the name (13.4).                                      |
  | `heading`     | Every kind                | A heading that the inspector shows above the property, to part a type's properties, such as Movement. |
  | `when`        | Every kind                | The values of other properties of the type that the property is shown with: `{ kind = "circle" }`, or one of a list, `{ kind = { "line", "polygon" } }`. The inspector hides it otherwise, so a component of one job with variants shows only what its chosen variant uses. The component has it all the same. A name that the type does not declare is an error when the type loads. |
  | `min`, `max`  | `integer`, `number`       | The least and the most value. The inspector keeps the value between them, and with both shows a slider; the engine does not check it. |
  | `choices`     | `choice`, which needs it  | The texts to choose from.                                                                |
  | `stream`      | `sound`                   | What the property starts with: LÖVE streams the file while it plays, as music needs, in place of decoding it whole when it loads. The user may change it for each component. |
  | `size`        | `font`                    | The size that the property starts with. 12, LÖVE's own, when left out.                    |
  | `extensions`  | `file`                    | The endings of the files that the inspector offers, such as `{ "json", "lua" }`. Every file when left out. |
  | `angle`       | `number`                  | `true`: the value is an angle in radians, or radians a second, which the inspector shows and takes in degrees, as it does a node's `rot` (13.4); the component and the node file have radians, as LÖVE's functions take them. A table in `when`'s form, `{ kind = "hinge" }`, makes it an angle only while those properties have those values, as a joint's `lower` is an angle for a hinge and a slide in pixels for a prismatic joint. Inside a `group` or a `list`, the table names the component's properties too. |
  | `handles`     | `vector`, `list` of `vector` | `true`: the node view's Shape tool drags the point, or each point of the list, in the node's space, and adds and removes a list's points (13.3), as a polygon's corners or a script's patrol path need. |
  | `preload`     | `nodeFile`                | The node file loads with the component's own, so a spawn of it waits for no file (below). |

- An option that the kind does not take, such as a misspelt one, is an error when the type loads.
- One job is one type (OVERVIEW 11), and its variants are a `choice` with `when` on the properties of each, as `onlr.shape`'s `kind` is (10) and a joint's is (11.4), not a type for each variant. A node holds one component of a type (5), so a node of two shapes holds the second on a child node.
- A node file keeps a colour as a list of four numbers, and a vector as a table of `x` and `y`. A value of another kind than its property's is an error, as a path that names no file is (below).
- A node file keeps a file as its path, and a font as a table of its `path` and its `size`. It keeps a sound as its path while it streams as the type says, and otherwise as a table of its `path` and `stream`, `{ path = "sounds/song.ogg", stream = true }`; a script gives either. It keeps a node, and a component, as the node's id, or as a path of ids when the node is inside an instance (9). When the file loads, the engine gives the component the node or the component itself.
- The engine loads each file once, and components that name the same file share it. A sound is the exception: each component gets its own source, so two can play at once. When a root replaces another, the engine keeps the files that the new root names too, and lets go of the others. It lets go of files at no other time: a file that a destroyed node named stays loaded until the root changes.
- A `nodeFile` property with `preload` loads that node file, and the files that it names, when its component's node file loads, as the files of its own properties load. The node files that their own such properties name load too. So `onlr.tree.spawn` of it reads nothing from disk. A node file without it loads when it is first spawned or loaded as the root.
- A value of a property that the type no longer declares is kept in the node file (4.2), and the component does not get it.
- A path that names no file is an error in the game, which names the node file, the node and the property. In the node view, the component gets `nil` and its node is marked, as for a `drawEditor` that fails (6.5), and the inspector marks the path.

### 6.3 Functions

The engine calls the functions that a type has. All are optional.

| Function             | The engine calls it                                                                                   |
| -------------------- | ----------------------------------------------------------------------------------------------------- |
| `load()`             | Once, when its node enters the tree. The properties are set, and every node that enters with it exists. The component makes here what it holds. |
| `enable()`           | When the component starts to run: after `load`, and each time it is turned on again.                 |
| `start()`            | Once, before the component's first `update`. Every `load` before it is done, so the component looks at others here. |
| Any callback of LÖVE | When LÖVE sends the event, with what LÖVE gives: `keypressed(key, scancode, isrepeat)`, `mousepressed(x, y, button)` and every other one. |
| `fixedUpdate(dt)`    | At a fixed rate, which the manifest names (3.2), with the same `dt` each time: before `update`, as many times in a frame as the time since the last one asks, and at most 8. What must behave the same at any frame rate, such as LÖVE's physics, steps here. |
| `update(dt)`         | Each frame, with the seconds since the last one.                                                      |
| `lateUpdate(dt)`     | Each frame, after every `update`. What follows another node, such as a camera, moves here.           |
| `draw()`             | Each frame, with the node's place applied, so drawing at 0, 0 draws at the node.                     |
| `drawTree(draw)`     | Each frame, in place of drawing its node and all under it, with a function that draws them (5).      |
| `disable()`          | When the component stops running: each time it is turned off, and before `destroy`.                  |
| `destroy()`          | Once, when its node is destroyed, or the root that it is in is replaced.                              |
| `bounds()`           | When the editor asks for the rectangle that the component covers, in the node's own space. The node view uses it to choose nodes (12.3). |
| `drawEditor(chosen)` | In the node view, in place of `draw`, with whether the component's node is chosen (6.5).              |
| `drawTreeEditor(draw)` | In the node view, in place of `drawTree` (6.5).                                                     |

- The engine passes on every event that LÖVE has, by its name, so it needs no list of them, and an event of a newer LÖVE reaches scripts too. So a type's function with the name of one of LÖVE's callbacks, such as `focus` or `resize`, is called for that event.
- A type may have more functions of its own, which other components call: `self.node.components.bump.body:move(x, y)`.
- Around each component's `draw`, the engine applies the node's place and takes it off again. It also sets back the shader that was set before the `draw`, when the `draw` changed it, so a script that sets a shader and forgets `love.graphics.setShader()` shades nothing drawn after it. It compares LÖVE's shader before and after, and sets it only when it differs, since setting a shader ends a batch of LÖVE's draws. It changes nothing else of LÖVE's drawing state, as plain LÖVE code expects to set its own colours. The engine's own components set back what they change, such as the colour. In the node view, all of the state is kept (6.5).

### 6.4 When functions are called

- A component's life is `load`, `enable`, `start`, then each frame its events, `fixedUpdate`, `update`, `lateUpdate` and `draw`, and at its end `disable` and `destroy`.
- A component runs while it is `enabled`, and its node and every node above that are `active`. Only a component that runs gets `start`, events, `fixedUpdate`, `update`, `lateUpdate`, `draw` and `drawTree`. A node whose `drawTree` does not run draws as a node without one.
- A script can pause a node with `node:setPaused` (7). Then the node and every node under it still draw, and their components get no `start`, events, `fixedUpdate`, `update` or `lateUpdate` until it is resumed. Pausing takes effect at once, and a resumed component gets its functions from the next frame on, as one that starts to run does. Pausing is not turning off: `enable` and `disable` are not called. So a pause menu under the top node pauses the root, and the level stays on the screen behind it. A node file does not hold it: every node starts unpaused.
- `load` and `destroy` are called once each, whatever the node and the component are set to. They make and free what the component holds.
- `enable` and `disable` are called each time the component starts and stops running, so every `enable` has its `disable`. What a component gives to others while it runs, such as a body's box in its world, is given in `enable` and taken back in `disable`.
- `start` is called once, before the component's first events and `update`: when the frame in which it started to run ends, or, in the top node and the first root, when both have loaded (8.1).
- In a frame, each function is called for the whole tree before the next one is (8.1). It goes through the tree in the tree's order, and through a node's components in theirs (5). `draw` goes in the order of drawing.
- What starts goes in the tree's order, and what ends goes in the reverse. When many components start at once, `load` and `enable` go parents first. When many end, `disable` and `destroy` go children first, and on one node a component goes before those that it needs. So a component finds what it needs from its `load` to its `destroy`.
- When the top node or a root loads, the engine makes all its nodes, then calls `load` of every component, then `enable` of every component that runs.
- What a script makes exists at once: an instance from `onlr.tree.spawn`, a node from `onlr.tree.newNode`, and a component from `node:addComponent` (7). `onlr.tree.find`, `onlr.tree.findComponent`, `node:getChildren()` and `components` give it, and its `load` and `enable` are called before the function that made it returns. Its `start` and its other functions are called from the next frame on. So a script sets values on what it made, and `start` finds them.
- `component:setEnabled` and `node:setActive` take effect at once, as making does. A component that stops running gets `disable` before the function returns, and from then on no call but `enable` or `destroy`. One that starts to run gets `enable` before the function returns, and `start` and its other functions from the next frame on. `node:setParent` does the same for the components that it starts or stops.
- A node whose `z` `node:setZ` changed, and a node that `node:setParent` moved, draw in their new order from the frame's next draw. The other functions follow the new order from the next frame on.
- `node:destroy()` marks the node and every node under it, and their `isDestroyed()` is true from then on. A destroyed branch goes whole: `node:setParent` takes no node out of it, and puts none into it. The top node and the root are not destroyed so: `onlr.tree.loadRoot` ends the root. They stay in the tree, and their functions are called, until the frame ends. Then the engine calls `disable` and `destroy` of their components and takes them out of the tree. A component that holds another node asks `isDestroyed()` before it uses it.
- `node:removeComponent(type)` does the same to one component: it stays, and its functions are called, until the frame ends. Then the engine calls its `disable` and `destroy` and takes it off the node, and the node can get a component of that type again.
- `onlr.tree.loadRoot` does the same to every node of the root when the frame ends, and their `isDestroyed()` is true from then on. Then it makes the new root in the old one's place among the top node's children. The top node and its own nodes stay.
- What a function returns is not used. `quit` is the exception: as in LÖVE, the game does not quit when `love.quit` or a component's `quit` returns true.

### 6.5 In the node view

- The node view shows nodes that do not run: no `load`, `update` or event reaches a component.
- There the engine calls `drawEditor` in place of `draw`. A type that looks the same in the editor as in the game says so: `Sprite.drawEditor = Sprite.draw`. The engine's own components do.
- `drawEditor` also draws what only the editor shows, such as the outline of a body or the frame of a camera. It is LÖVE code, written with the component by its author.
- There the engine does not call `drawTree`. It calls `drawTreeEditor(draw)` in its place, when the type has it, and otherwise draws the group's nodes as if there were no group. So a camera, which has none, does not move the view, and `onlr.shader`, which has one, shows its shader there (10).
- A type without `drawEditor` shows nothing in the node view. Its `draw` is not called there, since it may need what `load` or `update` sets.
- `loadEditor`, when a type has it, is called there once its node's components are made, in the order that they load (6.6), and again after each change of a value of the node's components. It sets up from the values what `drawEditor` or another component shows, as Unity's `OnValidate` does: anim8's sets its sprite's `quad` to the first frame (11.5). It is LÖVE code: the tree's functions change nothing there, as in `drawEditor`, one that fails marks its node, and one that never returns stops the preview only. It is not `load`, which may start what the editor must not run, such as a sound or a body of a world.
- `updateEditor(dt)`, when a type has it, is called there on the components of the chosen nodes only, 30 times a second, with the seconds since the last call, and the view is drawn again after it: so an emitter emits and an animation plays while its node is chosen, as Unity plays a chosen particle system, and the rest of the file stands still. What it moves is the editor's own, such as the picture that `drawEditor` keeps, and goes at the next change. It is called only while the editor has taken the view's last frame, so a slow link gives fewer steps, each of more seconds, up to a tenth of a second. One that fails marks its node, and is not called again until its node is made again. Limits: each step sends a whole frame through the link (12.4), so a chosen moving node costs the editor about what dragging does: on the owner's computer, Linux with an NVIDIA card, a chosen animation of the animation sample cost the editor's plugin about 34 ms a second, 3.4% of it, and the node view drew 26 frames a second, measured with OpenECS-std's profiler on 2026-11-20; nodes that are not chosen do not move, as the view would cost that much all the time; a script's `update` is not called, so what a script moves stays still.
- `drawEditor` may keep in `self` what it builds from the component's values, such as a map read from a file. When a value of the component changes, the preview makes the component anew from the node file's values, so what it kept is built again from the new ones.
- A `drawEditor` that fails marks its node in the view, and the rest draws on.
- `drawEditor` is code, so it can do anything. The node view is kept safe from it:
  - The engine saves all of LÖVE's drawing state before each `drawEditor` and restores it after, so a colour or a shader that one component sets does not reach the next.
  - The engine's functions that change the tree (7) change nothing there, and report an error.
  - The preview's nodes are a copy. The editor holds the node file and only sends it (12.2), so nothing that a component does there reaches the project's files.
  - A `drawEditor` that never returns stops the preview only, which the editor starts again (12.1).

### 6.6 Types that need others

``` lua
Player.needs = { "bump.body" }
```

- A type names the types that its components need on their node, in `needs`.
- The script's author writes `needs`. The engine does not work it out from the script's code.
- A node that gets a component gets those that it needs too, each with its defaults, when the node lacks them: in the editor, when a node file loads, and at `node:addComponent`.
- The editor does not remove a component that another of the node needs, and names the other. `node:removeComponent` of such a component is an error.
- A component loads, updates and draws after those that it needs (5). So its `load` finds them loaded, and `self.node.components.bump.body` is there without a check.
- Types cannot need each other in a circle. The engine refuses such a type, and says so.

### 6.7 Shaders

``` glsl
// effects/flash.glsl
extern number amount;
extern vec4 tint;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  vec4 c = Texel(tex, uv) * color;
  c.rgb = mix(c.rgb, tint.rgb, amount);
  return c;
}
```

- A shader is a file of the project, of one of two kinds:

  | Kind           | Its file                                                                                     | Written by                            |
  | -------------- | -------------------------------------------------------------------------------------------- | ------------------------------------- |
  | A GLSL file    | A `.glsl` file in LÖVE's own form, as `love.graphics.newShader` takes it, in any folder.     | The user, in their code editor.       |
  | An ira-shader | A Lua file in `ira-shaders/`: a graph whose blocks make a colour (6.8).                          | The editor, in the graph panel (13.9). |

- The `shader` property takes either, and gives a LÖVE shader (6.2). The engine loads each file once, and the components that name it share it, as they share an image. So `onlr.shader` (10) and a script's own property use the same files.
- A shader's values are its `extern`s, LÖVE's word for GLSL's `uniform`, which it takes too. An ira-shader's are its properties, with their defaults and options (6.8). A GLSL file's are read from its text: each `extern` or `uniform` outside its functions, of a type of this table. They start at 0, false or white, since GLSL ES gives a value no default:

  | Its type in GLSL           | The inspector shows                                                   |
  | -------------------------- | --------------------------------------------------------------------- |
  | `float`, LÖVE's `number`   | A number field.                                                       |
  | `int`                      | A number field of whole numbers.                                      |
  | `bool`                     | A toggle.                                                             |
  | `vec2`                     | Two number fields in one row, as a `vector`.                          |
  | `vec3`, `vec4`             | Three or four number fields in one row; an ira-shader's colour, a colour. |
  | `Image`, `sampler2D`       | An image of the project. Without one, a white pixel.                  |

  A value of another type, such as a matrix or a list, is not shown, and a script sends it itself.
- `time` is the engine's: a shader's `extern number time` gets the seconds that the game has run, the sum of its frames' `dt`, before each frame draws. The inspector does not show it, and a value of the user's own cannot have its name. So a game that the editor pauses stands still, and Step moves it by one step (12.1). In the node view it is 0, and moves while the node of the shader's component is chosen (6.5). LÖVE's own values, such as `love_ScreenSize`, work as in LÖVE.
- A shader that does not compile is an error in the game, which names its file, its line, and the node and the property that name it, as a path that names no file is (6.2). In the node view, the node is marked and draws without the shader, and the inspector marks the shader's row with LÖVE's message.
- LÖVE compiles a shader as GLSL on a computer and as GLSL ES on a phone, which is stricter: a number such as `1` must be `1.0` where a decimal is meant. The preview checks every shader as GLSL ES too, with `love.graphics.validateShader` (12.5). A shader that fails there still works on the computer: the console warns, with its file and its line, and the inspector marks the row. An export for Android or iOS refuses it, and names it.
- A shader that starts with LÖVE's `#pragma language glsl3` asks for newer GLSL, which the check takes as GLSL ES 3.00; its warning says that a phone without OpenGL ES 3 cannot run it. The GLSL that an ira-shader builds is LÖVE's default, GLSL ES 1.00 on a phone, which every phone that LÖVE runs on takes.
- A script may draw through a shader itself, as in LÖVE: it declares `onlr.property.shader()`, and calls `love.graphics.setShader` and `shader:send` in its `draw`. The engine sets the shader back after the `draw` (6.3).
- The limits:
  - A GLSL file's value cannot say its range, its default, or that it is a colour: a `vec4` shows as four numbers, and starts at 0. An ira-shader's properties say all three.
  - On a phone whose pixel shaders lack high precision, `time` holds fewer digits as it grows, so a shader that moves with it gets coarse after some minutes of play.

### 6.8 Graphs

A graph is made of blocks, joined by wires between their pins. The user makes it in the graph panel (13.9), and the engine builds code from it when the game loads it.

| Kind           | Its folder | Is                                         | The engine builds |
| -------------- | ---------- | ------------------------------------------ | ----------------- |
| An ira-script | `ira-scripts/`  | A component type, as a script is (6.1).    | Lua               |
| An ira-shader | `ira-shaders/` | A shader, as a GLSL file is (6.7).         | GLSL              |

``` lua
-- ira-scripts/door.lua: a door that opens half a second after E is pressed
---@type onlr.Graph
return {
  format = 1,
  properties = {
    {
      kind = "bool",
      name = "open",
    },
  },
  blocks = {
    {
      id = "b3x9mz",
      type = "flow.branch",
      x = 240,
      y = 0,
      inputs = {
        condition = "c4k8wd.result",
      },
      flow = {
        ifTrue = "d2l5qa",
      },
    },
    {
      id = "c4k8wd",
      type = "math.equal",
      x = 0,
      y = 140,
      inputs = {
        a = "k7p1fe.key",
      },
      values = {
        b = "e",
      },
    },
    {
      id = "d2l5qa",
      type = "flow.delay",
      x = 480,
      y = 0,
      flow = {
        done = "s8d1nf",
      },
      values = {
        seconds = 0.5,
      },
    },
    {
      id = "k7p1fe",
      type = "event.keypressed",
      x = 0,
      y = 0,
      flow = {
        out = "b3x9mz",
      },
    },
    {
      id = "s8d1nf",
      type = "property.set",
      x = 720,
      y = 0,
      values = {
        name = "open",
        value = true,
      },
    },
  },
}
```

- A graph's file is a data file (4), the editor's to read and to write, as a node file is, and written as section 4.2 says. A person does not write it.

  | Field        | Holds                                                                                                     |
  | ------------ | --------------------------------------------------------------------------------------------------------- |
  | `format`     | The version of the file's format (4.1).                                                                   |
  | `properties` | Its properties, in the order that the inspector shows them: each a `name`, a `kind` of section 6.2, a `default` and its `options`. An ira-script's are its type's properties; an ira-shader's are the shader's values (6.7), of the kinds `bool`, `integer`, `number`, `vector`, `color` and `image`. |
  | `needs`      | An ira-script's: the types that its components need on their node (6.6).                                 |
  | `blocks`     | Its blocks, in the order of their ids.                                                                    |

  | Field of a block | Holds                                                                                                 |
  | ---------------- | ----------------------------------------------------------------------------------------------------- |
  | `id`             | Its id, unique in its file, as a node's (4.2).                                                        |
  | `type`           | Its type: what it does, and its pins.                                                                 |
  | `x`, `y`         | Its place in the panel.                                                                               |
  | `inputs`         | Its inputs that a wire feeds: by the input's name, the block and the output that feeds it, `"c4k8wd.result"`. |
  | `flow`           | Its flow outputs that a wire leads on: by the output's name, the block that runs next, `"s8d1nf"`.     |
  | `values`         | The values of its inputs that no wire feeds, which the panel shows as fields in the block.            |

- A pin is an input or an output of a block. A value pin carries a value, which an ira-script's blocks give as Lua values and an ira-shader's as GLSL's `float`, `vec2`, `vec3` and `vec4`. A flow pin carries no value: it says what runs next. Only an ira-script has flow pins.
- A value input takes one wire, and a flow output leads on to one block; a value output may feed many inputs, and many outputs may lead on to one block. So each wire is written once, at its end that takes one, and a graph has no list of wires for two changes to conflict in.
- The engine knows the types of blocks, each a file of its own family in the engine (8.3), with its pins and the code that it builds. The editor asks the preview for them (12.5), as it asks for a component type's properties, so the two never disagree.
- An ira-script's blocks:

  | Family     | Blocks                                                                                                   |
  | ---------- | -------------------------------------------------------------------------------------------------------- |
  | `event`    | The functions that the engine calls (6.3), each a block that starts a flow, with what it is given as outputs: `load`, `start`, `enable`, `disable`, `destroy`, `update`, `fixedUpdate`, `lateUpdate`, `keypressed`, `keyreleased`, `mousepressed`, `mousereleased`, `touchpressed`, `touchmoved` and `touchreleased`. `message` is one that `node:send` names (7.2), such as a package's, with its arguments as outputs. `every` starts a flow each so many seconds. |
  | `flow`     | `branch`, which goes on by a condition; `sequence`, which runs its outputs one after another; `forEach`, which runs its output for each item of a list; and `delay`, which goes on after so many seconds. |
  | `property` | `get` and `set` the graph's own properties.                                                              |
  | `node`     | `get` and `set` its node's place, `posX` to `sclY`; `getComponent` and `setComponent`, a property of another component of its node, or of one that a property names; and `send`, which calls `node:send` (7.2). |
  | `math`     | Numbers, texts and toggles, and what joins them: `add`, `subtract`, `multiply`, `divide`, `equal`, `less`, `and`, `or`, `not`, `min`, `max`, `clamp` and `random`. |
  | `debug`    | `print`, which the console shows.                                                                        |

- `delay` and `every` count the seconds of their component's `update`, so they wait while its node is paused or it is off. A `delay` that is started again while it waits does not start over, as Unreal's Delay.
- An ira-shader's blocks:

  | Family     | Blocks                                                                                                   |
  | ---------- | -------------------------------------------------------------------------------------------------------- |
  | `input`    | What LÖVE gives a shader: the colour of the drawn image at the place being drawn, `image`; that place, `uv`; the drawn thing's own colour, `color`; the place on the screen, `screen`; and `time` (6.7). |
  | `property` | `get` a property: a value that the inspector shows on the component that uses the shader.               |
  | `math`     | Numbers and vectors, and what joins them: `add`, `subtract`, `multiply`, `divide`, `mix`, `step`, `smoothstep`, `sin`, `cos`, `fract`, `length`, `split`, which takes a vector apart into its numbers, and `combine`, which puts them together. |
  | `output`   | The colour that the shader gives. An ira-shader has one.                                                |

  A wire between two sizes of vector takes the first numbers of the longer, or repeats a single number into each, or gives a missing alpha 1, as Shader Graph does.
- When the engine loads a graph, it builds its code once, as text in memory, and compiles it: an ira-script's Lua with Lua's `load`, into a component type as a script's (6.1), and an ira-shader's GLSL with `love.graphics.newShader`. So a frame runs compiled code, as fast as a script or a GLSL file that does the same, and never reads a block. Nothing is written into the project, so a graph has one file (OVERVIEW 11).
- The built code is plain to read, a line for each block, named after the blocks. Copy as Lua Script and Copy as GLSL write it into a file of the user's (13.9).
- The engine keeps, for each line of the built code, the block that it came from. An error in a graph's code names the graph's file and the block, and the error that the game sends names the block's id (12.2). So the console's link opens the graph in a graph panel with the block chosen. An ira-shader's error when it compiles names its block in the same way, and so does a graph that cannot be built, such as one whose wire joins pins that cannot meet.
- An ira-script and a script are both component types, so a node holds both, and they reach each other as any two components do: a script reads `self.node.components.door.open`, and a graph's `node.getComponent` reads a script's property.
- The limits:
  - An ira-script has no blocks yet for LÖVE's own functions, such as `love.audio.play`, nor for the engine's, such as `onlr.tree.spawn` (7.2); a script does that.
  - A graph's properties are all shown in the inspector: a graph keeps no value of its own that the inspector does not show.

## 7. The engine's functions

### 7.1 A map

Every function that the engine calls in a component, and what makes it call it. A type defines those that it needs (6.3). A script calls the engine's own functions (7.2), and LÖVE's.

| When                                | The engine calls, in each component that has it                                   | Because of                                                          |
| ----------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Its node enters the tree            | `load`, then `enable` if the component runs                                        | The top node or a root loading (8.1), `onlr.tree.spawn`, `onlr.tree.newNode` and `node:addComponent` |
| Before its first frame              | `start`                                                                           | The end of the frame in which it started to run                     |
| Each frame                          | For each event, LÖVE's callback of it; then `fixedUpdate`, `update`, `lateUpdate`; then `draw`, or `drawTree` for a group | The loop (8.1)                                     |
| Its node is paused, or resumed      | Nothing: it keeps drawing, and gets no other call while paused                    | `node:setPaused`                                                    |
| It stops running, or starts again   | `disable`, or `enable`                                                            | `node:setActive`, `node:setParent` and `component:setEnabled`       |
| It leaves the tree                  | `disable` if it runs, then `destroy`, when the frame ends                         | `node:destroy`, `node:removeComponent` and `onlr.tree.loadRoot`              |
| Another component asks              | A function of the type's own                                                      | `node:send`, or a call such as `body:move(x, y)`                    |
| The editor shows a view             | `loadEditor` once its node is made and after a change, `updateEditor` while its node is chosen, `drawEditor`, `drawTreeEditor` and `bounds`, and nothing else | The node view (6.5, 12.3)                                           |

### 7.2 Functions for scripts

These are the engine's functions for scripts. The rest is LÖVE. The engine's source documents each.

| Function                                                                                                             | Does                                                                                                        |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `onlr.start()`                                                                                                       | Starts the engine, from `main.lua`: makes the engine's loop LÖVE's (8.1).                                   |
| `onlr.conf(t)`                                                                                                       | Sets LÖVE's settings from the project's manifest, from `conf.lua` (3.1).                                    |
| `onlr.loop.load()`, `onlr.loop.event(name, ...)`, `onlr.loop.update(dt)`, `onlr.loop.draw()`, `onlr.loop.endFrame()` | The steps of the engine's loop, which a game's own `love.run` calls (8.1).                                  |
| `onlr.tree.top`, `onlr.tree.root`                                                                                    | The top node and the root (5).                                                                              |
| `onlr.tree.loadRoot(path)`                                                                                           | Ends the root and loads another node file as the root, when the current frame ends.                         |
| `onlr.tree.find(name)`                                                                                               | Gives the tree's first node of that name, in the tree's order (5).                                          |
| `onlr.tree.findAll(name)`                                                                                            | Gives a list of the tree's nodes of that name, in the tree's order.                                         |
| `onlr.tree.findComponent(type)`                                                                                      | Gives the tree's first component of a type, in the tree's order.                                            |
| `onlr.tree.findAllComponents(type)`                                                                                  | Gives a list of the tree's components of a type, in the tree's order.                                       |
| `onlr.tree.spawn(path, x, y, parent)`                                                                                | Makes an instance of a node file at a place in its parent, the file's own when left out, and returns it (9). |
| `onlr.tree.newNode(name, parent)`                                                                                    | Makes an empty node in its parent, and returns it.                                                          |
| `node:addComponent(type, values)`                                                                                    | Gives the node a component of a type that it lacks, and returns it.                                         |
| `node:removeComponent(type)`                                                                                         | Takes the node's component of a type off it when the current frame ends (6.4).                              |
| `node:send(name, ...)`                                                                                               | Calls the function of that name in each of the node's components that runs and has it.                      |
| `node:isActive()`, `node:setActive(active)`                                                                          | Whether the node runs, with all that is under it (6.4), and turns it on or off.                             |
| `node:isPaused()`, `node:setPaused(paused)`                                                                          | Whether the node, or a node above it, is paused (6.4), and pauses or resumes it with all under it.          |
| `node:getZ()`, `node:setZ(z)`                                                                                        | The node's `z` (5), and changes it.                                                                         |
| `node:getParent()`, `node:getChildren()`                                                                             | The node's parent, `nil` for the top node, and the list of its children.                                    |
| `node:setParent(parent, index)`                                                                                      | Moves the node, with all that is under it, to the end of another node's children, or to `index` among them. Under the top node, the end is before the root, which stays its last child (5). |
| `node:destroy()`, `node:isDestroyed()`                                                                               | Destroys the node and its children when the current frame ends, and says whether it was destroyed.          |
| `node:toWorld(x, y)`, `node:toLocal(x, y)`                                                                           | Turn a point of the node's space into the world's, and back.                                                |
| `node:setWorldPosition(x, y)`                                                                                        | Moves the node to a point of the world, whatever its parents' places are.                                   |
| `component:isEnabled()`, `component:setEnabled(enabled)`                                                             | Whether the component is on (6.4), and turns it on or off.                                                  |
| `onlr.font.sharp(font)`, `onlr.font.apply(font)`                                                                     | The font at the size that the drawing shows it, and the scale to draw it at; `apply` also sets that scale (10). |

- A node's fields are `name`, its place, `posX` to `sclY`, and `components`, which holds the components themselves (6.1). A script reads and sets them as plain fields: `self.node.posX = 10`. No function stands before a component: `self.node.components.onlr.sprite`.
- What the engine must act on when it changes is read and changed through functions, as the values of LÖVE's own objects are: whether a node is active or paused, its `z`, its parent and children, and whether a component is enabled. So a change that does more than set a value is always a call, and never looks like a plain assignment. A node file holds them as plain values (5), apart from whether a node is paused, which only a script sets.
- A node's `id` and `instance` are only the files' (9).
- A `parent` that is left out is the root.
- The list that `node:getChildren()` gives is the engine's own: a script reads it and does not change it.
- `node:setParent` keeps the node's own place, so the node moves with its new parent. To keep it where it is in the world, a script calls `node:setWorldPosition` after. A node cannot be moved under itself or a node under it, and the top node and the root cannot be moved.
- No node has tags: a component type is one. With an empty script `enemy` on every enemy, `onlr.tree.findAllComponents("enemy")` gives them all.
- When each function takes effect is in section 6.4.
- The functions that declare properties are in `onlr.property` (6.2). The engine's components have functions of their own, such as the camera's (10).
- A function takes a type's name as one text, dots and all: `onlr.tree.findComponent("bump.world")`.
- `onlr.tree.findComponent` finds what a root has one of. A component that many others need, such as the world that bodies collide in, is a component of the root (5), and the others find it by its type.
- `node:addComponent` takes the properties' values as the component gets them, such as a LÖVE image. An image, a sound and a font may also be given as a node file holds them, such as a path.
- `node:send` is a call, as `body:move(x, y)` is: it reaches every component of the node that runs, paused or not, and one that was made in the same frame.
- `node:send` is how a component makes an event of its own. The engine calls `keypressed` in every component when LÖVE reports a key; in the same way, a component that finds a contact calls `self.node:send("contact", other)`, and every component of that node that defines `contact(other)` is called. The name is agreed between the two components, and the engine does not know it.

## 8. The loop

### 8.1 A frame

- `onlr.start` sets `love.run`, LÖVE's own loop. The engine's loop does what LÖVE's does, and adds the tree. Each step that it adds is a function of `onlr.loop`, so a game that sets its own `love.run` calls them from its own loop:
  1. It calls `love.load`, if the game defines it, then `onlr.loop.load()`, which loads the top node and the first root: the manifest's start node, or the node file that Play names (12.1).
  2. For each event, it calls LÖVE's handler of it, as LÖVE's loop does, which calls the game's own callback, such as `love.keypressed`. Then `onlr.loop.event(name, ...)` calls the components' function of that name.
  3. It calls `love.update(dt)`, then `onlr.loop.update(dt)`, which calls the components' `fixedUpdate` as often as the time asks (6.3), then their `update`, then their `lateUpdate`.
  4. It clears the window and calls `onlr.loop.draw()`, which calls the components' `draw` in the order of drawing, and each group's `drawTree` in its place (5). Then it calls `love.draw()`, which draws over the nodes in the window's own space.
  5. It shows the frame.
  6. It calls `onlr.loop.endFrame()`, which takes out what was destroyed, loads a new root if a script asked for one, and calls `start` of the components that started to run (6.4).
- The events go through LÖVE's own table of handlers, `love.handlers`, as in LÖVE's loop. So a library that adds to it, such as one that draws an interface and hears the keys, works as in any game.
- So code written for plain LÖVE in `main.lua` keeps working beside the nodes, such as an interface drawn in `love.draw`.
- The engine runs on LÖVE's main thread, as a LÖVE game does. A script may use `love.thread` as in any game.
- An error is LÖVE's: the game stops and LÖVE's error handler shows it, as in any game. A game may set its own handler, as LÖVE allows. Played from the editor, the stopped game still shows its nodes there (12.6).
- In an exported game the loop does this and nothing else. What serves the editor is not in the project: the engine loads it from the editor's plugin, and only when the editor starts it (12.1).

### 8.2 How the tree is kept

- A node is a Lua table with the fields of section 7. A component is a Lua table of its own values, which finds its type's functions and defaults through a metatable. A script reads and sets their fields as plain fields, and the engine does not watch them.
- What the engine keeps of a node is in fields of the node whose names start with an underscore, which are the engine's. Their definitions mark them as `package`, so a code editor leaves them out of a script's completion and warns when a script reads one; the engine's files that read them turn that warning off. What it keeps of a component is in a record of its own, outside the component, so every field of a component is the script's.
- What changes which functions run, or their order, is not a field: a node's `active`, whether it is paused, its `z`, parent and children, and a component's `enabled`. The engine keeps them, and a script reaches them through functions (7), so the engine knows of each change when it is made.
- All nodes share one metatable, and the components of a type share one, so LuaJIT compiles a script's code once for every component that runs it.
- For each function that a frame calls, the engine keeps one flat list of the tree's components that have that function, in the order of the tree: for `fixedUpdate`, `update` and `lateUpdate`, and for each event from the first time LÖVE sends it. The list of `draw` is in the order of drawing instead, and each group has one of its own (5). A frame walks the list of `update` and the list of `draw`, and an event walks the list of its name. So the engine walks no tree and asks no component what it has while the game runs, and a node costs a frame nothing for what its components do not define.
- The lists change only when a component starts or stops running, when a node is paused or resumed, when a node is moved, or when a `z` changes, at the moments that section 6.4 names. What changes builds as little as it can, the next time a list is walked, so a frame in which nothing changed builds none:
  - A component that stops stays in its lists, which pass over it, so a node that is destroyed or turned off builds nothing, unless its `drawTree` draws a group, which builds the groups again. One that starts again before the lists are built again runs where it was.
  - A component that starts to run joins the end of its lists when it comes after their last component in the tree's order, as one of a node spawned last under the root does, and its draw joins its group after the draws of its `z` and the lower ones, when they come before it. Else the lists, or the groups, are built again from the tree.
  - A `z` that changes builds the groups of drawing again, and not the lists of the updates; a node that is moved, or paused or resumed, builds them all.
  - When many components stopped since the last build, a quarter of the lists, the next start builds them again, so they do not grow.
  - The components that start at a frame's end are sorted in the tree's order; when many start, as when a level loads, the tree is walked instead.
- A node's place is plain fields, which the engine does not watch. It compares them when it uses the node's place in the world: to draw, and in `toWorld`, `toLocal` and `setWorldPosition`. Each node keeps that place as a LÖVE transform, and the engine works it out again only for a node whose place, or whose parent's transform, differs from the one it used last.

### 8.3 The engine's files

Each file of the engine holds one thing. The engine is laid out as a package is (11.2): what a game calls and what the editor reads at the top, and its own modules in `library/`, which `init.lua` joins. A game requires `onlr`, never a file of `library/`.

| In `packages/onlr/`                                 | Holds                                                                                                                                                      |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `manifest.lua`                                      | The engine's name and its version, as a package's manifest holds them (11.2).                                                                              |
| `init.lua`                                          | What `require("onlr")` gives: `start`, `conf`, and the namespaces of the files below. It joins them, sets where `require` looks (3.1), and does nothing else. |
| `library/loop.lua`                                  | `onlr.loop`: the loop and its steps (8.1).                                                                                                                 |
| `library/tree.lua`                                  | `onlr.tree`: the root, the tree and its lists (8.2).                                                                                                       |
| `library/node.lua`                                  | Nodes and their functions (7).                                                                                                                             |
| `library/component.lua`                             | Component types (6.1): finding and loading a type's file, and a node's `components`.                                                                       |
| `library/life.lua`                                  | The life of components (6.4), and the lists that a frame walks (8.2).                                                                                      |
| `library/build.lua`                                 | Making nodes from node files: their fields, components and values (9).                                                                                     |
| `library/instances.lua`                             | The walk over a node file's nodes and its instances, with their changes and ids (9), which the editor's trees share. It requires nothing.                   |
| `library/property.lua`                              | `onlr.property` (6.2), and turning a node file's values into a component's.                                                                                |
| `library/font.lua`                                  | `onlr.font`: fonts at the size that the drawing shows them (10).                                                                                           |
| `library/shader.lua`                                | Shaders (6.7): loading a GLSL file or an ira-shader, reading its values, checking it as GLSL ES, and `time`.                                              |
| `library/graph.lua`                                 | Graphs (6.8): reading a graph, building its code, and naming the block of a line of it.                                                                    |
| `library/blocks/`                                   | The types of blocks (6.8), a file for each family, such as `flow.lua` and `math.lua`: each type's pins and the code that it builds.                        |
| `library/data.lua`                                  | Reading data files (4), and loading the files that properties name.                                                                                        |
| `library/formats.lua`                               | The definitions of the data files' formats (4.3). Only a code editor reads it.                                                                             |
| `components/`                                       | The engine's components (10), one in each file: `sprite.lua`, `text.lua`, `shape.lua`, `paint.lua`, `shader.lua`, and the camera's in `camera/`: `view.lua`, `follow.lua`, `limits.lua` and `shake.lua`.                                                   |
| `license.txt`                                       | The engine's licence, which an export holds (14.1).                                                                                                        |

- The engine is in `packages/` as a package is, with its components in `components/`. So the editor finds the engine's components and a package's in one way. ONLR's repository keeps it so too: its `packages/` holds the engine and the packages that ONLR ships, with the same files that a project holds. Its source carries its own definitions (4.3), so it needs no definitions file.
- `conf.lua` loads the engine before LÖVE has loaded its modules for drawing, input and the rest (3.1): only its file functions are sure to be there. So no file of the engine uses another part of LÖVE while it loads, only when its functions run.

## 9. Instances

``` lua
-- nodes/coin.lua
---@type onlr.NodeFile
return {
  format = 1,
  id = "c0in7x",
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
      id = "g1nt4k",
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
-- in nodes/level.lua: an instance that is twice as large, worth more, and with its glint off
{
  id = "t1r6bz",
  instance = {
    base = "nodes/coin.lua",
    changes = {
      ["c0in7x"] = {
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
      },
      ["g1nt4k"] = {
        active = false,
      },
    },
  },
},
```

- A node file holds another as an instance: a node with an `id` of its own and `instance`. Any node file can be held so, as any can be loaded as the root (5).
- A node file's first node may be an instance too. The file is then a variant of its base, such as `nodes/bigcoin.lua`, a coin that is worth 5. A variant is held and loaded as any node file, and a change to its base reaches it.
- `instance` holds all that the instance is, in one table:

  | Field     | Holds                                                                                         |
  | --------- | --------------------------------------------------------------------------------------------- |
  | `base`    | The node file that the instance is made from.                                                 |
  | `changes` | What the instance changes in the base's nodes: for each changed node, an entry under its id.  |

- The instance is the base's nodes with the changes laid over them: what a change writes replaces the base's, and what it leaves out is the base's.
- Every node of the base is changed in the same way, the first one and those under it. In the sample, `c0in7x` is the coin itself and `g1nt4k` is its glint.

  | In a change                                                     | Does                                                                                         |
  | --------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
  | `name`, `posX`, `posY`, `rot`, `sclX`, `sclY`, `z`, `active` and `componentOrder` | Replaces the same field of the node. A `componentOrder` replaces the base's list whole. |
  | `components`                                                    | Is laid over the node's components, name by name: each value replaces that property's. A component that the node lacks is added to it. |
  | `children`                                                      | Adds nodes under the node, after its own children. They are nodes of the file that writes them, with ids of that file. |

- A value replaces a property whole. A group is the exception (6.2): it is laid over field by field.
- So an instance changes values, and adds components and children. It removes nothing: what it does not want of its base, it turns off, with `active = false` for a node and `enabled = false` for a component, as the sample does with the glint. What is off still loads, and stays in the tree.
- A node of the base may be an instance too. A change names a node inside it by a path: the inner instance's id, a slash, and the node's id in that instance's base, such as `ch3st9/g1nt4k`. The inner instance's own changes are laid over first, then the outer one's.
- A node file cannot hold itself, directly or through another.
- An id is read in the file that writes it, since the tree holds an id once for each instance:
  - A property that names a node holds an id of its own file. In a base, it gives each instance's own node.
  - From outside, a node inside an instance is named by a path too: the instance's id, a slash, and the node's id in the base, such as `t1r6bz/g1nt4k`. The instance's first node is named by the instance's id alone.
  - Ids are for the files and the editor. The engine turns each into its node when a file loads, and a script never looks a node up by id.
- A change or a reference that names no node, such as after a merge in git, is an error in the game, which names the node file and the id, as a path that names no file is (6.2). The editor clears such names when it deletes a node (13.6).
- A change to a node file reaches every instance of it, apart from what the instance's changes write.
- When the base later gets a component that an instance added, what the instance wrote is from then on a change of the base's component. Nothing else is needed.
- An instance's nodes are nodes of the tree as the others are: `onlr.tree.find` and `onlr.tree.findComponent` look through them too.
- The engine and the editor walk instances with one file, the engine's `library/instances.lua`, so this section lives in one place. The walk reads each node file, lays an instance's changes over its base's nodes in their order, and reads each id in the file that writes it; what a node is, and what laying an entry over it does, is its caller's. The engine makes nodes with components; the editor makes the nodes that its panels show, each with where a change of it is written (13.1). The editor goes on past an instance whose base does not load, which becomes a node with an error, and marks an instance's change that names no node (13.6); the engine stops at both, but notes a change that names no node on its node in the node view.
- `onlr.tree.spawn` makes an instance while the game runs, and calls `load` and `enable` of its components before it returns (6.4).

## 10. The engine's components

The engine has nine component types: `onlr.shape`, a node's outline, three that draw, one that draws through a shader, and the camera's four in the folder `camera/`: the view, and three that help it. A folder of types (6.1) keeps a family together, so `onlr.camera.follow` is found beside `onlr.camera.view`. They are written as scripts are, with the functions of section 7 and LÖVE alone.

| Type          | Is                                                                                                  |
| ------------- | --------------------------------------------------------------------------------------------------- |
| `onlr.sprite` | An image, or a part of one.                                                                         |
| `onlr.text`   | A text in a font.                                                                                   |
| `onlr.shape`  | A node's outline: a rectangle, a circle, a polygon or a line. It draws nothing in the game.          |
| `onlr.paint`  | Draws its node's `onlr.shape`, filled or as an outline, in a colour.                                 |
| `onlr.shader` | Draws its node and all under it through a shader (6.7): each draw alone, or all of them as one picture. |
| `onlr.camera.view` | A view: it draws its node and all under it as a group (5), moved, turned and zoomed so that the middle of its screen shows its point. |
| `onlr.camera.follow` | Moves its node's camera to follow a node, smoothly, with a deadzone.                          |
| `onlr.camera.limits` | Keeps what its node's camera shows inside a rectangle, such as a level's edges.               |
| `onlr.camera.shake`  | Shakes its node's camera when a script asks, and the shake fades.                             |

- A camera shows only what is under its node. So a level puts its world under a node with the camera, and what stays on the screen, such as a score, beside that node. The score draws at the window's pixels, and the camera does not move it.
- What no camera holds draws as plain LÖVE does, with 0, 0 at the window's top left.
- A camera's screen is what it draws into, of the size of its `width` and `height`: the window when they are 0, as they are by default. A library that scales the game draws it at a size of its own, such as 320 by 180, which the camera's `width` and `height` then name.
- A camera's properties move it, not its node's place, which moves the world under it. A script follows the player by setting them in `lateUpdate`: `camera.posX, camera.posY = player.posX, player.posY`.
- `camera:toWorld(x, y)` turns a point of the camera's screen into the point of the world that the camera shows there, in the space of `node:toWorld` (7). `camera:toScreen(x, y)` turns it back. So a click finds its place in the level: `camera:toWorld(love.mouse.getPosition())`. In a game that a library scales, the library first turns the pointer's place into the game's, such as with push's `toGame`.
- A package of a camera library gives a component that draws a group in the same way (11).

Their properties use LÖVE's names wherever LÖVE has one:

| Type          | Property          | Kind                                          | Default    | Is                                                                                               |
| ------------- | ----------------- | --------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------ |
| `onlr.sprite` | `image`           | `image`                                       |            | The image.                                                                                       |
|               | `quad`            | `group` of `x`, `y`, `width` and `height`     | 0          | The part of the image to draw, as a LÖVE quad. A `width` or a `height` of 0 draws the whole image. |
|               | `origin`          | `vector`                                      | 0, 0       | The point of the image, in its pixels, that is at the node's place. The node turns and scales around it. |
|               | `color`           | `color`                                       | white      | What the image is multiplied by, as `love.graphics.setColor` does.                               |
| `onlr.text`   | `text`            | `string`                                      | empty      | The text.                                                                                        |
|               | `font`            | `font`                                        | LÖVE's default, 12 | The font.                                                                                |
|               | `color`           | `color`                                       | white      | The text's colour.                                                                               |
|               | `width`           | `number`                                      | 0          | Where lines wrap, as the limit of `love.graphics.printf`. 0 wraps nothing.                       |
|               | `align`           | `choice` of left, center, right and justify   | left       | How the lines lie within `width`.                                                                |
| `onlr.shape`  | `kind`            | `choice` of rectangle, circle, polygon and line | rectangle | The shape. The inspector shows only the properties of the chosen kind (6.2).                   |
|               | `width`, `height` | `number`                                      | 32         | A rectangle's size.                                                                              |
|               | `radius`          | `number`                                      | 16         | A circle's.                                                                                      |
|               | `points`          | `list` of `vector`                            |            | A polygon's corners, or a line's points, in the node's space.                                    |
|               | `origin`          | `vector`                                      | 0, 0       | A rectangle's and a circle's: the point of the shape that is at the node's place, as a sprite's (above), a rectangle's from its top left and a circle's from its middle. The node turns and scales around it. A polygon's and a line's points are in the node's space already, so they have none, and one value has one owner. |
| `onlr.paint`  | `mode`            | `choice` of fill and line                     | fill       | Filled, or as an outline. A line shape is a line in either.                                      |
|               | `lineWidth`       | `number`                                      | 1          | The width of a line and of an outline, as `love.graphics.setLineWidth`.                          |
|               | `color`           | `color`                                       | white      | The shape's colour.                                                                              |
| `onlr.shader` | `shader`          | `shader`                                      |            | The shader: a GLSL file or an ira-shader.                                                       |
|               | `covers`          | `choice` of draws and picture                 | draws      | `draws`: each draw of its nodes goes through the shader alone, as a hit's flash or an outline needs. `picture`: its nodes draw into one picture, which then draws through the shader, as a blur or a ripple over a whole level needs. |
| `onlr.camera.view` | `posX`, `posY`    | `number`                                      | 0          | The point, in its node's space, that the middle of its screen shows.                             |
|               | `rot`             | `number`                                      | 0          | Its angle, clockwise. What it shows turns the other way.                                         |
|               | `zoom`            | `number`                                      | 1          | How large the camera shows its nodes: 2 is twice as large.                                       |
|               | `width`, `height` | `number`                                      | 0          | The size of its screen, in pixels. 0 is the window's.                                            |
| `onlr.camera.follow` | `target`    | `node`                                        |            | The node that the camera follows. A script may set it.                                           |
|               | `offset`          | `vector`                                      | 0, 0       | Added to the target's place: the camera shows a point ahead of it or above it.                   |
|               | `smoothing`       | `number`                                      | 0.1        | About the seconds that the camera takes to catch up. 0 keeps it on the target.                   |
|               | `deadzone`        | `vector`                                      | 0, 0       | A rectangle around the camera's point in which the target moves and the camera does not.         |
| `onlr.camera.limits` | `x`, `y`, `width`, `height` | `number`                    | 0, 0, 640, 360 | The rectangle, in the camera's node's space, that all the camera shows stays in.            |
| `onlr.camera.shake` | `amplitude`  | `vector`                                      | 8, 8       | The farthest it moves, across and down.                                                          |
|               | `angle`           | `number`                                      | 0.05       | The farthest it turns, an angle (6.2).                                                           |
|               | `frequency`       | `number`                                      | 15         | How fast it shakes.                                                                              |
|               | `decay`           | `number`                                      | 1.5        | How much of a shake of 1 fades in a second.                                                      |

- A text draws at the size that the drawing shows it. LÖVE makes a font's letters at the font's size, so a node's scale, a camera's zoom or the node view's zoom would stretch those pixels and blur them. `onlr.text` measures how much the drawing scales, the larger of its two axes, takes the same font at that size, and draws it at the inverse scale; when the drawing neither turns nor stretches, it also puts the text's place on a whole pixel of the screen. These are `onlr.font.sharp` and `onlr.font.apply`, which a script that draws text uses the same way, and SUIT's widgets use too (11.13). A font of a size is loaded once, and asking for it again, as each draw does, finds it with no new key or table, so a scaled text makes no garbage. The limits:
  - A font that the engine did not load, such as one that a script made with `love.graphics.newFont`, draws as LÖVE draws it, stretched.
  - A size is made at most 512, and each size that a scale gives is a font of its own: a text whose scale a tween moves makes many, which the engine lets go when the root changes (6.2).
  - A text that a node stretches more on one axis is sharp along the larger one only.
  - Lines that wrap, of a `width`, are measured with the sharp font, so they may break a little apart from where `bounds` says.
  - Under push's canvas (11.10), the scale of the canvas is not in the drawing, so the text is as sharp as the game's own size.
- One value has one owner (OVERVIEW 11): `onlr.shape` holds a node's outline, and what uses an outline reads it there, each time it uses it. `onlr.paint` draws it, `physics.fixture` collides with it (11.4), a shadow caster casts a shadow of it (11.14), and `bump.body` takes its rectangle (11.3). So the user sizes a wall once, and its look, its collision and its shadow follow. Each needs `onlr.shape` (6.6).
- `shape:outline()` gives the shape in its node's space, the origin taken off a rectangle and a circle, as LÖVE's functions take it: a rectangle's `x`, `y`, `width` and `height`, a circle's `x`, `y` and `radius`, or the `points` as one list, x, y, x, y. `shape:drawShape(mode)` draws it with LÖVE in the colour that is set; a polygon of fewer than 3 corners, or a line of fewer than 2 points, draws nothing. `outline` makes a new table at each call, for what reads the shape now and then, such as a body when it starts; `drawShape`, which draws at each frame, makes none: a rectangle and a circle draw from the shape's values, and a polygon's or a line's points go into one list that the shape keeps and fills again.
- In the node view, an outline that no `onlr.paint` draws shows as a thin green line of one pixel at any zoom, as a collider's does in Unity, so a node of a shape alone is seen and chosen; on a node that paints it, the line shows when the node is chosen.
- `onlr.shader` holds the shader's values (6.7) in `values`, a table with a field for each. The inspector shows them under its properties, one row each, and a node file keeps those that the user set, as `values = { amount = 0.5 }`. A script sets one as a field, `shader.values.amount = 1`, and the shader gets it before the next draw. Components that name one file share its shader, so each sends its values before it draws.
- `onlr.shader` is a group (5). With `draws`, it sets its shader, sends its values, draws its nodes, and sets back the shader that was set before it. LÖVE has one shader at a time, so a shader under it replaces it for the nodes under that one: a player's flash and its level's tint do not add up. With `picture`, it draws its nodes into a canvas of the size of what it draws into, the window or push's canvas (11.10), at the screen's pixel density, so it stays sharp on a phone. It clears the canvas to transparent, draws its nodes with the drawing's place, then draws the canvas through the shader with none, as `moonshine.chain` does (11.11). So what drew before its node shows where its nodes draw nothing, and a `picture` above other shaders takes in what they drew.
- In the node view, `onlr.shader` draws as in the game, through `drawTreeEditor` (6.5), with `time` at 0. While its node is chosen, its `updateEditor` moves `time`, so a shader that moves with it plays, as an animation does.
- The limits of `onlr.shader`, as they are now:
  - Each `draws` sets its shader twice, and each set ends a batch of LÖVE's draws. So many nodes with a shader each cost many draws; one shader on their parent shades them all at the cost of one.
  - Shaders under a `draws` do not add up, as above.
  - A `picture` costs a canvas of the screen's size.
- Each has `bounds` and `drawEditor` (6.3). A camera's `drawEditor` draws the frame of what it shows, in blue and 3 pixels wide, named "Camera" inside its top left, at the same size at any zoom.
- The camera's helpers are components beside `onlr.camera.view` on its node, which need it (6.6), and a game takes those that it wants. They change the camera's own properties, so a script can do all that they do, and they leave it to one when it sets the camera itself.
  - `onlr.camera.follow` moves the camera's `posX` and `posY` in `lateUpdate` (6.4), after the scripts and the physics moved its target. Its smoothing is the same at any frame rate. `snap()` puts the camera on its target at once, as when the follow starts, a level begins, or the player is put elsewhere.
  - `onlr.camera.limits` moves the camera's point so that all it shows, at its zoom and its angle, is inside its rectangle; a view larger than the rectangle is centred on it. It does so in `lateUpdate`, and `clamp()` does it at once: the follow calls it after each move, so the two agree whichever updates first. In the node view it draws its rectangle, orange.
  - `onlr.camera.shake` shakes when a script calls `shake(amount)`: 0.3 is a bump, and 1, the most, an explosion. Shakes add up and fade. The shake grows as the square of the amount, and moves by LÖVE's noise, smooth from frame to frame. It sets the camera's `shakeX`, `shakeY` and `shakeRot`, which are not properties: the camera adds them to its point and its angle when it draws, and nowhere else, so a shake does not move the camera's point that the follow and the limits set.
  - A script reaches them by the folder: `self.node.components.onlr.camera.follow`, and the view as `components.onlr.camera.view`.
  - `camera:getSize()` gives the size of its screen, which the limits use; divided by its zoom, it is the size of what it shows.
- The limits of the camera's helpers, as they are now:
  - A target is a node of the same node file, as every node property is (6.2). A target of another file, such as a player that the level spawns, is set by a script.
  - A shake can show past the limits by its amplitude.
  - `camera:toWorld` and `toScreen` take no shake, so a click during a shake is off by it.
  - The follow and the limits run in `lateUpdate`; a script that sets the camera in its own `lateUpdate` after them is not limited until the next frame.

## 11. Libraries

### 11.1 Using a library

- A library is Lua code that its author wrote for LÖVE games. The engine does not know it, and it does not know the engine (2.1).
- A project keeps its libraries in `packages/`, where `require` looks (3.1), so a script loads a library by the name its author gives:

  ``` lua
  local bump = require("bump")
  ```

- `require("bump")` finds `packages/bump.lua` or `packages/bump/init.lua`. A library that the user copies in works the same way, with or without a package.
- The file's name is what `require` looks for. A library whose repository is a folder with its file inside, such as `bump.lua/bump.lua`, is copied so that the file is `packages/bump.lua`.
- A script calls the library as the library's own documentation says. ONLR puts nothing between them and renames nothing.

### 11.2 Packages

A package is a folder in `packages/`, named as the library is loaded. It holds what a project holds, in the same folders.

| In `packages/bump/`     | Is                                                              | Read by                                   |
| ----------------------- | --------------------------------------------------------------- | ----------------------------------------- |
| `manifest.lua`          | The manifest, which describes the package (4.1).                | The editor. The game never loads it.      |
| `init.lua`              | Code: one line that returns the library.                        | The game, at `require("bump")`.           |
| `bump.lua`              | The library's definitions (4.3), named as the package, and written with it, since most libraries ship none. | A code editor only. |
| `library/`              | The library's own files, unchanged, with its licence.           | The game, through `init.lua`.             |
| `components/`           | Component types, one in each file: `world.lua` is `bump.world`, and `body.lua` is `bump.body`. | The game, when a node file names the type. |
| `nodes/`                | Node files that the package ships, which a project holds as instances (9). | The game and the editor, as the project's node files. |

``` lua
---@type onlr.Package
return {
  format = 1,
  name = "bump",
  description = "Collision of boxes",
  version = "0.1.0",
  license = "0BSD",
  library = {
    version = "3.1.7",
    source = "https://github.com/kikito/bump.lua",
    license = "MIT",
  },
}
```

- The package's `version` is its own, and grows whenever ONLR changes the package, such as a component of it, even with the same library; its `license` is that of ONLR's files in it. The library's own version, where it comes from and its licence are in `library`, so the editor can tell a newer package from a newer library, and offer either (below). A library that names no version gives its last commit.

- The manifest and `init.lua` stay two files. The editor reads the manifest as any data file (4.1), which cannot load the library. So the manifest describes the package and holds none of its code.
- `library/` holds what the library's author ships. A newer version of the library replaces that folder and nothing else. One library is the exception: a library that breaks a rule of ONLR's, such as one that sets a global, is shipped as ONLR's own copy, changed only as far as the rule needs. Each change is marked in its code, and a note in `library/`, `ONLR.md`, says what was changed and how to change a newer version the same way. `shadows` is so (11.14).
- A component type is one file, since its name is its file's (6.1). The names start with the package's: `bump.body` is `packages/bump/components/body.lua`. The types are written as scripts are (6), and the editor offers every one of them (13.4).
- A node file of a package is named by its path, as the project's are: `packages/bump/nodes/box.lua`.
- A package adds nothing to the engine and changes nothing in it. A game uses a package's library with its components, without them, or both.
- A package may wrap a system of LÖVE's own instead of a library (OVERVIEW 9), as `physics` wraps `love.physics` (11.4). It has no `library/`, no `init.lua` and no definitions file, since a script calls LÖVE as it always does. A module that its components share is a file of the package's own, which they require by its path: `physics/find.lua` is `require("physics.find")`. Its manifest has no `library`.
- The editor copies a package into a project when the user adds it, and deletes its folder when the user removes it. In the project, the package is the project's own copy, and an export holds it.
- The editor adds a package from ONLR's own, or from a folder that the user chooses, so anyone can make one. ONLR's own are in its `packages/`, beside the engine (2.2), each as a project holds it.
- The user does not change a package in the project, as they do not change the engine (3.1). To change one of its components, they copy it into `components/` under another name. When ONLR ships a newer version of a package that a project holds, the editor offers it, and updating replaces the package's folder whole.

### 11.3 A package's components

A package's components show a library in the inspector. The sample is a package for bump, a library that keeps boxes in a world of its own and tells which ones a moving box hits. bump's world is not the tree: it is bump's own list of boxes, and it knows nothing of nodes.

``` lua
-- packages/bump/components/body.lua: a box that collides
local onlr = require("onlr")

---@class bump.body : onlr.Component
local Body = {}

-- its box is its node's outline, which a paint may draw too (10)
Body.needs = { "onlr.shape" }

function Body:box()
  local o = self.node.components.onlr.shape:outline()
  return o.x, o.y, o.width, o.height
end

function Body:load()
  local world = onlr.tree.findComponent("bump.world") or onlr.tree.root:addComponent("bump.world")
  self.world = world:get()
end

function Body:enable()
  local ox, oy, w, h = self:box()
  self.x, self.y = self.node:toWorld(ox, oy)
  self.world:add(self, self.x, self.y, w, h)
end

function Body:disable()
  self.world:remove(self)
end

function Body:move(x, y)
  local ox, oy = self:box()
  local hits
  self.x, self.y, hits = self.world:move(self, x + ox, y + oy)
  self.node:setWorldPosition(self.x - ox, self.y - oy)
  for _, hit in ipairs(hits) do
    self.node:send("contact", hit.other.node, hit.normal.x, hit.normal.y)
    hit.other.node:send("contact", self.node, -hit.normal.x, -hit.normal.y)
  end
end

function Body:update()
  local ox, oy, w, h = self:box()
  local x, y = self.node:toWorld(ox, oy)
  self.world:update(self, x, y, w, h)
  self.x, self.y = x, y
end

return Body
```

``` lua
-- packages/bump/components/world.lua: the tree's one world
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

What the sample shows of every package:

- **What a root has one of** is a component of the root (5): here `bump.world`. It is made with the root and ends with it, so each root has its own, and its node file keeps its settings. It is not a module that lives through the whole game. A component that needs it finds it with `onlr.tree.findComponent`, and adds it to the root when the tree has none. A second world, of a node file that is held in another, is not used.
- **What the library must be told** is told by the component, in its `enable` and `disable` (6.4).
- **A value has one owner** (OVERVIEW 11): the box is the node's `onlr.shape`, which the body needs and reads each time it uses it, so a paint draws the same box that collides, and a script that resizes the shape resizes the box. bump's boxes do not turn, so the body takes the rectangle's corner and size, and not the node's angle or scale; a shape of another kind is an error that names the node. bump asks for each box to be added to its world; the body does that while it runs, so the user does not, and a node that is turned off collides with nothing.
- **Where a node is** has one truth: the node's own place (5). A library that keeps a place of its own, as bump does for each box, holds a copy, and the package's component keeps the copy in step. After `move`, the node takes the library's answer. When a script sets the node's place itself, the component tells the library, in its `update`.
- **What a script asks of the library** is a function of the component: `body:move(x, y)`. The script names the body in `needs` (6.6), so its node always has one.
- **What the library reports** reaches scripts with `node:send`, as a function that the script defines: `contact(other)`. Both nodes of a contact are told.
- **What the editor shows** is `bounds`, for choosing the node, and `drawEditor`, for the outline. Here the shape gives both (10).

### 11.4 Packages of LÖVE's systems

A package of LÖVE's own system follows 11.3 too. The first is `physics`, which wraps `love.physics`, LÖVE's Box2D. LÖVE asks the game to make a world, bodies, shapes and fixtures, to keep them in step with what it draws, and to route Box2D's callbacks; the package's components do that, so a node gets physics by its components alone:

| Type              | On                                   | Does                                                                                         |
| ----------------- | ------------------------------------ | -------------------------------------------------------------------------------------------- |
| `physics.world`   | The root                             | The root's one world, with its gravity, as `bump.world` is (11.3). Each root has its own.    |
| `physics.body`    | A node                               | A body: static, dynamic or kinematic. While the game runs, a dynamic body moves its node.   |
| `physics.fixture` | The body's node, or a node under it | Its node's `onlr.shape` (10), fixed to the nearest body above it, with its `friction`, `restitution`, `density` and whether it is a `sensor`, as LÖVE's fixture has them. |
| `physics.joint`   | The body's node, or a node under it | A joint of its `kind`, hinge, weld, distance, rope, prismatic, wheel, friction, motor or pulley, that holds the nearest body above it to the body that its `other` names, at its node's place. |

- A fixture collides with the node's own outline, which `onlr.paint` draws and a shadow caster casts (10), so the user sizes it once. A rectangle is Box2D's box, a circle its circle, a polygon its polygon, and a line its edge, or its chain of more than two points, which the fixture's `loop` closes from its last point to its first. A body turns around its node's place, so a box centred on it has the shape's `origin` at its middle.
- A node has one component of each type (5), so a body of many fixtures holds them on nodes under its own, each with its shape. The user builds a body's outline by placing nodes in the editor. A fixture takes its node's place, angle and scale in the body when the body starts.
- The world steps in its `fixedUpdate` (6.3). Before each step, each body whose node a script moved or turned goes there; after it, each body that is not static sets its node's place and `rot`. `meter` is how many pixels are a meter, which love.physics is told when the world is made, and `gravity` is in pixels a second, each second, which a script changes as a field: the world sets it before its next step.
- `body:get()` and a fixture's `get()` give the body and the fixture of love.physics, for all of LÖVE's own functions on them, such as `applyLinearImpulse`: the package wraps LÖVE and hides nothing of it.
- Where a node is has one truth, the node's place (11.3): after Box2D's step, a dynamic body sets its node's place; when a script sets a body's node itself, the body is moved there.
- Contacts reach scripts as messages to the two bodies' nodes, `contact(other, nx, ny)` and `contactEnd(other)`, as bump's do, and never as Box2D's callbacks: Box2D tells of them during its step, when nothing may change the world, so the world tells the nodes after it. The normal points away from the other node, so a body that lands on the ground gets 0, -1.
- A node that is turned off takes its body out of the world, and turning it on puts it back (6.4).
- A polygon takes 3 to 8 corners that make a convex polygon, as Box2D does. A new one has none, and collides with nothing until it has 3; more than 8, or a polygon that is not convex, is an error that names its node. A line collides with nothing until it has 2 points.
- A joint is one type with a `kind`, whose inspector shows only the properties of the chosen kind (6.2). It is Box2D's joint of its kind, named as LÖVE names it, but for the hinge:
  - a hinge is the revolute joint: the bodies turn around its node's place, with a limit of the angle, `limit`, `lower` and `upper`, and a motor, `motor`, `motorSpeed` and `motorTorque`;
  - a weld holds the bodies as one;
  - a distance keeps its node's place and the other body's `otherAnchor` as far apart as they were, or springs towards it with a `frequency` and `damping`;
  - a rope lets them come no further apart than its `length`;
  - a prismatic joint lets them slide along its `axis`, in its node's space, and not turn, as a lift or a piston, with a limit of the slide in pixels and a motor, whose force is `motorForce`;
  - a wheel lets the other body turn freely on its node's place, which slides along its `axis` on a spring of `springFrequency` and `springDamping`, as a car's wheel, with a motor. A car's body holds a joint for each wheel on a node under it, an axle, whose `other` is the wheel, so the axis stays in the car's space; a positive `motorSpeed` turns the wheel clockwise, since y grows down, and the car drives right, as the gallery's physics room shows; the spring's least is 0.01 times a second, since Box2D's wheel without a spring fails into numbers that are not numbers, NaN, which then spread to every body that it touches, and LÖVE's own default, 2, is the property's;
  - a friction joint slows the bodies' sliding and turning against each other, up to `maxForce` and `maxTorque`, as a top-down game's floor slows what is on it;
  - a motor joint pushes the other body towards where it was when joined, by `maxForce`, `maxTorque` and `correction`, as a platform that a script moves with LÖVE's `setLinearOffset`;
  - a pulley hangs its node's place and the other body's `otherAnchor` from `groundAnchor` and `otherGroundAnchor`, points of the world given in their nodes' spaces, by one rope, with a `ratio`.
  `other` and `collide` are for all. A joint is made when both bodies run, and ends when either stops, as Box2D ends a joint whose body is destroyed; it is made again when that body starts again. `get()` gives the joint of love.physics.
- Before each step, each body sets what a script changed since the last one, so a script changes physics as it changes any other field:
  - a body's properties, such as `type` or `gravityScale`, and a fixture's, such as `friction`, with LÖVE's setters;
  - a fixture whose node moved, turned or scaled under its body, as an animation might move it, or whose shape changed, such as a resized box, is made again, since Box2D's shapes do not change;
  - a joint whose node moved under its body, or whose `kind`, bodies, `collide`, anchors, `axis` or `ratio` changed, is made again, since Box2D takes them only when it makes a joint; the values that tune it, such as a motor's speed, a limit or a spring, are set on it without making it again.
  A fixture or a joint made again starts afresh: Box2D's contacts with it begin again, and a distance or a rope that was as far as they were when joined takes the distance that they are now.
- The limits, as they are now:
  - A body checks each fixture and joint before each step, also when nothing changed: it compares the values that they are made from with those of the last check, kept in a list, and sets only the properties that differ, with setters that each type makes once. So a step makes almost no garbage, and costs a little for each body.
  - A joint's `otherAnchor` and `otherGroundAnchor` are taken in the other body's node's space when the joint is made. A node under the other body that moves does not move them.
  - `meter` is LÖVE's one setting for every world, set when a world is made. A script that changes it afterwards changes nothing, as Box2D's bodies were sized by the old one.
  - Box2D's mouse and gear joints have no component: a mouse joint holds one body to a point, which a script makes with LÖVE's `newMouseJoint`, and a gear joint joins two other joints.

### 11.5 Animations of a sprite sheet

`anim8` wraps kikito's anim8, which cuts an image into a grid of frames and tells which frame shows at each moment. Its one type, `anim8.animation`, needs `onlr.sprite` on its node (6.6) and draws nothing: each frame it copies the rectangle of anim8's frame into the sprite's `quad` (10), and the sprite draws it. So the sprite's colour and origin, and the node's place, turn and scale, hold for every frame, and a scale of -1 on x flips the animation.

| Property                  | Is                                                                                                   |
| ------------------------- | ---------------------------------------------------------------------------------------------------- |
| `frameWidth`, `frameHeight` | A frame's size, in the image's pixels.                                                             |
| `left`, `top`, `border`   | Where the first frame starts, and the space between frames, as `anim8.newGrid` takes them.           |
| `animations`              | A list of animations, each a `name`, its `columns` and `rows` of the grid, such as `"1-4"` and `"1"`, the `duration` of each frame in seconds, and whether it `loop`s. |
| `first`                   | The animation that plays first. Empty, the first of the list plays.                                  |

``` lua
-- components/player.lua: chooses the animation by what the player does
function Player:update()
  local animation = self.node.components.anim8.animation
  animation:play(love.keyboard.isDown("right") and "walk" or "idle")
end

function Player:animationEnd(name)
  print(name .. " ended")
end
```

- `play(name)` plays an animation from its first frame. The one that plays already goes on, so a script may call `play` each frame; `play(name, true)` starts it again. A name that is not in the list is an error.
- An animation that does not loop stops on its last frame, and its node is told `animationEnd(name)` (11.3). `isPlaying()` says whether one plays; `pause()` and `resume()` hold its frame and go on.
- A range read backwards plays backwards: `"4-1"`. The frames are taken row by row, as anim8 takes them.
- `get(name)` gives anim8's animation, the current one without a name, for all of anim8's own functions on it, such as `gotoFrame`.
- The limits, as they are now:
  - The node view shows the first frame of the animation that plays first, through `loadEditor` (6.5), and plays it while its node is chosen, through `updateEditor`; one that does not loop starts again at its end there, and tells no node. A sprite without an image shows nothing, and a range that the grid lacks marks the node.
  - The grid is cut, and the animations made, when the component loads. A script that changes the sprite's image or a property afterwards changes nothing that plays.
  - Each frame of an animation shows for the same `duration`. anim8 takes a duration for each frame, and a script makes such an animation with anim8 itself.
  - An animation takes one range of columns and one of rows. anim8 takes several, such as the end of one row and the start of the next.
  - The animation moves on in `update`, by the time of each frame of the game.
  - Two animations of one name: the later one is played.

### 11.6 Particles

`particles` wraps LÖVE's particle systems, as `physics` wraps `love.physics` (11.4): it holds no library. Its one type, `particles.emitter`, is a system at its node. Its properties are the system's settings, named as LÖVE's setters name them, so `emissionRate` is `setEmissionRate` and LÖVE's wiki explains each: the `image` of a particle (a small white circle without one), `bufferSize`, `insertMode`, `emissionRate`, `emitterLifetime`, `particleLifetime`, `emissionArea`, `direction`, `spread`, `speed`, the accelerations, `linearDamping`, `sizes`, `colors`, `rotation`, `spin` and `relativeRotation`. A setting that LÖVE takes as two numbers, a least and a most, is a group of `min` and `max`.

- `space` says where the particles live. In `world`, a particle stays where it was emitted, as smoke does: the system follows its node, and turns its `direction` with the node. In `local`, the particles move, turn and scale with their node, as a ring around a player does.
- With `autoPlay` it emits from its start, as a sound plays with its own (11.12). A script calls `play()`, `stop()`, `emit(count)` and `reset()`; `emit` works also on a stopped emitter, as an explosion needs. The function is `play`, not LÖVE's `start`, which the engine calls at a component's start (6.4).
- When it stops emitting, at the end of its `emitterLifetime` or at `stop`, and its last particle dies, its node is told `particlesEnd()` (11.3), once until it emits again. A node that plays an explosion destroys itself there.
- `getCount()` gives the particles that live, and `get()` LÖVE's system, for all of LÖVE's own functions on it, such as `setQuads`.
- The node view shows the system after it has run for a particle's lifetime, at most 5 seconds, made once and kept until a value changes (6.5). While its node is chosen, the picture goes on emitting, through `updateEditor` (6.5). It also draws a cross at the node and the emission area.
- The limits, as they are now:
  - The properties are read when the emitter loads. A script that changes one afterwards calls `apply()`, which sets them all again; the particles that live keep what they had.
  - In `world`, the node's scale does not size the particles, and its turn turns only the `direction`, not the emission area.
  - A node that is turned off draws nothing, and its particles stand still until it is on again.
  - The node view's picture moves only while its node is chosen, and is drawn at the node also for a `world` emitter, so moving the node moves the particles that it emitted.
  - A system takes up to 8 sizes and 8 colours, as LÖVE does; more is an error.
  - Particles from a sprite sheet, LÖVE's `setQuads`, and the image's `offset` have no property: a script sets them on `get()`.

### 11.7 Tile maps

`sti` wraps STI, Simple Tiled Implementation, which loads a map made with [Tiled](https://www.mapeditor.org) and draws it with LÖVE's sprite batches. Its one type, `sti.map`, is a map at its node: `map` names a map that Tiled exported as Lua, such as `maps/level.lua`, with its tilesets' images beside it. The map's top left corner is at the node's place, the node's turn and scale turn and scale it, and a camera above it moves it, as it moves every node.

- `layers` names the layers that the node draws, in that order; empty, it draws every visible layer. So a game puts its player between a map's layers: one node draws the ground, and a node drawn after the player draws the treetops (5). A named layer draws even when Tiled hides it; a name that the map lacks is an error.
- Animated tiles move on in the component's `update`.
- `toTile(x, y)` gives the column and the row, from 1, of the tile at a place in the world, and `toWorld(column, row)` the place of a tile's corner, so a script finds what is under a node: `map:get():getTileProperties("ground", map:toTile(x, y))`.
- `get()` gives STI's map, for all of STI's own functions: its layers by name with their objects, the properties that Tiled gives tiles, layers and objects, `setLayerTile`, and layers that a script draws.
- The node view draws the map as the game does, loaded once and kept until a value changes (6.5).
- Three more types sit beside `sti.map` on its node, and need it (6.6). Which tiles collide, Tiled says, by the property `collidable`, as STI's own plugins read it: every tile of a tile layer that has it, every tile whose tileset gives it, wherever it is placed, the rectangles that a tile holds in Tiled's collision editor that have it, and the rectangles of an object layer that has it, or that have it themselves. A module of the package, `sti.solid`, finds them for both.
  - `sti.bump` makes each such rectangle a box of bump's world (11.3), at the node's place, which a `bump.body` stops at, as at another solid body, and whose contact names the map's node. Its `solid`, off, lets bodies pass and still tells them; a script changes it at any time, and the next move reads it. `getBoxes()` gives the boxes, each with `tile`: its rectangle, layer and properties.
  - `sti.physics` makes them fixtures of one static body of Box2D's world (11.4), at the node's place and angle and scaled as the node, so a `physics.body` falls onto them and rests, and a contact names the map's node. Its `friction`, `restitution` and `sensor` are a fixture's, and what a script changes of them reaches the fixtures before the next step, in the component's `lateUpdate`. `getBody()` gives the body, whose fixtures' user data hold `tile`.
  - `sti.objects` makes Tiled's objects nodes: each object of the map whose property `node` names a node file of the project, such as `nodes/coin.lua`, becomes an instance of that file under the map's node (9), at the object's place, turned as the object, and named as it when it has a name. So the author places coins and enemies in Tiled, and makes each one in ONLR's editor. Its `layers` names the object layers to take, every one when empty. `getNodes()` gives the nodes.
  - Each finds the tree's `bump.world` or `physics.world`, and adds one to the root when the tree has none, as a body does. The project must hold the bump or the physics package: the editor does not add it with `sti`.
- The component draws each layer itself, where the node draws, and does not call STI's `map:draw`, which draws through a canvas of the window's size from the screen's corner, so a node's place and a camera would not reach it.
- The limits, as they are now:
  - The map is loaded when the component loads. A script that changes `map` afterwards changes nothing; one that changes `layers` changes what draws.
  - Only maps that Tiled exports as Lua, with their tilesets embedded, as STI takes them: not `.tmx` files, nor tilesets in files of their own.
  - A layer's parallax, which STI's own `map:draw` applies, is not applied.
  - An object layer that is visible draws its objects as STI's grey outlines, as a debugging aid. A game hides it in Tiled, or leaves it out of `layers`.
  - The tiles' boxes and body are made where the node is when they start to run, and do not follow a node that moves afterwards; turning the node off and on makes them again. bump's boxes do not turn, so a turned map's boxes are the rectangles around its turned tiles.
  - A tile that a script changes with `setLayerTile` does not change what collides.
  - A contact names the map's node, not the tile: a script finds the tile with `toTile`, or reads `tile` from the box or the fixture.
  - Only rectangles collide. Tiled's ellipses, polygons and points do not, as STI's plugins take only rectangles too.
  - `sti.objects` takes an object's place and turn only. Its size and its other properties are not given to the instance; a script reads them from the layer. An object becomes a node in the game only: the node view shows the object layer as STI draws it, not the instances, since the preview runs no `load` (6.5).
  - `bounds` is right for orthogonal maps only.
  - The node view reloads the map only when it makes the component again, and STI keeps the images that it loaded. So a map or a tileset that Tiled saves again shows after the preview starts again.
  - STI makes a canvas of the window's size for each map, for its own `map:draw`, which the component does not use.

### 11.8 Tweens and timers

Two packages of rxi's, made to be used together: `flux` moves numbers to other values over time, a tween, and `tick` calls a function after a delay, or every few seconds. Each gives a node a component that holds a group of its own, which moves on in the component's `update`: `flux.tweens` and `tick.timers`. A script names them in `needs` (6.6).

``` lua
-- components/door.lua: slides open over half a second, and closes three seconds later
local Door = {}

Door.needs = { "flux.tweens", "tick.timers" }

function Door:open()
  local tweens, timers = self.node.components.flux.tweens, self.node.components.tick.timers
  tweens:to(self.node, 0.5, { posY = self.node.posY - 64 }):ease("quadout")
  timers:delay(function() self:close() end, 3)
end
```

- The group is the node's, not the game's. So a node's tweens and timers stop with it: they wait while it is turned off or paused (6.4), and end when it is destroyed, and none calls a function of a node that is gone. A game that wants tweens of its own, beside the tree, uses the libraries as they are: `require("flux")`.
- `tweens:to(obj, time, vars)` is flux's own: it moves any table's numbers, the node's `posX` as a sprite's `color[4]`, and returns flux's tween, whose functions chain: `ease`, `delay`, `onstart`, `onupdate`, `oncomplete` and `after`. A tween of a value that another tween moves takes it over.
- `timers:delay(fn, seconds)` and `timers:recur(fn, seconds)` are tick's own, and return tick's event: `:stop()` on it ends one timer, and `:after(fn, seconds)` chains another.
- `stop()` ends every tween or timer of the node; `tweens:stop(obj)` ends those of one table. A stopped tween stays where it is, and calls no `oncomplete`. It is safe to call in a tween's or a timer's own function: flux's and tick's own `stop` take one out of their list by moving the last into its place while the list is walked, which can skip one or break the walk when many stop at once, so the components leave the stopped ones in place with nothing to do, and go on in a new group.
- `count()` gives the tweens or the timers that wait or run.
- The limits, as they are now:
  - A tween or a timer moves on in `update`, by the time of each frame, never in `fixedUpdate`. A tween of a physics body's node fights the body's own motion (11.4).
  - A tween ends with the node of its component, not with the table that it moves. A tween of another node that is destroyed goes on moving numbers that nothing reads, until it ends.
  - flux's `stop` and tick's `stop` on one tween or one event are the libraries' own, with the problem above when many stop in one walk; the components' `stop` has none.
  - The node view shows nothing of them: it runs no `update` (6.5).

### 11.9 Input actions

`baton` wraps tesselode's baton, which reads keys, mouse buttons and joysticks as a game's own controls. Its one type, `baton.input`, is a player's controls. A script asks for a control by its name, such as `jump`, and never for a key, so the game's keys are set in one place, in the inspector, and a gamepad works as the keyboard does.

| Property                 | Is                                                                                                        |
| ------------------------ | --------------------------------------------------------------------------------------------------------- |
| `controls`               | A list of controls, each a `name` and its `sources`, as baton writes them, apart by commas: `key:left, key:a, axis:leftx-, button:dpleft`. |
| `pairs`                  | A list of pairs, each a `name` and the four controls that are its `left`, `right`, `up` and `down`, read as one stick. |
| `deadzone`, `squareDeadzone` | How far a stick moves before it counts, and whether a pair's deadzone is a square or a circle.       |
| `joystick`               | Which joystick is this player's, by the order they were connected: 1 is the first, and 0 reads none. Two players are two nodes, of joysticks 1 and 2. |

``` lua
-- components/player.lua: walks by the pair move, and jumps
local Player = {}

Player.needs = { "baton.input" }

function Player:update(dt)
  local input = self.node.components.baton.input
  local x = input:get("move")
  self.node.posX = self.node.posX + x * 120 * dt
  if input:pressed("jump") then
    self:jump()
  end
end
```

- `get(name)` gives a control's value from 0 to 1, or a pair's x and y from -1 to 1. `down`, `pressed` and `released` say whether it is held, went down this frame, or went up this frame. `getActiveDevice()` says whether the keyboard and the mouse or the joystick was used last, for a game that shows "press Enter" or "press A".
- The input reads its sources in its `update`. A script that reads it in its own `update` gets this frame's controls when the input updates first: on the script's node, which `needs` gives (6.6), or on a node above.
- A joystick that is connected or taken out reaches the component as LÖVE's events, `joystickadded` and `joystickremoved` (6.3), and it takes the joystick that its number names again.
- `apply()` binds the controls again from the properties, after a script changed them, as a game's menu of keys does. The controls start again, as none were down.
- A source of no kind, and a pair that names no control, are errors that name them when the input loads, as baton itself does not check them. A control that is not there is baton's error when a script asks for it.
- `getPlayer()` gives baton's player.
- The limits, as they are now:
  - `pressed` and `released` are true for one frame. A script that reads them in `fixedUpdate` misses them in a frame with no fixed step, and sees them twice in a frame of two (3.2).
  - A script on a node that updates before the input's node reads the controls of the frame before.
  - The mouse's place and its wheel, and touches, are not sources: baton reads the mouse's buttons only. A script reads them with LÖVE's own functions.
  - A joystick is chosen by the order of connecting, not by its name or its id.
  - The inspector takes the sources as text. It does not listen for a key to bind.

### 11.10 Scaling to the window

`push` wraps Ulydev's push, which draws a game at a fixed size, such as 320 by 180, and scales it to the window, with bars where the window's shape differs. Its one type, `push.screen`, is a group (5): on the top node, it holds the whole game, so every root draws at the game's size. The manifest's `window` stays the window's size, and the screen's `width` and `height` are the game's.

- `pixelPerfect` scales by whole numbers only, so each pixel of the game is a square of the window's, as pixel art needs; `stretched` fills the window with no bars; `borderColor` is the bars' colour. `canvas` chooses how the game is scaled. Without it, the default, push scales the drawing itself and cuts it to the game's rectangle with a scissor, so what the game draws is drawn at the window's pixels: text (10) and large images stay sharp. With it, the game draws into a canvas of the game's size, and push scales the canvas, as pixel art needs, so each pixel of the game is a block of the window's. A canvas of the window's size would make the screen do nothing but draw the bars, so it is not offered. A game of pixel art turns `canvas` and `pixelPerfect` on, and sets the manifest's default filter to `nearest` (3.2), so the scaled canvas is not blurred. `screen:hasCanvas()` says which way the screen draws.
- A place in the window, such as the mouse's, is not a place in the game: `screen:toGame(x, y)` turns it into one, or nil on a bar, and `toReal` turns it back. So a click under a camera is `camera:toWorld(screen:toGame(love.mouse.getPosition()))`.
- A camera under the screen names the game's size as its own, in its `width` and `height` (10). Without them it takes the window's, and its middle is off.
- The window's new size reaches the component as LÖVE's event `resize` (6.3).
- push is one table for the whole game, so a game has one screen: a second that starts to run while one runs is an error that names the first one's node.
- In the node view, the screen draws its frame, green and named "Screen", as a camera draws its own (10). The window's grey frame is the manifest's window, which the game is scaled into.
- `get()` gives push, for its own functions, such as `setShader`, which draws the scaled game through a shader at the window's size.
- The project settings set it up in one click, Scale to the window, under the window's Resizable and Fullscreen, which say what they do without it. The click copies ONLR's push package into the project when it lacks it, makes `nodes/top.lua` and names it the top node when the project has none, and gives the top node a `push.screen` of the manifest's window size, so the game keeps the size it was made at and is scaled from it. Once the top node has a screen, the settings say so in place of the button. The node file and the manifest change as one, which Ctrl+Z takes back; the copied package and a new top node's file stay, as files that the user makes do.
- The limits, as they are now:
  - push sets the window's mode when it is set up. The component gives it the window's own size and flags, so the window stays as the manifest made it, but LÖVE may make the window anew there.
  - push sets LÖVE's background colour to `borderColor` each frame. So where nothing draws, inside the game too, the window shows the bars' colour.
  - What `love.draw` draws, after the nodes (8.1), is at the window's pixels and is not scaled.
  - With `canvas`, everything under the screen draws at the game's size, text too. A game that wants text at the window's size there draws it outside the screen, or in `love.draw`.
  - A script changes `width`, `height`, `pixelPerfect`, `stretched` and `canvas` as fields: the screen sets push up again before it next draws, or turns a place with `toGame` or `toReal`. Setting it up makes push's canvas anew, so a script does not change them each frame. `borderColor` is set at each draw.
  - Without `canvas`, the game's place in the window may fall between two pixels when the scale is not whole, which `linear` blurs a little; `pixelPerfect` keeps it whole.

### 11.11 Screen effects

`moonshine` wraps vrld's moonshine, a chain of shaders that a scene is drawn through: blur, glow, a vignette, a CRT's glass and others. `moonshine.chain` is a group (5) that draws its node and all under it through the effects. Each effect is a component type of its own beside it on the same node, in the folder `effect/` and named as moonshine names the effect, whose properties are the effect's parameters with moonshine's defaults: `moonshine.effect.vignette`, `crt`, `scanlines`, `glow`, `gaussianblur`, `fastgaussianblur`, `boxblur`, `chromasep`, `desaturate`, `pixelate`, `posterize`, `filmgrain`, `colorgradesimple`, `godsray`, `dmg` and `sketch`. Each needs the chain (6.6).

- The effects apply in the chain's own order, not in the node's `componentOrder` (5), so a script changes the look by changing one list: its property `order` lists the effects' names, such as `pixelate` then `crt`, in the order they apply, and those it does not name apply after, by their names. A game composes its look by adding and removing components, as it does for anything else, and by `order`. A script that changes `order` makes the chain anew.
- An effect whose component is turned off is skipped. A property that a script or a tween changes, such as a vignette's `opacity` that flux moves when the player is hurt (11.8), reaches the effect in the next frame: the chain sends each parameter that changed, before it draws.
- An effect that joins or leaves the node makes the chain anew.
- The chain draws into canvases of the size of what it draws into: the window, or push's canvas under a `push.screen` that has one (11.10). It draws its nodes with the drawing's place, as a camera above it set it, and its result with none, so they are not moved twice.
- The chain's effects show only in the game: it has no `drawTreeEditor` (6.5).
- `get()` gives moonshine's chain, made when it first draws.
- moonshine's `fog` effect is not shipped: its file names no licence, and it was translated from another's code. The rest are MIT, or in the public domain, as each file says.
- The limits, as they are now:
  - moonshine clears its canvas to LÖVE's background colour before it draws the group. So a chain covers what drew before it in the window, such as the nodes before its node: a chain belongs on the top node, the root, or the node of all that it should cover.
  - Some effects measure with the window's size, `love.graphics.getWidth()`, and not with the chain's: the blurs, `glow`, `chromasep` and `filmgrain`. Under a `push.screen` with a canvas, their sizes are of the window's pixels, and `glow` keeps a canvas of the window's size.
  - A colour of an effect is the inspector's colour without its alpha.
  - Each frame the chain compares every parameter with what it sent. `fastgaussianblur` and `glow` make their shaders anew when theirs change, so a tween of them is slow.

### 11.12 Sound

`audio` wraps LÖVE's own sound, `love.audio`, as `physics` and `particles` wrap theirs (11.4): it holds no library. LÖVE plays a file through a source, which a game makes, plays, loops and stops by hand; the package's components do that at a node, so a sound is placed and set in the editor.

| Type             | Is                                                                                                       |
| ---------------- | -------------------------------------------------------------------------------------------------------- |
| `audio.source`   | A sound at its node. LÖVE decodes it whole when it loads, its `static` source, for short sounds such as a jump or a coin; or, with Stream, streams it as it plays, its `stream` source, for music and other long sounds. |
| `audio.listener` | Where the game hears from: LÖVE's one listener, at its node.                                             |

- Streaming is part of the `sound` property's value (6.2): the inspector shows a Stream toggle beside the file. Music is a source with Stream, `autoPlay` and `looping` on, not a type of its own (OVERVIEW 11). By default a source waits for a script.
- Its properties are LÖVE's setters' names: `sound`, `autoPlay`, `looping`, `volume` and `pitch`, and for a sound with a place `positional`, `attenuation`, a group of `reference` and `max` as `setAttenuationDistances` takes them, and `rolloff`. A value that a script or a tween changes, such as music's `volume` that flux fades out (11.8), reaches LÖVE in the next frame.
- A script calls `play()`, `pause()`, `stop()`, `isPlaying()`, `seek(seconds)`, `tell()` and `getDuration()`, which are LÖVE's, and `get()` for LÖVE's source itself, such as for `setFilter`. `play` plays on a sound that plays already, as LÖVE does; `playNew()` plays a new copy over those that play, as shots and footsteps need, and gives its source. `stop` stops the copies too.
- When a sound plays to its end, its node is told `soundEnd()` (11.3), and not at `stop`. A node that plays a last sound and goes destroys itself there.
- A node that is turned off pauses its sounds and its copies, and turning it on plays them on (6.4). Its destroy stops them, so a level's sounds end with the level, and music on the top node plays on through every level (5).
- A sound with a place, `positional`, plays from its node's place in the world, and follows it: louder near the listener, and from its left or its right. Nearer than `reference` it plays at its volume, and it fades until `max`, by the listener's `distanceModel`. Without a place, a sound plays at the listener, wherever that is.
- The listener sets LÖVE's listener in `lateUpdate`, after what it follows moved: at its node's place, or, on a camera's node, at the camera's point (10), so the game hears what the screen shows. Its `volume` is every sound's, `love.audio.setVolume`, and `distanceModel` is `love.audio.setDistanceModel`'s. A game has one listener at a time, as LÖVE has; a second that runs is an error. Without one, LÖVE's listener stays at 0, 0.
- The node view draws a speaker at a source's node, and for a chosen sound with a place, its `reference` and `max` as circles. The preview plays nothing (12.1).
- The limits, as they are now:
  - A sound with a place must be mono, as OpenAL, under LÖVE, places only mono sounds. A stereo file with `positional` is an error that names its node.
  - `positional` is read when the component loads; a script that changes it afterwards changes nothing.
  - A node that `node:setPaused` pauses (6.4) plays its sounds on, as pausing calls no function of a component. A pause menu that should quiet the level pauses its sounds itself, or turns their nodes off.
  - `playNew`'s copies take the values of their start: a later `volume` reaches the sound and not its copies. With a place, they follow their node.
  - The listener and a camera's follow both move in `lateUpdate`, in their node's `componentOrder` (5). A listener above the follow in the inspector hears from where the camera was a frame before; the user moves it below.
  - LÖVE's effects, such as reverb, and its filters have no property: a script sets them on `get()`.
  - Grouping sounds by kind, such as a volume for effects and one for music, as ripple does (TODO.md, Libraries), is not offered yet.

### 11.13 An interface inside the game

`suit` wraps vrld's SUIT, a small library of buttons, labels, checkboxes, sliders and text fields, for a game's menus and its screens of settings. SUIT is immediate: a game asks for each widget every frame, with its place and its size, and SUIT answers whether it was clicked; nothing is kept between frames for an editor to place. So the package gives a component for each widget, which asks SUIT for itself each frame. The user places widgets on nodes in the editor, and sees them in the node view.

| Type               | Is                                                                     | Tells its node              |
| ------------------ | ---------------------------------------------------------------------- | --------------------------- |
| `suit.button`      | A box with a text.                                                     | `clicked()`                 |
| `suit.label`       | A text.                                                                | `clicked()`                 |
| `suit.checkbox`    | A box that a click checks, with a text beside it: `checked`.           | `changed(checked)`          |
| `suit.slider`      | A bar that the pointer drags from `min` to `max`: `value`.             | `changed(value)`            |
| `suit.input`       | A field that the keyboard types into after a click on it: `text`.      | `changed(text)`, and at Enter `submitted(text)` |
| `suit.imagebutton` | A button that is an image, with others while hovered and held.         | `clicked()`                 |

- A widget's top left corner is at its node's place. A text's widget has a `width` and a `height`, where 0 fits the text, a `font`, and its text's `align` and `valign`, as SUIT names them.
- A script reads and sets the values, such as `checkbox.checked` or `input.text`, which the widget shows from the next frame. A change by the pointer or the keyboard sets the value, then tells the node (11.3). A script that wants a menu's button calls nothing: its node's script has `clicked`.
- `getState()` gives SUIT's state, `normal`, `hovered`, `active` while the pointer holds it, or `hit` in the frame of a click; `isHovered()` whether the pointer is over it. A text field's `grabFocus()` gives it the keyboard, and `hasFocus()` says whether it has it. `get()` gives the game's SUIT, for what the widgets do not do.
- The game has one SUIT, which every widget asks, in the tree's order. SUIT ends its frame once a frame, after every widget asked: it reads the mouse's button then, and forgets the keys.
- A widget draws in its node's `draw`, where SUIT would have drawn it from `love.draw`. So it draws in the node's order of drawing, with its node's place, and a camera above it moves and zooms it as it does any node (10). A menu is drawn at the window's pixels by putting it where no camera holds it. A widget's text draws at the size that the drawing shows it, as `onlr.text`'s does (10): the widget draws through SUIT's theme at the inverse of the drawing's scale, with the font at that size.
- The pointer is taken in the widget's own space: when it draws, the widget keeps how its node's space lies in the drawing, and turns the pointer into it in the next update. Under a `push.screen` with a canvas (11.10), the pointer is first turned into the game's, by the screen's `toGame`; without one, the drawing that the widget kept holds push's scale already. So a widget under a camera, a turned node or a scaled game is clicked where it shows.
- The look is SUIT's theme, `suit.theme`, which every widget shares: a script sets its colours, `require("suit").theme.color.hovered.bg = { 1, 0.5, 0 }`, or its `cornerRadius`.
- The node view draws a widget as it is with no pointer over it, by a SUIT of its own, and its rectangle is what it draws.
- The limits, as they are now:
  - Of two widgets under the pointer, the one first in the tree's order takes it, as SUIT gives the pointer to the first that asks, though the one drawn later shows on top.
  - The pointer is turned with what the widget drew in the frame before: a node that moved this frame is clicked where it was.
  - A text field cuts its text to its box with a scissor, which LÖVE keeps straight: in a turned node it cuts to the box's straight bounds.
  - A widget that its node's `setPaused` pauses still draws, as it was, and takes no pointer.
  - SUIT's keyboard reads one key and one text a frame. A held Backspace repeats only when the game turns LÖVE's key repeat on, `love.keyboard.setKeyRepeat(true)`.
  - The theme is one for the game; a widget has no colours of its own. SUIT's layout, which places widgets in rows and columns, is not used: nodes place them.

### 11.14 Light and shadows

`shadows` wraps Matías Hermosilla's Shädows, which darkens a scene but where lights reach it, and casts shadows from shapes in a light's way. Its world draws the light into a canvas: dark, of its `color`, where no light reaches, and each light's colour, fading with distance, where one does. The canvas is multiplied over the scene, so a white ground under a white light shows as it is, and in the dark it is black.

| Type                    | Is                                                                                        |
| ----------------------- | ----------------------------------------------------------------------------------------- |
| `shadows.world`         | A group (5): it draws its node and all under it, then the light over them.                |
| `shadows.light`         | A light at its node: `radius`, `color`, the `arc` that it lights around its node's way, an angle (6.2), and soft edges, `blur` and `sizeRadius`. |
| `shadows.caster`        | Its node's `onlr.shape` blocks light and casts shadows (10): a rectangle, a circle or a convex polygon. A line casts nothing. |

- A light and a caster belong to the nearest `shadows.world` on their node or above it, as a physics fixture belongs to the nearest body (11.4). Without one, a world is added to the root, as a body of physics or of bump adds its world (11.3); a world on the root darkens all of the game. So a level puts the world on the node of all that it lights, and a world's lights light only its own casters.
- Lights and casters follow their nodes: a light takes its node's place and its angle, which turns a beam, and a caster its node's place, angle and scale. Before the world draws, each is given its node's place in the world, and a caster's shadow is moved only when its outline moved in the world, since Shädows makes the shadows of the lights that reach a moved shape again.
- A value that a script or a tween changes, such as a light's `color` that flickers or its `radius`, shows in the same frame.
- The world draws the light where the drawing is, as `moonshine.chain` does (11.11): a camera above it moves and zooms the light with the world (10). Its canvas is of the size of what it draws into, the window or push's canvas under a `push.screen` that has one (11.10).
- A caster reads its node's `onlr.shape` before each draw, so a shape that a script resizes casts its new shadow, and one whose `kind` changes casts a shadow of the new kind.
- A node that is turned off takes its light or its caster out of the world, and turning it on puts it back (6.4).
- `get()` gives Shädows' own object, for what the components do not do: the world's `LightWorld`, with its rooms and stars, a light's `Light`, with `SetImage`, and a caster's shadow shape, which is made again when the shape's kind changes.
- Shädows sets a global, `shadows`, through Lua's `module`. So the package ships ONLR's copy of it, changed so that it sets none, and the `lights` sample checks so (11.2). `library/ONLR.md` lists the changes.
- The node view shows a light's reach, or its beam, and the shape's outline (10). The light itself shows only in the game, as the world has no `drawTreeEditor` (6.5).
- The limits, as they are now:
  - Shädows takes a camera's place and zoom, not its angle: under a camera that turns, the light does not turn with the world.
  - The light's canvas is multiplied over all that is in what the world draws into, also what drew before the world's node. So the world belongs on a node that draws first, such as the level's root, and what draws after it, such as a score, is not darkened.
  - A light's `radius` does not grow with its node's scale.
  - Soft edges, `blur`, which is on by default, cost each frame in proportion to the light's area. On a weak GPU they are what costs: drawn in software, as the checks draw, the gallery's room of two lights of radius 260 and 420 takes 90 ms a frame with them and 9 without, where every other room takes about 1.5. A game for phones turns `blur` off on its large lights.
  - Each caster is a body of Shädows' own. Shädows' bodies of many shapes, its heights, its images, normal maps and height maps, its rooms and its stars have no component: a script makes them on `get()`.
  - A polygon is meant to be convex, as a physics fixture's is (11.4); a concave one is not tested.
  - Each caster that moves makes the shadows of the lights that reach it again, which is slow for many moving casters.

## 12. The runner and the link

### 12.1 The runner

- The editor starts LÖVE itself, unchanged, as a program of its own on the project's folder. Arguments tell the engine that the editor started it, the mode, where the editor listens, and where the runner's files are: `--onlr-runner=FOLDER`, `--onlr-mode=preview` or `game`, `--onlr-port=PORT`, for Play This File `--onlr-start=PATH`, and for a window size that Play chose `--onlr-size=WIDTHxHEIGHT`.
- The runner's files are the Lua code that serves the editor: the link and the views. They belong to the editor, in its plugin's `runner/` folder (13.1), and no project or export holds them. The engine loads them with Lua's own `loadfile`, which reads any path, where LÖVE's file functions read only the game's folder (3.1). So a project and its exports hold nothing of the editor, and both ends of the link are of one version of ONLR.
- A runner runs in one of two modes:

  | Mode    | Runs                                        | Draws into                                     |
  | ------- | ------------------------------------------- | ---------------------------------------------- |
  | Preview | Views: node files drawn and not updated (12.3). | Frames for the node views (12.4).           |
  | Game    | The game.                                   | LÖVE's own window.                             |

- The preview runs while a project is open, and has no window that the user sees.
- LÖVE starts every game by running its `conf.lua` and `main.lua`, so the preview runs them too, and the code of each script that is outside its functions when the editor asks about the script (12.5). It does not call `love.load`, nor a component's `load` or `update` (6.5). So what both the game and the node view need, such as the default filter, is in the manifest (3.2), and the engine sets it in both runners.
- In the preview, the engine sets LÖVE's volume to 0, so a sound that the game's code plays there is not heard. On Linux the editor starts it with SDL's offscreen video driver, `SDL_VIDEODRIVER=offscreen`, so it opens no window and still draws with the graphics card. On Windows that driver cannot start LÖVE, whose runtime there has no EGL. So there LÖVE opens its window, and the runner's files hide it as soon as the engine loads them, with SDL's `SDL_HideWindow` through LuaJIT's FFI. The preview then draws into canvases, as on Linux.
- Play saves the project (13.6), then starts a second runner with the manifest's start node as its first root, as an exported game starts. Play This File does the same with the node file of the node view that has the focus. The top node runs above it (5). When the file in focus is the top node's, Play This File plays as Play does. Stop ends it, and so does closing its window.
- The Game bar's Window chooses the size of the game's window when it plays: the manifest's own, or another, such as a phone's (360 by 800, 390 by 844, and 800 by 360 on its side), a tablet's or a common screen's. So the author sees how the game lays itself out on a screen it was not made on, without changing the manifest, which an exported game keeps. The project's editor settings keep the choice (13.3). The runner sets the size after the manifest's settings, and turns off `fullscreen`. Limits: the window is that many pixels on the author's screen, not a phone, so its pixel density, touch and safe areas are the computer's; a game whose `conf.lua` sets the window after `onlr.conf` keeps its own size; a size taller than the author's screen is shrunk by the system, as 13.2 says of the manifest's.
- While a game plays, the editor takes the colour of the setting `onlr.playTint`, a brown, mixed into the theme's colours (OpenECS DESIGN 12.4): about a third of it into the space around the panels, which is the title bar's too, and the rows of tabs, a quarter into the tabs and the panels, a fifth into the buttons, and two fifths into the lines around them. Fields and text keep their colours. So the author sees at once that what they change now is in the running game, and gone at Stop (12.6), and the text stays readable. It is set through OpenECS's settings for the run only, `ecs.setting.setForRun` (OpenECS DESIGN 12.2), so the user's own colours are never written, and come back at Stop, or when the editor ends while a game plays. A tint that is not a colour of the form `#RRGGBB` is taken whole.
- Pause stops the game, and Step runs one frame of it. While it is paused, the engine's loop handles LÖVE's events for LÖVE alone, such as quit, and draws, but calls nothing of steps 2 and 3 of a frame (8.1). Step runs those steps once, with `dt` of one fixed step (3.2), so it runs one `fixedUpdate`. Resume goes on.
- The game is LÖVE as an exported game runs it: the window, the keyboard, the pointer, the gamepads and the sound are LÖVE's own, and the engine stands in for nothing.
- What a mode draws into is the one difference between the modes. Starting a runner, the link, the console and the errors are the same code for both, so the editor's other parts do not know where the game is drawn.
- A runner is another program, so a game that fails or never returns leaves the editor running. The editor shows what happened, and starts the runner again when asked.
- The editor gives the preview two seconds for each answer. When it does not answer, as when a `drawEditor` never returns, or the game's code fails before the engine has loaded, the editor ends it, shows in the console the last hundred lines that it printed, among them the error that ended it, and starts it again at the next change. The editor keeps no more of the preview's lines, and none of the game's, which reach the console as they are printed. When it stops twice in a row, it does not start again until the user asks, with Start the Preview Again.
- The editor reads what a runner prints, and shows it in the console, each line an entry, which stacks on the one before it when it repeats it (OpenECS-std DESIGN 31). In a runner, the engine turns off the buffer of the game's output, so each line shows when it is printed. Play clears the console first, with `console.clear()`, unless the setting `onlr.clearOnPlay` is off; the console itself knows nothing of games.
- Each entry names its source, which the console's checkboxes show or hide: `game` for what the game prints and its errors, `preview` for the preview's errors and what it printed before it ended, `export` for what an export says, and `onlr` for the editor's own warnings. The console also takes in the log's lines, each with its plugin as its source, `onlr` for the editor's own, so a misuse that the editor or OpenECS reports reaches the user without a terminal. Its Show dropdown shows the entries from a level up. OpenECS-std's console starts at Warnings and up, from its setting `console.show`; ONLR's preset sets it to Info and up, so the game's prints show and the log's debug lines do not.

### 12.2 The link

- The link is a TCP connection on this computer: the editor listens on a free port of `127.0.0.1`, and the engine connects to it with LuaSocket, which LÖVE ships. Each player has a link of its own.
- A message is a Lua table written as text, and may carry a block of bytes after it, such as a frame's pixels. Each message starts with a line of the sizes of both, in bytes: `52 0`, then the text, then the block. Both ends write and read messages with one file, `plugins/onlr/runner/wire.lua`, which the runner loads as one of its parts and the editor with `loadfile`, so they cannot drift apart; it requires nothing.
- The editor adds what arrives to one buffer of the runner's, a `string.buffer`, and reads each message where it lies in it: a block is given to its handler as an array of the buffer's bytes, read during the call only, so a frame is copied once on its way to the graphics card, into the buffer. The node view takes a frame only when its block holds 4 bytes for each pixel of its size.
- A message's `type` names it. The tables below give each message's type, and the runner's files document its fields.
- When a runner has connected, it sends `hello`, with its mode and the engine's version.
- A runner never waits to send. What the system does not take at once, such as the rest of a large frame, waits, and goes at the runner's next frame, so an editor that stops reading for a while stops neither the game nor the link. While messages wait, only the newest `values`, `tree` and `stats` are kept. When more than 64 MB waits, the runner closes the link, as the editor reads nothing. At an error, the runner waits at most two seconds for the error to go, since the preview ends then.

| The editor sends | Type                      | To              | For                                                                                                        |
| ---------------- | ------------------------- | --------------- | ---------------------------------------------------------------------------------------------------------- |
| A file           | `file`                    | The preview | A node file or a graph as the editor holds it, saved or not, its text in the block: at each change in the editor or on disk, and when the preview starts, each with changes. A file that does not load goes as its text on disk, so its views go empty. The preview reads it in place of the project's file. |
| A change         | `change`                  | The preview | One edit of a node's own fields in such a file, such as a moved node, or of its components' values, such as a dragged point. |
| A view           | `view`                    | The preview | Which node file to draw, from where, at what size, which nodes are chosen, and which the user hid (12.3, 13.3); or, with `closed`, that the view is gone. |
| A shader's view  | `shaderView`              | The preview | Which shader to draw, on which picture, at what size, for a graph panel's preview (13.9).                 |
| Shown            | `shown`                   | The preview | The editor has taken the last frame (12.4).                                                                |
| A question       | `question`                | The preview | What a component type declares, what a shader's values are, which types of blocks there are, or a graph's built code (12.5). |
| Reload           | `reload`                  | The preview | A file of the project that is not Lua changed, such as an image.                                           |
| Stop             | `stop`                    | Both runners    | The runner ends.                                                                                           |
| Pause, Step, Resume | `pause`, `step`, `resume` | The game | The game stops, runs one frame, or goes on (12.1).                                                      |
| Watch            | `watch`                   | The game | Whether to send the running tree, as `tree`, and which running nodes' values to send, or none (12.6).      |
| A running change | `set`                     | The game | A new value for a running node (12.6).                                                                     |

| The engine sends | Type     | From            | For                                                            |
| ---------------- | -------- | --------------- | -------------------------------------------------------------- |
| Hello            | `hello`  | Both runners    | The runner has connected: its mode and the engine's version.   |
| A frame          | `frame`  | The preview | The picture of a view, or of a shader's view (12.4).           |
| Bounds           | `bounds` | The preview | The nodes' bounds and places, when they change (12.3).         |
| An answer        | `answer` | The preview | What a question asked, or why its file does not load (12.5).   |
| The tree         | `tree`   | The game | The running tree's nodes, when it changes (12.6).              |
| Values           | `values` | The game | The watched nodes' places and values (12.6).                   |
| Stats            | `stats`  | The game | The frames a second, and the time of update and draw (12.6).   |
| An error         | `error`  | Both runners    | Its message, file, line and stack, and what raised it, with a graph's block (13.1, 6.8). |
| Halted           | `halted` | The game        | The game stopped at its error, and keeps answering the link (12.6). |

- A change carries a node's own fields, its name, its place, its `z` and whether it is active, and values of its components that a node file holds as they are, such as a shape's `width` or its `points` that the Shape tool drags (13.3). The preview sets them on the view's nodes, so a drag draws at once; a component reads them where it uses them, as `onlr.shape`'s users do (10). For any other edit, and at a drag's release, the editor sends the file again, and the preview makes the views' nodes anew.
- A node file that does not load leaves its view empty, and its error names the view.

### 12.3 Views

- The preview only draws, and what it draws are views.
- A node view shows a view of an open node file. Other files, such as an image or a sound, are shown by the asset viewer (13.1) as the files they are; how the game draws them shows in the node view.
- The preview makes a view's nodes from its node file, and makes them again only when that file or a file that they come from, such as an instance's base, changes, or when the view shows another file. It then forgets the old nodes: the engine lets go of their components and of the files that they held, so a long session keeps only the views that show. A file that does not load is read again only when a file changes, not when the view moves.
- The preview draws a view when the editor asks: after a change, or when the view moves, and 30 times a second while a chosen node has `updateEditor` (6.5). It runs no loop of frames otherwise, so it uses the processor only when something changed or moves.
- What is drawn is split by what it depends on:

  | Drawn by                    | What                                                                  | Because                                                       |
  | --------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------- |
  | The preview, in LÖVE    | Each component's `drawEditor` (6.5): its picture, and its own outlines. | It depends on the component, and its author writes LÖVE code. |
  | The panel, over the frame   | The grid, the outline of the chosen nodes, and their handles.        | It depends on the pointer and the tool, and is the same for every component. |

- The engine sends every node's `bounds` (6.3), in the node's own space, with the node's place in the world: when a node file loads, and when its nodes change, not with each frame. The panel places them in the view itself, so moving the view sends nothing, and a turned node's outline turns with it. The panel draws its part from them and finds the node under the pointer from them, so a click needs no answer from the player.
- A node without `bounds` covers no rectangle, such as one whose only component is a script. The panel draws a small marker at its place, so it can be seen and chosen.

### 12.4 Frames

- The engine draws a view into a canvas of the view's size, reads the canvas back, and sends its pixels.
- The engine sends a frame only when the editor has taken the last one, so a slow editor never fills the link. The editor says so when the frame arrives, so the engine draws the next one while the panel shows this one.
- A frame names the place and the zoom that it was drawn from. The panel draws the frame, the grid, the outlines and the handles all from that place and zoom, not from where the view has moved to since. So the nodes stay on the grid, and the panel's drawing on the nodes, while the user moves the view and the next frame is on its way.
- A frame is bigger than what the system holds of a connection at once. The editor reads the rest of a frame that has started at once, not at its next look at the link.
- LÖVE holds a pixel as red, green, blue and alpha, and OpenECS-std's gpu textures as blue, green, red and alpha. The engine draws the view's canvas once more through a shader that swaps red and blue, then reads it back. So the graphics card does it, and the panel takes the pixels as they come.
- The engine clears a view's canvas to transparent, so the panel's grid shows behind the nodes (13.3). LÖVE's canvases hold colours multiplied by their alpha, as gpu's textures do, so the shader changes nothing else.

### 12.5 What the editor learns from LÖVE

- The editor never loads a script. To show a type's properties, it asks the preview, which loads the file as the game would and answers with the type's properties (6.2): their names, kinds, defaults and options, in their order. It answers with the types that the type needs too (6.6).
- When a Lua file of the project other than a node file changes on disk, such as a script or the manifest, the editor starts the preview again, which takes about a tenth of a second, and asks again. So nothing of the old code stays in it.
- The editor does not read a shader or build a graph either. It asks the preview for a shader's values (6.7), which the preview reads from a GLSL file's text or an ira-shader's properties, with the result of checking the shader as GLSL ES: so the inspector shows `onlr.shader`'s rows, and the console warns of a shader that a phone cannot run. It asks again when the file changes, or when the editor's copy of a graph does. It asks once for the types of blocks (6.8), which the graph panel's list offers, and asks for a graph's built code when the user copies it (13.9).
- While the preview is down, such as after an error in `main.lua`, the node view shows the error, and the inspector shows the values that the node file holds, without their kinds.

### 12.6 The running game

- While the game plays, the node hierarchy and the inspector can show the running tree in place of a node file. A change made there changes the running game only, and is gone at Stop. The panels mark that they show the running game.
- The editor asks the game for the tree. The engine sends each node's name, its children and its components' types, and sends the tree again when it changes, at most four times a second. It knows of a change by a number that the engine raises at each change of the tree, a node that joins, leaves, moves or is turned on or off, and a component that joins or leaves, and by each node's name, which is a field and raises nothing: so a tree that did not change costs a walk of its names, and is neither made nor written. A running node has no id of a file (9), so the engine gives each a number for the link.
- For the chosen nodes, the engine sends their places and their components' values ten times a second. A reference is sent as what it names: a file as its path, and a node or a component as the node's number.
- A value that the user changes is sent to the game, which sets it between two frames, as a script sets a field. A node's active and a component's enabled are set through their functions (7).
- The game stops at an error, as a LÖVE game does (8.1), and in place of Unity's Pause on Error, which a game's error cannot have, it keeps answering the link while LÖVE's handler shows the error: the node hierarchy's running tree and the inspector's values show the nodes as the error left them, and a value can still be read, until Stop. The Game bar says that the game stopped at an error. Nothing runs any more, so no frame updates or draws, and Pause, Step and a changed value do nothing a game would show. LÖVE 11.5's own handler is `love.errhand`, which the runner calls; a game that sets its own `love.errorhandler` in `main.lua` replaces the runner's, and the editor gets the error from its print alone.
- Twice a second, the game sends its frames a second, and the mean time that a frame spent in update and in draw, in milliseconds. The Game bar shows them while the game plays, so the user sees what makes a game slow. The engine's loop measures the times only when a runner runs it; the time of draw leaves out `love.graphics.present`, which waits for the screen. A game with its own `love.run` sends its frames a second alone.
- The engine sends none of the tree and the values unless the editor asks, and an exported game holds none of it (8.1).
- A game that sets its own `love.run` does not run the engine's loop (8.1). The game then reads the link when the game's frame ends, and Pause and Step do nothing.

## 13. The editor

### 13.1 Plugins and panels

- The editor is an OpenECS tool: a preset and plugins, in Lua unless a part needs C. The user never sees or writes them.
- It builds on OpenECS's standard plugins (OpenECS-std DESIGN): process starts the runners, net carries the link, fs watches the project, compress and hash serve export, web downloads LÖVE, and ui and draw make the panels.
- Every panel is a panel type that a plugin registers (OpenECS DESIGN 4), and the preset only places them. No panel is built into the editor, so the user opens, moves and groups them as in any OpenECS tool.
- The preset places the asset viewer under the inspector, in the same column, so a file that a click chooses shows beside its details (13.7).
- A panel that needs nothing of ONLR, such as the files panel, the asset viewer and the console, is a standard plugin that knows nothing of ONLR and serves any OpenECS tool: OpenECS-std's `files`, `viewer` and `console` (OpenECS-std DESIGN 29, 30 and 31).
- Such a plugin is told what ONLR needs through its functions. The files panel takes handlers: what a click shows, how a file opens, which files it makes, what a rename and a delete do, and what the question before a delete adds. It drags a file as a list of paths, as another application's files come. The console takes lines, each with its source (12.1), and the folder that their files are in.
- A panel of ONLR's own, such as the inspector or the node hierarchy, is built from generic parts, such as ui's elements. A part that it needs and that knows nothing of ONLR is added to the standard plugin that it belongs to, not written inside ONLR, and not worked around.

ONLR's own panels and functions are one plugin, `onlr`, whose names all start with `onlr.`, such as `onlr.play` and the panel type `onlr.view`. It has a file for each part:

| In `plugins/onlr/`                      | Holds                                                                                         |
| --------------------------------------- | --------------------------------------------------------------------------------------------- |
| `init.lua`                              | Loads the parts, and registers the functions that they give as the plugin's.                  |
| `project.lua`, `format.lua`, `resolve.lua` | The open project: its manifest, its node files, the chosen nodes, the chosen tool, and the records it gives to the project's history (13.6). It reads and writes the files, and watches the folder. `format.lua` reads a file with the engine's `data.lua`, and `resolve.lua` makes a file's tree with the engine's `instances.lua` (9), both loaded from ONLR's own engine in `packages/onlr/`, beside the plugin, not from the project's copy. |
| `nodeview.lua`, `runners.lua`, `link.lua`, `hints.lua` | The node view, the runners and the link, and the functions Play, Play This File, Pause, Step and Stop. |
| `panels.lua`, `hierarchy.lua`, `inspector.lua`, `tools.lua`, `settings.lua`, `search.lua`, `shared.lua` | The other panels of ONLR's own: the node hierarchy, the inspector, the bars Transform, Game and Action, the project settings and the search. The History panel is OpenECS-std's (13.6). |
| `graph.lua`                             | The graph panel (13.9).                                                                       |
| `export.lua`, `runtimes.lua`           | Export (14), and LÖVE's runtimes (15).                                                        |
| `runner/`                               | The runner's files (12.1), which the editor names to LÖVE and never loads itself.              |

- The parts call each other's functions as Lua functions, and other plugins call them as `onlr.*`.
- Each panel type is a class, as OpenECS's Lua panels are (OpenECS DESIGN 1.1): the node hierarchy's is `Hierarchy`, and its panels' states are objects of it, whose methods draw them and take their events.
- The panels built with ui are `ui.panelType`'s (OpenECS-std DESIGN 5): their `view` gives the elements, and ui draws them, gives them the events first and forgets the panel when it closes; a type's own `event` gets only the events that no element took, such as the node hierarchy's F2 and Ctrl+A, or a drop on the inspector outside its elements. The node view draws its own GPU surface, so it registers its functions itself.

- The project's data lives in `project.lua`, not in a panel (OpenECS DESIGN 10). Panels show it, change it through its functions, and hear of changes through its events.
- Every panel can be open many times. What belongs to the project is one, in `project.lua`: its files, the chosen nodes, the chosen tool, snapping and the history. So two node views of one file show the same nodes, two inspectors show the same chosen nodes, and a change made in one panel shows in every other at once.
- The tools are three panel types, each a `bar` of ui's styles (OpenECS-std DESIGN 5), in one row that wraps, so a narrow panel takes the rest to a second line and every control stays visible:

  | Panel type       | Title     | Holds                                                                                   | The preset puts it      |
  | ---------------- | --------- | --------------------------------------------------------------------------------------- | ----------------------- |
  | `onlr.transform` | Transform | The tool, the pivot, snapping and the grid (13.3).                                      | Over the node view, where its tools act. |
  | `onlr.action`    | Action    | Undo, Redo and Save, with the history's count, such as 3 of 5 changes, not saved.       | Across the top, at the left. |
  | `onlr.game`      | Game      | Play, Play This File, Pause, Step and Stop; the Window of Play; and while a game plays, its state and its frames a second. | Across the top, beside Action. |

- A control's tooltip names its keys with ui's `keys`, after its text, dimmed. Play, Play This File, Pause, Step and Stop are on F5, F6, F7, F8 and Shift+F5, and Save on Ctrl+S, for the whole editor, in the preset, as the title bar's buttons and bars act anywhere: in the files panel, the console, the viewer and export too. OpenECS's core binds Ctrl+Z, Ctrl+Y and Ctrl+Shift+Z to OpenECS-std's history for every tool, and they act on the project's history in every panel too (13.6); the tools' keys work in the node view and in the Transform bar.
- What belongs to one panel is its own state (OpenECS DESIGN 4): where a node view looks from and its zoom, which nodes a node hierarchy has open, and which components an inspector has folded.
- The asset viewer shows a file of the project as what it is, with the standard loaders: an image with image, a sound with audio and mixer, and a text with syntax. It shows no video, since OpenECS-std's video does not read LÖVE's Ogg Theora.
- The console is a log whose lines may name a file and a line, which a click opens in the user's code editor. Opening a file at a line in the user's code editor runs a command that is a setting, `console.editor`. The console first checks that the command's program is there, as a path or in the folders of `PATH`. When it is not, or does not start, the system opens the file with the program that it has for such files, and the console warns once.
- An error of the game shows as one entry, with its stack. It names the component that raised it and the component's node, which the engine knows, as it notes the component whose function it calls. When a node file wrote the node, the name is a link, and a click opens the file and chooses the node. A hint follows, when the error is one that the editor knows: what such an error often means in a game, in plain words, and what to try. The hints are a list of patterns in `hints.lua`, matched against the error's text, and know Lua's errors, LÖVE's and the engine's.
- `project.lua` tells of changes with events, such as `onlr.chosen`: a project opened or closed, files changed, saved or renamed, the chosen nodes, the tool, the types, and a file that changed on disk. Its functions and events are documented in its code.
- A change costs what its files hold, not what the project holds. The changed event names the files, and only they are written again: each file keeps its text, as the editor writes it now, made once at each change. The trees of nodes are kept until a file that they are made of changes, so only those are made again; an edit of nodes' places, turns, scales or z changes the file's own tree in place, and it is not made again, since nothing else in a tree holds those fields, though a change of a name or of active makes it again, as the lists keep their rows while the tree is the same; the preview is sent only the changed node files, with those texts, in the message's block; the list of node files is kept until the folder's watch sees one come or go; and the search makes its index again only when a search with a query shows.
- Each panel type draws its panels again only at the events that change what they show, which it names in OpenECS's `redrawOn` (OpenECS DESIGN 4.3), so the plugin keeps no list of panels for it. What the running game sends is an event for each kind, `onlr.runningTree`, `onlr.runningStats` for the frames a second and `onlr.runningValues` for the watched nodes' values, so the values, ten times a second, draw the inspector again, and not the node hierarchy or the bars. `onlr.shown` says that what the node hierarchy and the inspector show changed: the running game or the node file, the chosen running node, or the file chosen in the files panel; `onlr.exported`, what the Export panel says. A setting's event, `onlr.settings`, draws every panel that shows any setting, since settings change only when the user changes one. A panel in a hidden tab draws when it is next shown. The node view draws again at the tool and the settings this way, and at other events only the views of their file.
- A long list builds only the rows in view (OpenECS-std DESIGN 5): the search's results with ui's `ui.range`, the History panel as OpenECS-std builds it, and the node hierarchy's tree by itself, as every tree of ui does. So a file of thousands of nodes, or a long history, costs a panel what it shows.

### 13.2 Projects

- ONLR's preset gives OpenECS an `open` function (OpenECS DESIGN 13.6), so a project's folder named on the command line opens.
- The title bar's menus are the tool's menu (OpenECS DESIGN 6.8, 6.11), and hold what concerns the whole project, as Unity's do: File has New Project, which asks for an empty folder, Open Project, which asks for a folder, Save and Quit; Edit has Undo, Redo, Copy, Paste, Duplicate, Delete, Select All, Select Children and Search; Game has Play, Play This File, Pause, Step, Stop and Start the Preview Again; Window has Project Settings and Export, which show those panels, then OpenECS's entries. The preset's layout holds neither panel: an entry gives the focus to the open one, or opens one as a tab beside an inspector, or beside the focused panel when no inspector is open, and the editor that starts with no project opens the Project panel, for its list of the projects opened last. The settings and the list of panels put themselves under Tools. After the menus, the title bar has Play, Pause and Step as buttons, as Unity has them above its view; the Game bar keeps its own (13.1). The editor sets the settings `onlr.playing` and `onlr.paused` for the run only, so Play and Pause show on while a game plays and while it is paused. The history is in the Action bar, Pause and Step in the Game bar, and all are on keys, and export in its panel. The Project panel has both too, and while no project is open it lists the projects opened last.
- ONLR's preset turns on OpenECS's `ecs.keepSession` (OpenECS DESIGN 13.4), so the editor starts as it was closed: with its project, which the session keeps with the projects opened last, its panels where the user put them, the files each node view shows, and the locks. A project named on the command line opens in place of the kept one. So a layout that a new version of ONLR's preset changes shows only once the editor starts from the preset again: with OpenECS's `--fresh`, or with the setting off.
- The editor holds one project at a time. Opening another closes the one that is open, after asking about unsaved work.
- A new project holds the files that section 3.1 says the editor writes, the engine in `packages/onlr/`, empty `components/` and `shared/` folders, and `nodes/start.lua`, an empty node. Its manifest names that file as the start node, the folder's name as the game's `name` and `id`, a window of 1920 by 1080, the size of most screens, and the `nearest` default filter (3.2). On a screen of that size the window does not fit beside the title bar and the task bar, so the system shrinks it or lets it pass the screen's edge; the user makes it smaller, `resizable` or `fullscreen` in the project settings.

### 13.3 The node view

- Many node files can be open at once, each in a node view of its own. One preview draws them all, since each is a view (12.3). Play This File and the panels follow the node view that has the focus.
- The node view has five tools: move, turn, scale, Rectangle and Shape, chosen by W, E, R, T and Y, as Unity's keys are. The first three draw one gizmo for all the chosen nodes, and a drag on the gizmo or on a chosen node changes the places of them all. The node view draws them over the frame (12.3). The tools are the Transform bar (13.1), and every node view follows the tool chosen there.
- The chosen nodes turn and scale by one amount, around a pivot that the Transform bar chooses, as Unity's Pivot and Center do:

  | Pivot      | Each node turns and scales around                                                                   | The gizmo is at                         |
  | ---------- | --------------------------------------------------------------------------------------------------- | --------------------------------------- |
  | Own place  | Its own place, so it stays where it is. The default.                                                 | The place of the node chosen last.      |
  | Own middle | The middle of its own bounds (12.3), so a node whose place is a corner turns about its middle.      | The middle of the last chosen one's bounds. |
  | Selection  | The middle of the rectangle in the world that holds every chosen node's bounds, so they move as one. | That middle.                            |

  The amount is how far the pointer turns around the gizmo, or how much nearer or farther it goes, so every node turns and scales by the same. A node without bounds counts as its place. The pivot is a setting of the project, `pivot`, `own`, `bounds` or `selection`, kept with snapping, and the functions `onlr.pivotOwn`, `onlr.pivotBounds` and `onlr.pivotSelection` choose it. With Selection, a turn or a scale goes around the middle where it started, and the gizmo stays there while it goes, though the rectangle around the turned bounds changes. After it, the middle is kept while the chosen nodes stay as the turn left them, so turning in several drags goes around one point, as one drag would. A change of the choice, a move, an edit in the inspector or an undo measures the middle again.
- A click chooses the node that draws last under the pointer, and another click at the same place chooses the one under it. Shift adds to the choice, and a drag from empty space chooses every node whose middle is in the rectangle.
- The move tool's gizmo is two arrows, along the world's x in red and its y in green, which points down, as y grows down in LÖVE. A drag that starts on an arrow moves the chosen nodes along its axis alone, as Unity's arrows do, and only that axis snaps. A square between the arrows moves them on both axes. The arrows and the square are above the nodes, so they take the press before a node under them, such as a camera's big frame.
- A drag that starts on a node, or on the gizmo, drags the chosen nodes with the tool: move by the pointer's way, turn by its angle around the gizmo, and scale by its distance from it. The turn tool's gizmo is a ring with a line along the leading node's x; a press within 16 pixels of it starts a drag, also beside the nodes. The scale tool's gizmo is a square, which scales both axes, and two grips, lines with a box at their ends along the leading node's own x in red and its own y in green, as Unity's are. A drag on a grip scales that axis alone, by how far the pointer goes along the grip from the gizmo: each chosen node's own Scale X or Scale Y changes by that amount, and its place moves along the grip from its pivot. A press within 12 pixels of the square, or on a grip, starts a drag, above the nodes, as the move tool's arrows do. With chosen nodes turned apart, a grip follows the leading node, and scales the others along their own axes, which may not be along it. The preview draws each step (12.2), and the release is one change of the history.
- The Rectangle tool sizes the one chosen node by handles at the corners and the edges' middles of a rectangle, as Unity's Rect Tool does. A drag of a handle moves that edge, or those two, while the edges across stay, and stops just before the edge across. What it changes depends on what the node's size is:
  - A node whose `onlr.shape` is a rectangle has the shape's own handles, as the Shape tool's below, and a drag changes the shape's `width`, `height` and `origin`. Its size is a property, as a sliced sprite's or an interface's rectangle is in Unity, so what it holds, such as a physics fixture made from the shape (11.4), takes the new size, and the node's children are not stretched.
  - Any other node has handles on its bounds (12.3), and a drag changes its Scale X and Scale Y, and its place, so the edges across stay where they are, as Unity's Rect Tool does to a sprite. So a sprite, a circle, a text and every component of a package scale as one, with the node's children.

  A drag inside the node moves the chosen nodes, as the move tool does. A point snaps to the grid in the node's space, as the Shape tool's does. The preview draws each step (12.2), and the release is one change of the history, Size for a scale. The limits, as they are now:
  - With more than one node chosen, the tool shows no handles. Unity's sizes the rectangle around all of them.
  - Shift does not keep the node's proportions.
  - A circle is scaled, so its two axes may differ and it draws as an ellipse, while a physics fixture keeps it round. A text is scaled too, not given a `width` to wrap at.
  - A node without bounds, such as an empty one, has no handles.
- The Shape tool edits the one chosen node's outlines and points, as Unity's Edit Collider does, with handles, small squares above the nodes:
  - `onlr.shape`'s rectangle has one at each corner and at each edge's middle. A drag of one moves that edge, or those two, while the edges across stay: the right edge changes `width`, and the left edge `width` and `origin`, so the node's place stays where it is in the shape. An edge stops at the one across from it.
  - Its circle has one on its edge, to the right of its middle, whose drag sets `radius`.
  - Each property that its type marks with `handles` (6.2) has one at its point, or at each of a list's points, as a polygon's corners, a line's points and a script's patrol path have. A list's points are joined by a thin line in their order. A double click adds a point: between the two neighbouring points whose line is under the pointer, or after the last, which closes a polygon between its last corner and its first. Delete removes the point clicked last.
  - A handle is placed in its node's space, so it follows the node's place, angle and scale. A point and an edge snap to the grid in that space, and a radius in the grid's steps. The preview draws each step (12.2), and the release is one change of the history.
  - With more than one node chosen, the tool shows no handles. A click on a node chooses it as the other tools do, but a click on empty space keeps the choice, so a double click beside the shape adds a point there.
- The wheel zooms around the pointer. A drag with the middle button, or with Alt, moves the view. F fits the view to the chosen nodes, or to every node when none is chosen, as Unity's F does; F in the node hierarchy fits the view of the file that the hierarchy shows.
- The eye and the lock, as Unity's: each row of the node hierarchy ends with an eye and a lock, which a click turns for that node alone, and chooses nothing (OpenECS-std's tree marks, drawn as its icons: a closed eye for a hidden node and a shut lock for a locked one, in the accent colour, and an open eye and lock, dimmed, otherwise); H hides the chosen nodes in the node view, and L locks them there, and the keys again take the marks off; with many chosen, a key marks them all unless each has the mark already. A hidden node draws nothing in the view, nor its outline, and the nodes under it are hidden too; a locked node, and those under it, draw as always. Neither is chosen by a click or a rectangle in the view, so a background can be left alone while the user works on what is in front of it; the node hierarchy still chooses them. The marks are the editor's, not the game's: they are settings of the project, kept in `.onlr/editor.lua` by the node file and the node's path, so a node file stays as it was, and the game runs and exports every node. The limits, as they are now:
  - A node file renamed in the editor, or a node moved to another parent, loses its marks, which name the old path. A deleted node's mark stays in the settings, and names nothing.
- A right click opens a menu, as in the node hierarchy: on a node, which it chooses when it is not chosen, Duplicate, Delete, Copy, Paste, Frame Chosen, Hide in the View and Lock in the View; in empty space, Add Node Here, at the pointer, Paste and Frame All.
- Snapping to a grid is a toggle. It and the grid's size are settings of the project, kept in `.onlr/editor.lua`, a data file. Ctrl held in a drag flips it, as in Unity, and makes a turn go in steps of 15 degrees.
- The node view draws with OpenECS-std's gpu, on a panel's GPU surface (OpenECS-std DESIGN 15). The frame is a texture on the graphics card, which each new frame replaces, and the grid, the outlines, the handles and the messages are gpu's rectangles, lines and text. So drawing the panel copies no pixels, and costs the same at any size. Without a graphics card that gpu can use, the view shows why in place of the nodes.
- The node view draws the window's frame: a rectangle from 0, 0, of the size of the manifest's `window`. So the user sees where the nodes that no camera holds show, such as a score. It is grey, and named above its top left with its size, such as "Window 1920 × 1080", so it is told from a camera's frame. A camera's frame shows what the camera shows of the world under its node when the game runs; the window's frame shows where nodes outside any camera draw on the screen.
- Dragging an image from the files panel into the node view makes a node with a sprite of it, and dragging a node file makes an instance of it (9). An image from another application is copied into the project first, as a file's row does (13.4).
- The editor does not tell a level from a coin. Any node file can be the start node and can be held in another (5, 9), so the manifest's start node is chosen from every node file.

### 13.4 The node hierarchy and the inspector

- The node hierarchy shows the tree of the node file whose view has the focus, from its first node. It keeps its rows until the tree, the open nodes, the marks or the search change, makes them only for open nodes, and builds those in view (13.1). An instance's node shows its base's name after its own, and it and every node of its base are in the accent colour; a node turned off is dimmed, and one with an error is in the theme's `error` colour (OpenECS DESIGN 12.4), which the node view's outlines and the inspector's messages share, so they read in the dark theme and the light one alike. Only the move tool's red and green arrows stay the same in every theme, as Unity's do. A node hidden in the node view is dimmed too, and the row's Hide and Lock at its end show its marks in the accent colour while on (13.3). A search above the tree, OpenECS-std's `ui.search`, shows only the nodes whose name holds each word of its text, as every search of the tool matches (`ui.matches`), and those above them, opened; `t:` and words shows those with a component whose type's name holds them, as Unity's search does. Ctrl+F gives it the keys.
- A right click on a node opens its menu, about the chosen nodes, and chooses the node first when it is not chosen, as a file manager does: Add Child, Rename, Duplicate, Delete, Hide in the View and Lock in the View (13.3), the moves up, down, out of its parent and into the node above, Save as Node File, and on an instance Open Base, as the inspector's button does. Beside the nodes, the menu adds a node, and makes a new variant of the file. A new node file is named after the node or the file, in `nodes/`, with a number when the name is taken; the user renames it in the files panel. The menu takes the place of the panel's rows of buttons. Rename, and F2 as in Unity, asks for the chosen node's new name in a field above the tree.
- The inspector shows the chosen node's own fields (5): its name, its place, its `z` and whether it is active. Then it shows each of its components as a section under its type's name, which a click on the heading folds. A property that is a group or a list, such as a polygon's points, is a section of its own inside it, which folds the same way; Add ends a list. What is folded is kept in the session, by the type and the property, such as `onlr.shape:points`, so it stays folded for every node. A right click on a component opens its menu: Open Script, first, opens its type's script in the code editor that OpenECS-std's setting `console.editor` names, as the console's links do, also for a package's type; Copy Values keeps the chosen node's values of it, Paste Values gives them to the chosen nodes' component of the same type as one change, and Remove Component removes it, as Unity's menu does. Move Up and Move Down, below Open Script, move it in the nodes' order (5), each as one change that writes each node's whole `componentOrder`, or none when the order is what it would be without one; on an instance, Put Back the Base's Order drops the change of it. The sections show in the first chosen node's order. Components are not dragged yet. Below the components, Add Component offers the project's types that the chosen nodes lack, in a dropdown whose folders are the parts of their names, as Unity's groups are: `onlr`, then `camera`, then `view`, one folder for each package, and a project's own script, such as `player`, at the top. A folder opens in place, below a row that goes back; typing searches every folder (OpenECS-std's `ui.dropdown` with `folders`). Its first row turns it on and off, and it has one row for each property after that, apart from each other by the gap between the node's own rows: its `label`, or else its name in words, `cellSize` as "Cell size", and the control of its kind (6.2). A number with both `min` and `max` shows a slider beside its field, as Unity's Range does, and a drag of it is one change, at the release. A colour shows its four numbers and a swatch, whose click opens a picker.
- The inspector's Lock, beside the node's name, keeps the nodes that it shows while other nodes are chosen, as Unity's lock does: so a node's reference is set by dragging another node from the node hierarchy, which would otherwise choose it. A locked inspector shows its nodes also while a file is chosen in the files panel and while the game plays, and names their node file when another node view has the focus. Each inspector panel has its own lock, kept in the session, so a second inspector, opened from the panels list, can stay on one node beside one that follows the choice. The limits, as they are now: a locked node file that is renamed in the editor, or a deleted node, shows that it is gone, and the user turns the lock off.
- A typed value is taken at Return. The inspector shows a node's angle in degrees, and every property that its type marks as an `angle` (6.2), with its `min` and `max`; the file keeps radians, as LÖVE does, and the field's tooltip says so.
- A node dragged in the node hierarchy moves before, into or after the node that it lands on, by where on that node's row: its upper quarter, its middle or its lower quarter, as ui's tree tells (OpenECS-std DESIGN 5). The chosen nodes move together when the dragged node is one of them, and the move is one change of the history. While a node is dragged, the tree marks where it lands, and its `onDragOver` refuses a landing on the moving nodes or inside them, or a node of another node file, so no mark shows there and a drop there does nothing. A node file or an image dropped from the files panel on a node becomes its child, as a drop in the node view makes it (13.3).
- In the node hierarchy, a double click on a node, a second click within 0.4 seconds, opens or closes it, as the files panel's does (13.7).
- In the node hierarchy, a click chooses a node alone. A click with Ctrl adds a node to the chosen ones, or takes it out, and a click with Shift chooses every shown node from the last node clicked alone or with Ctrl to the clicked one, as a system's file manager does. The node view and the inspector follow the same choice. Ctrl+A chooses every node of the file, and Shift+A adds every node under the chosen ones, so a group moves, hides or is deleted as one; both are in the right-click menus of the node hierarchy and the node view, and work in both. In the node hierarchy, a field being edited, the search or a rename, takes Ctrl+A to select its text first, so the panel handles the key itself after its fields rather than with a binding, which would win over them. Shift+A does not open the tree's nodes that it chooses: a chosen node under a closed one shows in the node view and the inspector, not in the tree.
- With many nodes chosen, the inspector shows the fields and the components that all of them have. A value that differs among them shows empty, and a change sets it on all of them, as one change of the history.
- A reference (6.2) is set by dragging onto its row what it names: a file from the files panel, or a node from the node hierarchy or the node view. A node must be one of the node file of the inspector's nodes, also while the inspector is locked on them and another file has the focus; a node file, one of the project's `nodes/`; and a file, one of the endings that the row takes. The console says why a drop is refused. A value is typed or chosen with its control, and is not dragged in the node view.
- A node's or a component's row also has Pick, as Unity's round button: after it, the next click on a node, in a node view or in the node hierarchy, sets the reference, and does not choose the node, so the inspector keeps showing what it showed. The node view says that it waits, in a line at its bottom, and the row says so in place of its value; the row's Cancel, Escape in any panel of ONLR's, or a click beside the nodes in the view ends the pick, setting nothing. Escape is bound for the plugin's panels together, `onlr` as the scope (OpenECS DESIGN 7.8), so it ends the pick wherever the focus went while it waits; a field that takes typing keeps its own Escape. A node of another node file, or for a component's reference a node without the type, sets nothing, and the console says why.
- A file's row is also a field of its path, from the project's folder, with a button that chooses the file in the system's dialog, which shows the endings that LÖVE reads for its kind, or the property's `extensions`. A game reads only its own folder (3.1), so a file from outside the project, chosen in the dialog, typed, or dropped on a row, the node view or the node hierarchy, is copied into it first. The editor asks, naming where it goes: into a folder by its kind, `images/` for an image, `sounds/` for a sound and `fonts/` for a font, made when it is missing, and the project's top folder for any other. When a file of that name is there with the same bytes, it is used and nothing is copied; with other bytes, the copy gets a number before its ending, `gem 2.png`. A user who declines keeps the value as it was. The copy is not in the history: the user deletes it in the files panel.
- A type or a property that the editor does not find, such as after a script was renamed outside the editor, shows in the inspector as the node file writes it. The user can give its values to another type or property. Until then they are kept (4.2).
- The types that adding a component offers are the files of the project's `components/` and `ira-scripts/` (3.1), and of the `components/` of the engine and of each package (11.2). A script and a graph show alike.
- Duplicating or pasting nodes gives the copies new ids. A property of a copy that names another node of the copies names that node's copy; one that names a node outside them is kept.
- A new script starts from ONLR's template: the type's table, empty functions for `load`, `update` and `draw`, and `return`.

### 13.5 Instances

- The node hierarchy shows an instance's nodes, from its base, marked as an instance's. A change to one of them, from any panel, is written as a change of the instance (9).
- The inspector marks every value that an instance's change sets. A click on the mark puts back the base's value, and takes it out of the change.
- Open Base opens the base's node file in a node view.
- An instance whose base does not load, such as after its node file was deleted, is a node with an error, in the `error` colour in the node hierarchy, without children; the rest of the file still works. Its own values cannot be changed, since its changes are keyed by the base's ids. The user deletes it, or gives its base back, which gives the instance back.
- A node that comes from the base cannot be deleted or moved in the instance, since an instance removes nothing (9). The editor offers to turn it off instead.
- Save as Node File writes the chosen node, with all under it, to a new node file, and puts an instance of it in its place, as one change of the history. A property of the old file that named one of those nodes names it through the instance (9). A property among them that named a node outside them is left out of the new file, and set by a change of the instance, which names the old file's node. Undoing it puts the nodes back, and leaves the new file.
- New Variant makes a node file whose first node is an instance of the chosen node file (9).

### 13.6 Changes and saving

- Each change of a node file or of the manifest is a record that can be undone. The project has one history, OpenECS-std's history named `onlr` (OpenECS-std DESIGN 34), which `project.lua` opens with the project and closes with it. One history, not one for each file, as one record can change many files, and Ctrl+Z takes back the last thing that the user did, whichever file it changed. `project.lua` pushes each record with its undo and its redo, and the paths of the files that it changed as its tags. A record holds each file's text before and after, as the editor writes it, which the change wrote already, and undo reads the text back and keeps it as the file's text, since it is what the editor writes for that table: Lua keeps one copy of a text, however many records hold it. The editor writes a file's text into one `string.buffer`, with the keys' order and the indents kept, so `samples/speed`'s 5000 nodes are written in about 17 ms. One record can change many files, such as a deleted node and the properties that named it.
- Changes of the same field or property of the same nodes, or of the same field of the manifest, that come within `history.mergeTime` of each other, 1 second by default, are one record, with the key of the file, the nodes and the field: so names typed one after another in the inspector are undone at once. Changes that end the same as they began stay a record, which changes nothing.
- The project's history is the tool's default (OpenECS-std DESIGN 34), so Ctrl+Z, Ctrl+Y and Ctrl+Shift+Z, which OpenECS's core binds, act on it in every panel, OpenECS-std's console, files and viewer too, and so do Undo and Redo in the Edit menu and the Action bar. A record pushed while an undo runs is refused, so an undo makes no record, also when it chooses nodes or opens a view.
- The history keeps at most `history.limit` records, 1000 by default, the choices among them; a push past it drops the oldest. An undo or a redo that fails clears the history, as its records may no longer match the files (OpenECS-std DESIGN 34).
- Choosing nodes is a record of the same history, between the records of changes, as in Unity. So one key walks back through everything that the user did, and undo gives the nodes that were chosen before back. A record of choosing never marks a file as unsaved. Nodes that the editor chooses right after a change, such as the copy that Duplicate makes, belong to the change's record, so one undo takes back both. A view that gets the focus chooses its own nodes again, which is no record.
- Deleting a node, with all under it, also clears every property that names one of those nodes or one of their components, and drops every change of an instance that names one of them, in every node file of the project, in the same record. Removing a component clears the properties that name it in the same way. So no file names a node that is gone.
- When the editor reads a file that names a node that does not exist, such as after a merge in git, the inspector marks the property or the change, and offers to clear it (9).
- Undoing or redoing a change of a file that no node view shows opens a view of it.
- OpenECS-std's History panel, `history.list`, a tab beside the console in the preset, lists every record, the changes and the choices, as Unity's Undo History does: each by its label, such as Move or Choose, and its tags, the files that it changed. Its first row is the state before every record, and the records after the last one done are dimmed. A click on a row undoes or redoes until that record is the last one done, as many undos or redos would. The history lasts until the project closes.
- A node file with changes marks its panel as unsaved, so OpenECS asks before it closes (OpenECS DESIGN 4.5). The marks are ONLR's, as OpenECS-std's history keeps no point of a save: a file is unsaved while its text differs from what the editor last wrote or read on disk, so an undo past a save marks it again, and an undo or a redo back to the saved text takes the mark away. A file that no view shows keeps its changes until the next save, and the editor asks about them before it closes the project.
- When a file goes back to what is on disk, because the user does not save its changes, or keeps a change made outside the editor, every record that changed it is taken out of the history, by its tag, with `history.drop`. So is every record of a file that a rename or a move changes, the files that name the renamed one too (13.7), since the rename itself is not in the history.
- Play saves every node file with changes, and the manifest, before it starts the game (12.1). So the game that plays is the project's files, and the game is sent none. One game plays at a time: Play while a game plays stops it first.
- A file of the project that changes on disk is read again. When the editor's copy has unsaved changes too, the editor asks which to keep. So it does when such a file is deleted on disk: the editor's changes, which the next save writes as a new file, or none. Kept changes are unsaved against the new text, and when a person wrote that text, the save asks first (4.2).
- The editor watches the project's folder and the folders in it with OpenECS-std's `fs`, with one recursive watch (OpenECS-std DESIGN 10). It follows a folder that is made, moved in, or removed and made again, as git does when it changes branches, and the files that such a folder holds already come as added, so they are read. What starts with a dot is not watched: `.onlr/` is the editor's own, and `.git/` is git's. The editor reads the changes 0.05 seconds after the first that the watch gives, so the changes of one write, or of a branch that git changes, are read together; fs reads them ten times a second, so a change on disk shows in the editor within about a fifth of a second. A watch that lost changes, an overflow, reads the files of its folder and of the folders in it again. A folder that cannot be watched, such as when the system's limit of watches is reached, is said in the console, and the editor does not see its changes.
- A node view of a file that is renamed follows it, and one of a file that is gone shows no file.

### 13.7 Files

- The files panel shows the project's folder, apart from what starts with a dot, as a tree or as a grid of icons, in which an image shows as a small picture, and a node file and a component's script have badges of their own. Its right click's menu makes folders, scripts and node files, renames and moves them, and deletes them after asking (OpenECS-std DESIGN 29). Files dropped on it go into the folder under the pointer: a file of the project moves there, as a rename does, and a file from another application is copied there, without asking, since the user chose the folder. The question names the node files that name the file. A deleted file goes to the system's trash, or to `.onlr/trash/` when the system has none.
- A click on a file chooses it and shows it without opening it: in the asset viewer, when one is open, and in the inspector, which shows its name, its kind, its size and a node file's count of nodes, until nodes are chosen. A double click, a second click within 0.4 seconds, opens it: a node file in a node view, an ira-script or an ira-shader in a graph panel (13.9), a script or a GLSL file in the user's code editor, and any other file in the asset viewer. The right click's menu makes an ira-script in `ira-scripts/` and an ira-shader in `ira-shaders/` too.
- The files panel follows what is chosen, as Unity's Project window does: when nodes are chosen, it chooses their node file, or the base of a chosen instance, and opens the folders above it; and what the search opens (13.8) it chooses too. It does so with OpenECS-std's `files.reveal`, which does not run the editor's `choose`, so the inspector keeps the nodes. Its Lock keeps it where it is, so the user can keep a folder open while choosing nodes, and drag its files onto them. Each files panel has its own lock, kept in the session.
- Renaming, moving and deleting files are not in the history. Before a rename or a move, the editor saves every file with changes. Then it renames the file, changes every path and type name that names it, in every node file and in the manifest, and saves them. The user undoes it by renaming or moving the file back, and gets a deleted file back from the system's trash.

### 13.8 Search

- Ctrl+K, Unity's key for its search, opens the Search panel from any panel, or gives the open one the focus, with the keys in its field. The preset binds it for the whole tool, to `onlr.search`.
- It finds, by `ui.matches` of each item's name, place and kind:

  | Kind     | What                                                                 | Return                                                       |
  | -------- | -------------------------------------------------------------------- | ------------------------------------------------------------ |
  | Node     | Each node that a node file writes itself, by its name, with its file. A node of an instance is found in its base's file. | Opens the file in a node view, and chooses the node. |
  | Function | Each function that the project's own scripts define, `function Player:jump(` and `local function step(`, with its file and line. | Opens the file at the line in the code editor. |
  | File     | Each file of the project, apart from what starts with a dot.          | Opens it as a double click in the files panel does (13.7).   |
  | Type     | Each component type of the project, of the engine and of the packages. | Opens its script in the code editor.                         |
  | Command  | Each function of the editor that a key can run, by its description, as Unity's search finds its menus' items. | Runs it, on the panel that had the focus before the search. |

- Up and Down choose a result, and Return or a double click opens it. It shows the first 200 results. It reads the project again when the project changes, opens or closes.
- The limits, as they are now: a function written another way, such as `Player.jump = function(`, is not found; the engine's and the packages' functions are not searched, as the project holds copies of them; and nothing is found inside a file's text, as a code editor finds it.

### 13.9 The graph panel

``` text
┌ Graph: ira-shaders/water.lua ──────────────────────────────────────┐
│ [Copy as GLSL]                                                     │
│ Properties     ┌ uv ────┐   ┌ sin ───┐   ┌ output ─┐  ┌ Preview ─┐ │
│  speed  2.0    │      ● │───│ ●    ● │───│ ● color │  │ ░▒▓▒░▒▓▒ │ │
│  [+]           └────────┘   └────────┘   └─────────┘  │ [Image ▾]│ │
│                                                       └──────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

- A graph panel shows one graph (6.8), as a node view shows one node file. Many can be open, each a panel of its own. The graph's folder says its kind, so one panel type serves both: an ira-script's blocks in `ira-scripts/`, and an ira-shader's, with a preview, in `ira-shaders/`.
- It draws on a GPU surface, with ui's element of blocks and wires (OpenECS-std DESIGN 5), so moving the view and zooming stay smooth. A block is ui's elements: its title, its pins, and a field of ui for each input that no wire feeds, such as a number field, a toggle or a colour.
- A pin shows its kind: a flow pin is a triangle, and a value pin a dot, in a colour for each kind of value. A wire has its output's colour.
- A right click on empty space opens the list of blocks, in folders by their families, with a search, as Add Component's list does (13.4), and adds the chosen one at the pointer. A wire dragged from a pin and dropped on empty space opens the same list with only the blocks that it can join, and joins the new one.
- A drag from a pin to a pin joins them, when their kinds can meet. A wire to an input that has one replaces it, as a flow output's does. A right click on a pin, or Alt with a click on it, takes its wires off.
- Choosing and moving are the node view's (13.3): a click chooses a block, Shift adds to the choice, a drag from empty space chooses every block in its rectangle, and a drag on a block moves the chosen ones. The wheel zooms around the pointer, a drag with the middle button, or with Alt, moves the view, and F fits it to the chosen blocks. Delete, Copy, Paste and Duplicate are the node view's too, on their keys; copies get new ids, and wires between copies join the copies.
- A list at the panel's left holds the graph's properties (6.8): each one's name, kind and default, and its options in a row that opens below it. Its button adds one. A property dragged into the panel makes a block that gets it, and with Alt one that sets it, as Unreal's variables do. An ira-script's list holds its `needs` below them.
- Every change is a record of the project's history (13.6). A graph with changes marks its panel as unsaved, and Play saves it with the node files. The editor sends the graph as it holds it to the preview (12.2), so the node views show an ira-shader's changes before it is saved.
- Copy as Lua Script, on an ira-script, and Copy as GLSL, on an ira-shader, ask for a new file's name: a script in `components/`, or a `.glsl` file beside the graph. They write the graph's built code there (6.8), which the user then owns. The graph stays as it was, and the two are not kept in step.
- An ira-shader shows a preview at the panel's right: the shader on a picture, which is a checker until the user chooses an image of the project in its dropdown. The preview draws it, as the game would (12.2), and the panel shows its frames as a node view does (12.4). While the panel shows and the shader uses `time`, the preview draws it 30 times a second, as it does for `updateEditor` (6.5).
- A block that an error names (6.8), when the graph is built or while the game runs, shows red, with the error as its tooltip, until the graph changes or the game plays again.

## 14. Export

### 14.1 The `.love` file

- A `.love` file is a zip archive of the project's folder, with `main.lua` at its root.
- The user chooses the folder that an export is written to, and the editor keeps it for the project in `.onlr/editor.lua`. A path that starts at no root is in the project's folder, and `./out`, `out` and `out/` name one folder. A folder inside the project is left out of every export, as `exclude`'s files are. The project's own folder is refused, since each export would hold the ones before it.
- The file is named after the game: `My game.love`. A pattern of `exclude` names a path from the project's folder (3.2).
- It leaves out every file and folder whose name starts with a dot, such as `.onlr/` and `.luarc.json`, and what `exclude` in the project's manifest names.
- It holds every other file, as it is. The editor does not leave out a file that no node file names, since a script may name it in a text. Scripts stay source: LuaJIT's bytecode is tied to its version.
- The licences travel with their parts: the engine's is in `packages/onlr/`, and a library's is in the library's folder.

### 14.2 Builds

A build is made from the `.love` file and LÖVE's runtime for the platform (15.2), by copying and joining files. It runs no tool of the target's platform.

| Target        | The build                                                                                                         |
| ------------- | ----------------------------------------------------------------------------------------------------------------- |
| Linux x86_64  | LÖVE's files, with the `.love` file joined to the end of LÖVE's executable, in a `.tar.gz` archive that keeps the files' permissions. A launcher named after the game starts it: the launcher of LÖVE's AppImage, which tells LÖVE where its libraries are. |
| Windows x86_64 | `love.exe` with the `.love` file joined to its end, named after the game, beside LÖVE's libraries, in a zip archive. |

- LÖVE runs a `.love` file that is joined to the end of its executable.
- A Windows build keeps LÖVE's icon and details.
- A build holds LÖVE's `license.txt`, which lists the licences of LÖVE and of the libraries inside it.
- A build's archive holds one folder, named after the game, and is named after the game and the target: `My game-linux-x86_64.tar.gz` and `My game-windows-x86_64.zip`.
- A build writes the `.love` file first, into the same folder.

## 15. LÖVE

### 15.1 Version

- ONLR is made for LÖVE 11.5, and a project names the version it is made for (3.2). Each version of ONLR serves one version of LÖVE. When a project names another, the editor offers to move it to ONLR's, as it does for the engine (3.3).
- The engine avoids the functions that LÖVE's development version, 12.0, removes or renames, so the move to it stays small.
- The limit, as it is now: the editor does not offer the move yet. A project that names another version opens and runs on ONLR's LÖVE as it is, and LÖVE warns at its start that the game was made for another version, since the engine gives it `loveVersion` as `t.version`.

### 15.2 Runtimes

- A runtime is LÖVE for one version and one platform, as files in a folder.
- ONLR's archive holds the runtime of the editor's own platform, which the runners run. On Linux it is the contents of LÖVE's AppImage, unpacked, so it runs without the system's AppImage support.
- The runtime of another platform is downloaded at the first export for it: from LÖVE's releases, and for Linux from ONLR, which hosts the AppImage's contents as a `.tar.gz`, since only Linux unpacks an AppImage. The editor checks the downloaded file against the SHA-256 hash that ONLR ships for it, before it uses anything of it, and keeps the runtime in the user's data folder, by version and platform: `onlr/runtimes/11.5/windows-x86_64/love/`.
- A download is unpacked by its format, a `.zip` or a `.tar.gz`, into `unpacking/` beside `love/`, and renamed to `love/` when it holds LÖVE, so `love/` is always a whole runtime: an unpack that was cut short, by a crash or a full disk, leaves only `unpacking/`, which the next download takes away. The downloaded archive is removed once it is unpacked.
- A platform's runtime is downloaded once at a time: an export that asks for it while it downloads waits for the same download.
- The variable `ONLR_RUNTIMES` names a Lua file that returns what ONLR knows of the runtimes in place of what it ships: for each platform, the address, the file's name, its SHA-256 hash and the folder inside it that holds LÖVE, as `runtimes.KNOWN` in `plugins/onlr/runtimes.lua` writes them. The editor reads the file at each export, so a test can write it after the editor starts. It is for the tests (16), which serve runtimes of their own, and for trying a runtime before ONLR ships its hash; a user never needs it.
- A setting names a folder to use as a runtime instead, such as a LÖVE the user built: `onlr.linuxRuntime` and `onlr.windowsRuntime`.
- The runners run the LÖVE that the setting `onlr.love` names, or else the one that the variable `LOVE` names, as the tests set it, or else the one of ONLR's archive (15.3), or else `love`, as the system finds it.
- When the runners' LÖVE is a runtime of the editor's own platform, as the archive's is, a build for that platform uses it, and downloads nothing.
- The limits, as they are now:
  - Nothing hosts the Linux runtime yet, so ONLR has no address for it. A Linux build takes LÖVE from the runners' LÖVE when it is the contents of LÖVE's AppImage, as the archive's is, or from the folder that `onlr.linuxRuntime` names.
  - A runtime unpacked from a `.tar.gz` keeps no file's executable mark, so it cannot run as it is. The Linux build marks LÖVE's files itself (14.2), so it needs none; the runners never run a downloaded runtime.

### 15.3 ONLR's archive

- ONLR ships as one archive for each platform, which the user unpacks anywhere: `onlr-0.1.0-linux-x86_64.tar.gz` and `onlr-0.1.0-windows-x86_64.zip`. Nothing is installed (OVERVIEW 2).
- It holds the repository's own layout, so the plugin finds what it needs where it does in the repository: `plugins/onlr/`, `packages/` with the engine, `preset.lua`, LÖVE's definitions in `dependencies/love2d/library/` (4.3), and `LICENSE.md`. Beside them:
  | Folder or file      | What it holds                                                                                                    |
  | ------------------- | ---------------------------------------------------------------------------------------------------------------- |
  | `OpenECS/`          | OpenECS's release for the platform, unchanged, with its standard plugins.                                        |
  | `love/`             | LÖVE 11.5, unchanged: on Linux the AppImage's contents, which run through `AppRun` without the system's AppImage support; on Windows LÖVE's own folder. |
  | `gallery/`          | `samples/gallery` with its packages and without its test: a project to open first (16).                          |
  | `ONLR`, `ONLR.cmd`  | The program that starts the editor: OpenECS with `--preset` naming the archive's preset, and what it is given. `ONLR gallery` opens the gallery, and `--install` adds ONLR to the system's launcher (OpenECS DESIGN 13.9). |
  | `README.md`         | How to start it.                                                                                                 |
  | `GUIDE.md`          | The user's guide as it is at the release, with `OVERVIEW.md` and `DESIGN.md`, which it links to (17).            |
- On Windows, `ONLR.cmd` is a command file, so a console window shows for a moment when it starts. A shortcut that `--install` makes starts OpenECS without it.
- `.github/scripts/package.sh` makes an archive: it downloads OpenECS's release and LÖVE's, checks each against its SHA-256 hash, and lays them out with ONLR's files. It runs on Linux for both platforms, since only Linux unpacks LÖVE's AppImage.


## 16. Tests

- The samples are the tests. A sample is a small project that shows one part of ONLR. It has a test of the engine, a test of the editor, or both.
- A sample's test of the engine runs the sample in LÖVE with the offscreen driver; the sample checks itself and ends with a status.
- That test is the sample's `test.lua`, a plain module that the sample's `main.lua` loads when LÖVE gets the argument `--test`. It runs beside the game, a frame at a time, checks the game through the engine's functions, and quits with status 0 when every check passed.
- ONLR is built and tested with [shuild](https://github.com/omerfuyar/shuild), as OpenECS is: `shuild.c` is the build script. ONLR has no C code, so the script compiles nothing. It copies the repository's packages into every sample's `packages/`, as a project holds them (3.1), so LÖVE runs a sample as it is: the engine into each, and the packages that a sample uses, which the script's one list, `SAMPLE_PACKAGES`, names for it, such as bump for `samples/coinrun`. With `--test` it runs the samples' tests, one at a time, and prints pass or FAIL for each with the seconds that it took, into `build/tests/tests.log`; the checks list those times, the slowest first, in the run's log and summary. With `--editor` it starts the editor. The script is laid out as OpenECS's is, so a person who reads one reads the other: its settings in one `CONFIG`, grouped, and `main` first. It turns on none of shuild's choices for compiling, such as `SHUC_ENABLE_INCREMENTAL`, since it compiles only itself.
- The tests share one helper, `samples/check.lua`, which the script puts into each sample's `packages/` too. The repository does not keep those copies.
- The editor runs on OpenECS's `dev`, built and laid out as a release in the repository's `OpenECS/`, which git ignores, as the checks lay it out; OpenECS is not a submodule. ONLR uses what OpenECS's and OpenECS-std's `dev` hold as soon as it is merged there, and waits for no release of OpenECS: a release of ONLR names the release of OpenECS that it holds (17).
- The checks build OpenECS's `dev`, or, on a pull request, OpenECS's branch of the same name when there is one, so a change that spans OpenECS and ONLR is checked before OpenECS's pull request merges. A change of documents alone, the `.md` files of the root, `.claude/` and `.github/`, skips them; a run by hand runs them all.
- The runner and the link have a sample of their own, `samples/link`, which is no project: a plain LÖVE program that listens as the editor does, starts both runners on other samples, and speaks the link with them.
- A sample's test of the editor is its `editortest.lua`, an OpenECS test (OpenECS DESIGN 17.5): it opens the sample, acts as a user would, and checks the files that the editor writes. It runs on a copy of the sample, since it writes the sample's files. The copy leaves out the sample's `.onlr/`, which the editor kept for it on this computer, such as snapping.
- `samples/editor` is a project as the editor writes one, so its test checks that a change and its undo give the first text again.
- The editor's test waits for what it checks, not for a fixed time. After a change on disk, or a question to the preview, it looks again every 0.05 seconds until the check holds, up to a limit of seconds (`waitUntil`), so a fast computer goes on at once and a slow one gets longer. A save is done when Ctrl+S is handled, so it needs no wait. A fixed wait stays where nothing shows that the editor has read a change, such as a file put back as the editor holds it, half a second, more than twice what the watch takes (13.6); where the check is that nothing happened, such as a node file that tries to change the editor's strings; and after the clicks and keys that a timer of the editor follows, such as two clicks kept apart so they are no double click. On the owner's computer, with OpenECS's Debug build, it takes about 76 seconds, the middle of three runs, from 107 when it waited fixed times.
- The tests run with the user's folders of data, settings and state in `build/tests/home/` (`XDG_DATA_HOME`, `XDG_CONFIG_HOME` and `XDG_STATE_HOME`), so they read nothing that this computer keeps, such as ONLR's runtimes or OpenECS's settings, and write nothing there. The editor's test downloads no runtime from LÖVE's releases, so it needs no network: it makes small runtimes that hold files of LÖVE's names, a `.zip` for Windows and a `.tar.gz` for Linux, serves them from this computer with Python's `http.server`, and writes the file that `ONLR_RUNTIMES` names, which shuild sets to `build/tests/home/runtimes.lua` (15.2). So it needs `python3`, `zip`, `tar` and `sha256sum`. It checks that two exports for Windows download once, and that an unpack cut short leaves nothing behind. When `LOVE` is LÖVE's unpacked AppImage, as the checks have it, the Linux build takes the runners' LÖVE, and the test runs the build; with another LÖVE, the Linux runtime is downloaded from the test's server and the test checks the build's files. So the checks cover the download of a `.tar.gz` only on a computer whose `LOVE` is not an unpacked AppImage. The test does not check the addresses and hashes that ONLR ships.
- The inspector saves the rectangles of its elements that have ids in its state, as `rects`, such as `aaaaaa:thing:speed` for A's speed, so the editor's test finds a row by its id, not by a place that changes with every new row. ui does not tell how far a panel is scrolled, so the test brings a row up by folding the sections above it.
- `samples/gallery` is the demonstration, not a test of one part: a project of rooms, one node file each in `nodes/rooms/`, that shows what the engine, its packages and the editor do. A bar in its top node goes from room to room, by its buttons or Page Up and Page Down; each room's root has a `room` component with the room's title and what it shows. A significant feature that a game shows goes into the gallery in the same piece of work as the feature: into the room of its part, as the tile map room shows sti's collisions and objects, or a room of its own, a node file whose name orders it among the others, with nothing else to change. A feature of the editor alone, such as a key of the node hierarchy, has no room, since the gallery is a game. Its test only keeps it working: it visits every room, runs it, and checks a few things in each. It has no test of the editor, since an editor test cannot read the preview's nodes.
- One sample has thousands of nodes. It is the measure of speed: its test reports the time of a frame.
- A change that breaks a sample changes the sample in the same piece of work.

## 17. Versions and releases

- ONLR, its editor and its engine share one version, which `preset.lua` and the engine's manifest name (8.3). It is semantic versioning: before 1.0.0, a minor release may break anything, and a patch release only fixes.
- Each release of ONLR holds one release of OpenECS, which the release workflow names, and the version of LÖVE that it serves (15.1). Between releases ONLR works on OpenECS's `dev`, so a release of ONLR waits for a release of OpenECS that holds what `dev` gave it.
- A release is a tag `vMAJOR.MINOR.PATCH`, such as `v0.1.0`, on `main`, which names `preset.lua`'s version. The tag starts `.github/workflows/release.yml`, which makes the archives (15.3) and their checksums, `SHA256SUMS`, and drafts a release whose description is `.github/release-notes/TAG.md`. A version below 1.0.0 is a pre-release. The owner reads the draft, and publishes it.
- The repository's GUIDE.md always describes `dev`. A release ships its own copy, as it is at the release's commit, in its archive (15.3), so the guide that a user of a release reads describes what they have.
- A file's `format` is a number that changes when an older engine or editor cannot read the newer file (4.1). Nothing converts a file of an older format: while ONLR has no users, a new format may break projects.
- `dev` is the default branch, where work is merged. `main` holds what is stable: it changes only through a pull request from `dev`, which the owner merges.

## Glossary

**AppImage.** A way to ship a Linux program as one file. LÖVE's Linux release is one.

**Block.** A step of a graph, such as an event, a branch or an addition, with pins.

**Canvas.** A picture in the graphics card's memory that LÖVE draws into instead of the window.

**Component type.** A Lua file that returns a table with a component's properties and functions.

**Definition.** A LuaLS annotation that tells a code editor a type's fields or a function's parameters.

**Entry.** The table that a node file holds for one node, one component or one change of an instance.

**Frame.** One picture that LÖVE draws: of the game, or of a view.

**Game.** The runner that runs the game when the user plays it: LÖVE's own window, as an exported game.

**GLSL.** The language of shaders that LÖVE compiles on a computer.

**GLSL ES.** GLSL's stricter form, which LÖVE compiles on a phone.

**Graph.** Blocks joined by wires, from which the engine builds code: an ira-script or an ira-shader.

**Ira-script.** A graph that is a component type, in `ira-scripts/`, from which the engine builds Lua.

**Ira-shader.** A graph that is a shader, in `ira-shaders/`, from which the engine builds GLSL.

**Group.** A node that draws with all under it as one, through a component's `drawTree`.

**Library.** Lua code that its author wrote for LÖVE games to use.

**Link.** The connection between the editor and a runner.

**LuaJIT.** The implementation of Lua that LÖVE runs. Its language is Lua 5.1 with additions.

**LuaLS.** The Lua language server, which completes and checks Lua code in code editors.

**LuaSocket.** A Lua library for network connections, which LÖVE ships.

**Metatable.** A table that tells Lua where to look when another table lacks a field.

**Offscreen driver.** A video driver of SDL that opens no window.

**Package.** A library made ready for ONLR: a folder of `packages/` with the library, its components and its node files.

**Pin.** An input or an output of a block, which a wire joins to another's.

**Plugin.** A module that gives OpenECS panels and functions.

**Preset.** The file that tells OpenECS which plugins and panels a tool starts with.

**Preview.** The runner that draws views of node files for the editor's node views, with no window that the user sees.

**Quad.** LÖVE's object for a rectangle of an image, with which LÖVE draws only that part of it.

**Root.** The node that the game runs under the top node, with all that is under it, until a script loads another in its place.

**Runner.** LÖVE, started by the editor on the project: the preview or the game.

**Runtime.** LÖVE for one version and one platform, as files in a folder.

**SDL.** The library through which LÖVE and OpenECS use windows, input and graphics.

**Shader.** A small program that the graphics card runs for each pixel that LÖVE draws, to change its colour.

**Transform.** LÖVE's object for a position, a rotation and a scale together.

**Top node.** The node that the game loads once and keeps, above every root.

**Tree.** The nodes that the game runs: the top node and all under it, the root too.

**Variant.** A node file whose first node is an instance of another node file.

**View.** A node file as the preview draws it: seen from a point, at a zoom and a size.

**Wire.** A line in a graph from one block's output to another's input.
