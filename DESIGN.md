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
- Lua names use camelCase: `onlr.tree.loadRoot`, `startNode`. Files and folders have lowercase names.
- A node's place has short names, since scripts write them most: `posX`, `posY`, `rot`, `sclX` and `sclY`.
- Functions of one kind share a namespace, such as `onlr.tree`. What acts on a node or a component is its method.
- The engine sets no global. A script gets it with `local onlr = require("onlr")`.
- Every public function, type and file format of the engine has LuaLS annotations in the engine's source. They are the definitions that guide a code editor (4.3), so the source and the hints cannot differ.
- A path in a project uses `/` and starts at the project's folder, as LÖVE's paths do: `images/player.png`.
- Angles are radians, colours are tables of red, green, blue and alpha from 0 to 1, and y grows down, as in LÖVE.

## 2. Parts

### 2.1 Layers

A game made with ONLR is built in layers. Each uses only the layers above it in this table:

| Layer              | Is                                                                                              | Written by                      | Uses                           |
| ------------------ | ----------------------------------------------------------------------------------------------- | ------------------------------- | ------------------------------ |
| 1. LÖVE            | The runtime: the window, drawing, sound, input, physics and files.                              | LÖVE's authors                  |                                |
| 2. Libraries       | Lua code for LÖVE games, such as a library for collision (11).                                  | Their authors                   | LÖVE, or nothing               |
| 3. The engine      | Nodes, components, properties and the loop (5 to 9).                                            | ONLR                            | LÖVE                           |
| 4. Components      | What nodes show and do: the engine's own (10), a package's (11.2) and the user's scripts (6).      | ONLR, a package's author, the user | The engine, LÖVE and libraries |
| 5. The game's data | The project's manifest and node files, which name component types and hold their values (3, 4). | The user, through the editor    | Component types, by name       |

- The engine and the libraries do not know each other. A component is where they meet: it is called by the engine, and it calls a library.
- All three kinds of component are the same thing to the engine. The engine's own and a package's can do nothing that a script cannot.
- The editor is not a layer of the game. It is another program: it reads and writes the game's data, and asks the player (12) what the components declare and how the nodes look.

### 2.2 In this repository

| Part           | In this repository       | Is                                                                                                              | Runs in |
| -------------- | ------------------------ | --------------------------------------------------------------------------------------------------------------- | ------- |
| Engine         | `engine/`                | The Lua library that every project holds a copy of, as `packages/onlr/`.                                        | LÖVE    |
| Player's files | `player/`                | The Lua code that the engine loads when the editor starts it: the link and the views (12). No project holds it. | LÖVE    |
| Editor         | `plugins/`, `preset.lua` | OpenECS plugins and their preset (13).                                                                          | OpenECS |
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
- `shared/` holds the user's Lua code that is not a component and that components share: what keeps a value when the root changes, such as a score, and functions that many scripts use. The engine does not read it: scripts load it with `require`, as in any LÖVE game. Its name is not taken; a new project has it.
- `packages/` holds what the game uses and was not made for this game alone, each in a folder of its own: the engine in `packages/onlr/`, packages, and libraries. The user adds to it, by hand or in the editor.
- `packages/onlr/` is the engine's. The editor replaces it when it updates the engine (3.3), so the user does not edit it. Each project holds its own copy, so `love mygame` runs it and an export holds it.
- `.onlr/` holds what the editor keeps for this project on this computer, such as LÖVE's definitions (4.3). It is not exported, and not in git: when the editor makes the project, it writes a `.gitignore` that names it.
- The names `main.lua`, `conf.lua`, `manifest.lua`, `components/`, `nodes/`, `packages/` and `.onlr/` are taken. Every other name is the user's.

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
    height = 720,
    width = 1280,
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
| `window`          | The game's window, as LÖVE's `t.window`, with its names: `width` and `height` in pixels, and any other field of it, such as `resizable`, `fullscreen` or `highdpi`. The engine adds none of its own. |
| `modules`, `audio`, `console` and LÖVE's other settings | As in LÖVE's `t`, under LÖVE's names. LÖVE's `identity` is `id`, and its `version` is `loveVersion`. |
| `defaultFilter`   | How images are scaled, as `love.graphics.setDefaultFilter` takes it: `linear`, LÖVE's default, or `nearest`, which keeps pixel art sharp. The engine sets it in both players, before anything loads (12.1). |
| `fixedRate`       | How many times a second `fixedUpdate` is called (6.3). 60 when left out.        |
| `exclude`         | Patterns of files that an export leaves out. In a pattern, `*` stands for any part of a name, `**` for any folders, and a pattern that ends with `/` names a folder. |

- LÖVE's settings are here, and not in `conf.lua`, since two things need them: LÖVE, before it opens the window, and the project settings panel, to show and change them. The editor does not run `conf.lua`, which is the game's code.

### 3.3 Updating the engine

- The editor ships one version of the engine, and works on a project that holds that version. The engine's manifest in `packages/onlr/` names its version (8.3).
- When the editor opens a project that holds another version, it asks the user, then replaces `packages/onlr/`. If the user declines, the project stays closed.

## 4. Data files

### 4.1 Rules

- Every data file that ONLR writes is a Lua file that returns one table: the manifests and the node files.
- The table is plain data: numbers, texts, booleans and tables, and no function.
- The engine and the editor each read a file by running it, with their own Lua: LuaJIT in the game, and the editor's Lua. The file runs with Lua's basic functions and its `string`, `table` and `math` libraries, and nothing else. It cannot reach LÖVE, the engine, the editor or another file.
- The basic functions are those that compute: `assert`, `error`, `getmetatable`, `ipairs`, `next`, `pairs`, `pcall`, `rawequal`, `rawget`, `rawset`, `select`, `setmetatable`, `tonumber`, `tostring`, `type`, `unpack` and `xpcall`. Those that load code or reach outside are left out, such as `require`, `load`, `dofile` and `print`. Each file gets its own copies of the three libraries, so it changes nothing for another file.
- So a file that a person writes may compute its table, such as a manifest that works out the window's size. Its code must be Lua that both run.
- A file's kind is known by its folder, without reading it: a node file is in `nodes/`, as a script is in `components/` (3.1). No file's name has a second ending.
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
  - A whole number from -2^53 to 2^53 without a point, such as `250`. Any other number with the fewest digits that read back as the same number, such as `0.1`, and an endless one as `math.huge`, and one that is no number as `0/0`. So LuaJIT and the editor's Lua read the same value.
  - A text in double quotes, with `\\`, `\"` and `\n`, and every other byte below 32 as three digits, such as `\009`. So both Luas read the same text.
- A value that equals its default is left out, so a file holds only what the user set. In an instance, the value in its base is the default (9).
- A node's `id` is six random characters, lowercase letters and digits, such as `c0in7x`. The editor gives it once. Nodes are named by id wherever one refers to another, never by their place in a list.
- An id is unique in its file, and no further. When a file holds an id twice, such as after a merge in git, the editor gives one of the two nodes a new id, and says so.
- Two changes on neighbouring lines, such as a node's `name` and its `posX`, and two nodes added at the end of one list of children conflict in git, as in any text. A node file with git's marks of a conflict does not load: the node view shows the error, and the user resolves it in a text editor.
- A field or a component type that the editor does not know is kept as it is, and written back. A node's field that section 5 does not name is written after those it names, in the order of the names.
- LuaJIT cannot read a node file of much more than 30,000 nodes. The editor warns well before a file gets there. A tile map is one component, not a node for each tile.

### 4.3 Definitions

- The first line of each file names its type, such as `---@type onlr.NodeFile`, so a code editor with the Lua language server completes and checks its fields.
- The types are in the engine's source, in the project's `packages/onlr/` (1). LÖVE's own definitions, from [LuaCATS/love2d](https://github.com/LuaCATS/love2d), are copied into `.onlr/love2d/`.
- The editor writes `.luarc.json` once, when it makes the project. It names LuaJIT as the Lua version, `.onlr/` as a library, and `packages/` as a place where `require` looks (11.1):

  ``` json
  {
    "runtime.version": "LuaJIT",
    "runtime.path": ["?.lua", "?/init.lua", "packages/?.lua", "packages/?/init.lua"],
    "workspace.library": [".onlr"]
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
| `components`       | Its components, by their types' names (6.1). Each is a table of its properties' values, and of `enabled`, which is true when left out. | |
| `children`         | Its children, nodes too.                                                      |         |

- The game runs one root at a time: a node, with all that is under it, which `onlr.tree.root` gives. The game starts with the manifest's start node (3.2), and `onlr.tree.loadRoot` puts another in its place (7). A level and a coin are node files alike: the game loads the level as its root, and the level holds the coin as an instance (9).
- Above the root is the top node: the node of the node file that the manifest names (3.2), which the game loads once, before the first root, and keeps for the whole game. What outlives the root is under it, such as a music player or a pause menu, and the root runs as its last child. When the manifest names none, the top node is an empty node. While the top node loads, there is no root yet: `onlr.tree.root` is `nil` until the first root loads.
- The top node, with all under it, is the tree. So the tree has one top, and a group on the top node holds the whole game, such as a library that scales the game to the window.
- A script keeps a node of the root when the root changes by moving it under the top node, or under a node of the top node's own (7).
- What a root has one of, such as the world that its bodies collide in, is a component of the root. No node is made only to hold one.
- Nodes update, and get events, in the order of the tree: a parent, then its children, and siblings in the order of their list, so the top node's own nodes before the root. `z` plays no part in it. So what must update before every other node, such as what reads the input for the whole game, is a component of the top node.
- Nodes draw by `z`, the lowest first. A node's z is its own added to its parent's, so a child with a negative `z` draws behind its parent. Nodes of the same z draw in the order of the tree.
- The engine does not order by y. A game seen from above, which draws what is lower on the screen later, sets a node's `z` from its `posY` in a script, and the next draw follows it (6.4).
- A node can draw as a **group**, when one of its components has the function `drawTree(draw)` (6.3). Then the node and all under it draw together, at the node's place in the order of drawing, and by `z` among themselves. The engine calls `drawTree` in place of drawing them, and gives it `draw`, which draws them. So the component sets something up before they draw and ends it after: a camera's view (10), a canvas, a shader, or a library that works in the same way.
- Any node can be a group, at any depth, and a group can hold others. A group's nodes draw nowhere else, whatever their `z`: a child with a `z` of 100 draws over the rest of its group, not over what is outside it.
- `drawTree` may call `draw` more than once, such as once for each half of the window in a game for two players, or not at all. Each call draws the group's nodes once, so a group costs what drawing its nodes that many times costs, and one call costs no more than drawing them without a group.
- A node with two such components draws through both, the first in the order of their names outermost.
- A node's components load, update and draw in the order of their names, and each after those that it needs (6.6). A node does not set another order: what must draw in another order is a child with a `z` of its own.
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
  | A package's         | The package's name, then its path in the package's `components/`: `bump.body`. | `packages/bump/components/body.lua` (11.2) |
  | The engine's own    | `onlr.`, then its path in the engine's `components/`: `onlr.sprite`. | `packages/onlr/components/sprite.lua` (10) |

- The engine looks for a type in the project's `components/` first, then in the packages'. So a script cannot have the name of the engine or of a package, and the editor says so.
- Each part of a type's name is a name in Lua, since a script reads it so: `components.enemies.bat`. The editor makes no file or folder in `components/` whose name is not one, and the engine refuses such a type.
- A node has at most one component of a type. Giving it a second is an error.
- The engine loads a type's file with `require`, under the name that its path gives: `components.player`, or `packages.bump.components.body`. So a script that loads a type's file the same way gets the same table.
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
| `font`                      | A font file of the project and a size.            | A LÖVE font. Without a file, LÖVE's default font at that size. |
| `file`                      | A file of the project, of the endings in `extensions` if given. | Its path.                      |
| `nodeFile`                  | A node file of the project.                       | Its path.                                    |
| `node`                      | A node of the same file.                          | The node.                                    |
| `component`                 | A node of the same file that has a component of the type. | That component.                      |
| `vector`                    | Two number fields in one row.                     | A table with `x` and `y`.                    |
| `group`                     | The properties it holds, under one heading.       | A table with a field for each.               |
| `list`                      | Rows of one kind, which the user adds and removes. | A list of what that kind gives.             |

- A kind is a value or a reference. A value is held in the node file as it is: `bool`, `integer`, `number`, `string`, `choice`, `color`, `vector`, `group` and `list`. A reference names something else of the project: `image`, `sound`, `font`, `file`, `nodeFile`, `node` and `component`.
- `group` and `list` take other properties: `onlr.property.group({ width = onlr.property.number(32), height = onlr.property.number(32) })` is read as `self.box.width`, and `onlr.property.list(onlr.property.image())` as `self.frames[1]`.
- The options:

  | Option        | Taken by                  | Is                                                                                       |
  | ------------- | ------------------------- | ---------------------------------------------------------------------------------------- |
  | `description` | Every kind                | A text that the inspector shows with the property.                                       |
  | `label`       | Every kind                | What the inspector shows in place of the name (13.4).                                      |
  | `min`, `max`  | `integer`, `number`       | The least and the most value. The inspector keeps the value between them; the engine does not check it. |
  | `choices`     | `choice`, which needs it  | The texts to choose from.                                                                |
  | `stream`      | `sound`                   | LÖVE streams the file while it plays, as music needs, in place of decoding it whole when it loads. |
  | `size`        | `font`                    | The size that the property starts with. 12, LÖVE's own, when left out.                    |
  | `extensions`  | `file`                    | The endings of the files that the inspector offers, such as `{ "json", "lua" }`. Every file when left out. |
  | `preload`     | `nodeFile`                | The node file loads with the component's own, so a spawn of it waits for no file (below). |

- An option that the kind does not take, such as a misspelt one, is an error when the type loads.
- A node file keeps a colour as a list of four numbers, and a vector as a table of `x` and `y`. A value of another kind than its property's is an error, as a path that names no file is (below).
- A node file keeps a file as its path, and a font as a table of its `path` and its `size`. It keeps a node, and a component, as the node's id, or as a path of ids when the node is inside an instance (9). When the file loads, the engine gives the component the node or the component itself.
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

- The engine passes on every event that LÖVE has, by its name, so it needs no list of them, and an event of a newer LÖVE reaches scripts too. So a type's function with the name of one of LÖVE's callbacks, such as `focus` or `resize`, is called for that event.
- A type may have more functions of its own, which other components call: `self.node.components.bump.body:move(x, y)`.
- Around each component's `draw`, the engine applies the node's place and takes it off again, and changes nothing else of LÖVE's drawing state, as plain LÖVE code expects to set its own colours. The engine's own components set back what they change, such as the colour. In the node view, all of the state is kept (6.5).

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
- `node:destroy()` marks the node and every node under it, and their `isDestroyed()` is true from then on. The top node and the root are not destroyed so: `onlr.tree.loadRoot` ends the root. They stay in the tree, and their functions are called, until the frame ends. Then the engine calls `disable` and `destroy` of their components and takes them out of the tree. A component that holds another node asks `isDestroyed()` before it uses it.
- `node:removeComponent(type)` does the same to one component: it stays, and its functions are called, until the frame ends. Then the engine calls its `disable` and `destroy` and takes it off the node, and the node can get a component of that type again.
- `onlr.tree.loadRoot` does the same to every node of the root when the frame ends. Then it makes the new root in the old one's place among the top node's children. The top node and its own nodes stay.
- What a function returns is not used. `quit` is the exception: as in LÖVE, the game does not quit when `love.quit` or a component's `quit` returns true.

### 6.5 In the node view

- The node view shows nodes that do not run: no `load`, `update` or event reaches a component.
- There the engine calls `drawEditor` in place of `draw`. A type that looks the same in the editor as in the game says so: `Sprite.drawEditor = Sprite.draw`. The engine's own components do.
- `drawEditor` also draws what only the editor shows, such as the outline of a body or the frame of a camera. It is LÖVE code, written with the component by its author.
- There the engine does not call `drawTree`: a group's nodes draw through the node view alone. So a camera does not move the view, and a group's shader shows only in the game.
- A type without `drawEditor` shows nothing in the node view. Its `draw` is not called there, since it may need what `load` or `update` sets.
- `drawEditor` may keep in `self` what it builds from the component's values, such as a map read from a file. When a value of the component changes, the edit player makes the component anew from the node file's values, so what it kept is built again from the new ones.
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
- A node that gets a component gets those that it needs too, each with its defaults, when the node lacks them: in the editor, when a node file loads, and at `node:addComponent`.
- The editor does not remove a component that another of the node needs, and names the other. `node:removeComponent` of such a component is an error.
- A component loads, updates and draws after those that it needs (5). So its `load` finds them loaded, and `self.node.components.bump.body` is there without a check.
- Types cannot need each other in a circle. The engine refuses such a type, and says so.

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
| The editor draws a view             | `drawEditor` and `bounds`, and nothing else                                       | The node view (6.5, 12.3)                                           |

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
| `node:setParent(parent, index)`                                                                                      | Moves the node, with all that is under it, to the end of another node's children, or to `index` among them. |
| `node:destroy()`, `node:isDestroyed()`                                                                               | Destroys the node and its children when the current frame ends, and says whether it was destroyed.          |
| `node:toWorld(x, y)`, `node:toLocal(x, y)`                                                                           | Turn a point of the node's space into the world's, and back.                                                |
| `node:setWorldPosition(x, y)`                                                                                        | Moves the node to a point of the world, whatever its parents' places are.                                   |
| `component:isEnabled()`, `component:setEnabled(enabled)`                                                             | Whether the component is on (6.4), and turns it on or off.                                                  |

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
- An error is LÖVE's: the game stops and LÖVE's error handler shows it, as in any game. A game may set its own handler, as LÖVE allows.
- In an exported game the loop does this and nothing else. What serves the editor is not in the project: the engine loads it from ONLR's own folder, and only when the editor starts it (12.1).

### 8.2 How the tree is kept

- A node is a Lua table with the fields of section 7. A component is a Lua table of its own values, which finds its type's functions and defaults through a metatable. A script reads and sets their fields as plain fields, and the engine does not watch them.
- What the engine keeps of a node is in fields of the node whose names start with an underscore, which are the engine's. What it keeps of a component is in a record of its own, outside the component, so every field of a component is the script's.
- What changes which functions run, or their order, is not a field: a node's `active`, whether it is paused, its `z`, parent and children, and a component's `enabled`. The engine keeps them, and a script reaches them through functions (7), so the engine knows of each change when it is made.
- All nodes share one metatable, and the components of a type share one, so LuaJIT compiles a script's code once for every component that runs it.
- For each function that a frame calls, the engine keeps one flat list of the tree's components that have that function, in the order of the tree: for `fixedUpdate`, `update` and `lateUpdate`, and for each event from the first time LÖVE sends it. The list of `draw` is in the order of drawing instead, and each group has one of its own (5). A frame walks the list of `update` and the list of `draw`, and an event walks the list of its name. So the engine walks no tree and asks no component what it has while the game runs, and a node costs a frame nothing for what its components do not define.
- The lists change only when a component starts or stops running, when a node is paused or resumed, when a node is moved, or when a `z` changes, at the moments that section 6.4 names. A component that stops is skipped at once. A list that changed is built again from the tree the next time it is walked, so a frame in which nothing changed builds none.
- A node's place is plain fields, which the engine does not watch. It compares them when it uses the node's place in the world: to draw, and in `toWorld`, `toLocal` and `setWorldPosition`. Each node keeps that place as a LÖVE transform, and the engine works it out again only for a node whose place, or whose parent's transform, differs from the one it used last.

### 8.3 The engine's files

Each file of the engine holds one thing:

| In `packages/onlr/`                                 | Holds                                                                                                                                                      |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `manifest.lua`                                      | The engine's name and its version, as a package's manifest holds them (11.2).                                                                              |
| `init.lua`                                          | What `require("onlr")` gives: `start`, `conf`, and the namespaces of the files below. It joins them, sets where `require` looks (3.1), and does nothing else. |
| `loop.lua`                                          | `onlr.loop`: the loop and its steps (8.1).                                                                                                                 |
| `tree.lua`                                          | `onlr.tree`: the root, the tree and its lists (8.2).                                                                                                       |
| `node.lua`                                          | Nodes and their functions (7).                                                                                                                             |
| `component.lua`                                     | Component types (6.1): finding and loading a type's file, and a node's `components`.                                                                       |
| `life.lua`                                          | The life of components (6.4), and the lists that a frame walks (8.2).                                                                                      |
| `build.lua`                                         | Making nodes from node files: instances, their changes and ids (9).                                                                                        |
| `property.lua`                                      | `onlr.property` (6.2), and turning a node file's values into a component's.                                                                                |
| `data.lua`                                          | Reading data files (4), and loading the files that properties name.                                                                                        |
| `formats.lua`                                       | The definitions of the data files' formats (4.3). Only a code editor reads it.                                                                             |
| `components/`                                       | The engine's components (10), one in each file: `sprite.lua`, `text.lua`, `shape.lua` and `camera.lua`.                                                   |
| `license.txt`                                       | The engine's licence, which an export holds (14.1).                                                                                                        |

- The engine is in `packages/` as a package is, with its components in `components/`. So the editor finds the engine's components and a package's in one way. Its source carries its own definitions (4.3), so it needs no definitions file.
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
  | `name`, `posX`, `posY`, `rot`, `sclX`, `sclY`, `z` and `active` | Replaces the same field of the node.                                                         |
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
- `onlr.tree.spawn` makes an instance while the game runs, and calls `load` and `enable` of its components before it returns (6.4).

## 10. The engine's components

The engine has four component types. They are written as scripts are, with the functions of section 7 and LÖVE alone.

| Type          | Is                                                                                                  |
| ------------- | --------------------------------------------------------------------------------------------------- |
| `onlr.sprite` | An image, or a part of one.                                                                         |
| `onlr.text`   | A text in a font.                                                                                   |
| `onlr.shape`  | A rectangle, a circle, a line or a polygon, filled or as an outline.                                |
| `onlr.camera` | A view: it draws its node and all under it as a group (5), moved, turned and zoomed so that the middle of its screen shows its point. |

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
| `onlr.shape`  | `kind`            | `choice` of rectangle, circle, line and polygon | rectangle | The shape.                                                                                     |
|               | `mode`            | `choice` of fill and line                     | fill       | Filled, or as an outline. A line has no mode.                                                    |
|               | `width`, `height` | `number`                                      | 32         | A rectangle's size, from the node's place.                                                       |
|               | `radius`          | `number`                                      | 16         | A circle's, around the node's place.                                                             |
|               | `points`          | `list` of `vector`                            |            | A line's points, or a polygon's corners, in the node's space.                                    |
|               | `lineWidth`       | `number`                                      | 1          | The width of a line and of an outline, as `love.graphics.setLineWidth`.                          |
|               | `color`           | `color`                                       | white      | The shape's colour.                                                                              |
| `onlr.camera` | `posX`, `posY`    | `number`                                      | 0          | The point, in its node's space, that the middle of its screen shows.                             |
|               | `rot`             | `number`                                      | 0          | Its angle, clockwise. What it shows turns the other way.                                         |
|               | `zoom`            | `number`                                      | 1          | How large the camera shows its nodes: 2 is twice as large.                                       |
|               | `width`, `height` | `number`                                      | 0          | The size of its screen, in pixels. 0 is the window's.                                            |

- Each has `bounds` and `drawEditor` (6.3). A camera's `drawEditor` draws the frame of what it shows.

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
  version = "3.1.7",
  source = "https://github.com/kikito/bump.lua",
  license = "MIT",
}
```

- The manifest and `init.lua` stay two files. The editor reads the manifest as any data file (4.1), which cannot load the library. So the manifest describes the package and holds none of its code.
- `library/` holds what the library's author ships. A newer version of the library replaces that folder and nothing else.
- A component type is one file, since its name is its file's (6.1). The names start with the package's: `bump.body` is `packages/bump/components/body.lua`. The types are written as scripts are (6), and the editor offers every one of them (13.4).
- A node file of a package is named by its path, as the project's are: `packages/bump/nodes/box.lua`.
- A package adds nothing to the engine and changes nothing in it. A game uses a package's library with its components, without them, or both.
- The editor copies a package into a project when the user adds it, and deletes its folder when the user removes it. In the project, the package is the project's own copy, and an export holds it.
- The editor adds a package from ONLR's own, or from a folder that the user chooses, so anyone can make one.
- The user does not change a package in the project, as they do not change the engine (3.1). To change one of its components, they copy it into `components/` under another name. When ONLR ships a newer version of a package that a project holds, the editor offers it, and updating replaces the package's folder whole.

### 11.3 A package's components

A package's components show a library in the inspector. The sample is a package for bump, a library that keeps boxes in a world of its own and tells which ones a moving box hits. bump's world is not the tree: it is bump's own list of boxes, and it knows nothing of nodes.

``` lua
-- packages/bump/components/body.lua: a box that collides
local onlr = require("onlr")

---@class bump.body : onlr.Component
local Body = {}

Body.width = onlr.property.number(32)
Body.height = onlr.property.number(32)

function Body:load()
  local world = onlr.tree.findComponent("bump.world") or onlr.tree.root:addComponent("bump.world")
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
- **What the library must be told** is told by the component, in its `enable` and `disable` (6.4). bump asks for each box to be added to its world; the body does that while it runs, so the user does not, and a node that is turned off collides with nothing.
- **Where a node is** has one truth: the node's own place (5). A library that keeps a place of its own, as bump does for each box, holds a copy, and the package's component keeps the copy in step. After `move`, the node takes the library's answer. When a script sets the node's place itself, the component tells the library, in its `update`.
- **What a script asks of the library** is a function of the component: `body:move(x, y)`. The script names the body in `needs` (6.6), so its node always has one.
- **What the library reports** reaches scripts with `node:send`, as a function that the script defines: `contact(other)`. Both nodes of a contact are told.
- **What the editor shows** is `bounds`, for choosing the node, and `drawEditor`, for the outline.

## 12. The player and the link

### 12.1 The player

- The editor starts LÖVE itself, unchanged, as a program of its own on the project's folder. Arguments tell the engine that the editor started it, the mode, where the editor listens, and where the player's files are: `--onlr-player=FOLDER`, `--onlr-mode=edit` or `play`, `--onlr-port=PORT`, and for Play This File `--onlr-start=PATH`.
- The player's files are the Lua code that serves the editor: the link and the views. They are in ONLR's own folder, and no project holds them. The engine loads them with Lua's own `loadfile`, which reads any path, where LÖVE's file functions read only the game's folder (3.1). So a project and its exports hold nothing of the editor, and both ends of the link are of one version of ONLR.
- A player runs in one of two modes:

  | Mode | Runs                                        | Draws into                                     |
  | ---- | ------------------------------------------- | ---------------------------------------------- |
  | Edit | Views: node files drawn and not updated (12.3). | Frames for the node views (12.4).              |
  | Play | The game.                                   | LÖVE's own window.                             |

- The edit player runs while a project is open, and has no window that the user sees.
- LÖVE starts every game by running its `conf.lua` and `main.lua`, so the edit player runs them too, and the code of each script that is outside its functions when the editor asks about the script (12.5). It does not call `love.load`, nor a component's `load` or `update` (6.5). So what both the game and the node view need, such as the default filter, is in the manifest (3.2), and the engine sets it in both players.
- In the edit player, the engine sets LÖVE's volume to 0, so a sound that the game's code plays there is not heard. On Linux the editor starts it with SDL's offscreen video driver, `SDL_VIDEODRIVER=offscreen`, so it opens no window and still draws with the graphics card. On Windows that driver cannot start LÖVE, whose runtime there has no EGL. So there LÖVE opens its window, and the player's files hide it as soon as the engine loads them, with SDL's `SDL_HideWindow` through LuaJIT's FFI. The edit player then draws into canvases, as on Linux.
- Play saves the project (13.6), then starts a second player with the manifest's start node as its first root, as an exported game starts. Play This File does the same with the node file of the node view that has the focus. The top node runs above it (5). When the file in focus is the top node's, Play This File plays as Play does. Stop ends it, and so does closing its window.
- Pause stops the game, and Step runs one frame of it. While it is paused, the engine's loop handles LÖVE's events for LÖVE alone, such as quit, and draws, but calls nothing of steps 2 and 3 of a frame (8.1). Step runs those steps once, with `dt` of one fixed step (3.2), so it runs one `fixedUpdate`. Resume goes on.
- The play player is LÖVE as an exported game runs it: the window, the keyboard, the pointer, the gamepads and the sound are LÖVE's own, and the engine stands in for nothing.
- What a mode draws into is the one difference between the modes. Starting a player, the link, the console and the errors are the same code for both, so the editor's other parts do not know where the game is drawn.
- A player is another program, so a game that fails or never returns leaves the editor running. The editor shows what happened, and starts the player again when asked.
- The editor gives the edit player two seconds for each answer. When it does not answer, as when a `drawEditor` never returns, or the game's code fails before the engine has loaded, the editor ends it, shows in the console what it printed, and starts it again at the next change. When it stops twice in a row, it does not start again until the user asks, with Start the Edit Player Again.
- The editor reads what a player prints, and shows it in the console. In a player, the engine turns off the buffer of the game's output, so each line shows when it is printed.

### 12.2 The link

- The link is a TCP connection on this computer: the editor listens on a free port of `127.0.0.1`, and the engine connects to it with LuaSocket, which LÖVE ships. Each player has a link of its own.
- A message is a Lua table written as text, and may carry a block of bytes after it, such as a frame's pixels. Each message starts with a line of the sizes of both, in bytes: `52 0`, then the text, then the block.
- A message's `type` names it. The tables below give each message's type, and the player's files document its fields.
- When a player has connected, it sends `hello`, with its mode and the engine's version.

| The editor sends | Type                      | To              | For                                                                                                        |
| ---------------- | ------------------------- | --------------- | ---------------------------------------------------------------------------------------------------------- |
| A file           | `file`                    | The edit player | A node file as the editor holds it, saved or not. The edit player reads it in place of the project's file. |
| A change         | `change`                  | The edit player | One edit of a node's own fields in such a file, such as a moved node.                                      |
| A view           | `view`                    | The edit player | Which node file to draw, from where, at what size, and which nodes are chosen (12.3).                      |
| Shown            | `shown`                   | The edit player | The editor has shown the last frame (12.4).                                                                |
| A question       | `question`                | The edit player | What a component type declares (12.5).                                                                     |
| Reload           | `reload`                  | The edit player | A file of the project that is not Lua changed, such as an image.                                           |
| Stop             | `stop`                    | Both players    | The player ends.                                                                                           |
| Pause, Step, Resume | `pause`, `step`, `resume` | The play player | The game stops, runs one frame, or goes on (12.1).                                                      |
| Watch            | `watch`                   | The play player | Which running nodes to send, or none (12.6).                                                               |
| A running change | `set`                     | The play player | A new value for a running node (12.6).                                                                     |

| The engine sends | Type     | From            | For                                                            |
| ---------------- | -------- | --------------- | -------------------------------------------------------------- |
| A frame          | `frame`  | The edit player | The picture of a view (12.4).                                  |
| Bounds           | `bounds` | The edit player | The nodes' bounds and places, when they change (12.3).         |
| An answer        | `answer` | The edit player | A type's properties, or why its file does not load (12.5).     |
| The tree         | `tree`   | The play player | The running tree's nodes, when it changes (12.6).              |
| Values           | `values` | The play player | The watched nodes' places and values (12.6).                   |
| An error         | `error`  | Both players    | A message with its file, line and stack.                       |

- A change carries a node's own fields only: its name, its place, its `z` and whether it is active. The edit player sets them on the view's nodes, so a drag draws at once. For any other edit, such as a component's value, the editor sends the file again, and the edit player makes the views' nodes anew.
- A node file that does not load leaves its view empty, and its error names the view.

### 12.3 Views

- The edit player only draws, and what it draws are views.
- A node view shows a view of an open node file. Other files, such as an image or a sound, are shown by the asset viewer (13.1) as the files they are; how the game draws them shows in the node view.
- The edit player draws a view when the editor asks: after a change, or when the view moves. It runs no loop of frames, so it uses the processor only when something changed.
- What is drawn is split by what it depends on:

  | Drawn by                    | What                                                                  | Because                                                       |
  | --------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------- |
  | The edit player, in LÖVE    | Each component's `drawEditor` (6.5): its picture, and its own outlines. | It depends on the component, and its author writes LÖVE code. |
  | The panel, over the frame   | The grid, the outline of the chosen nodes, and their handles.        | It depends on the pointer and the tool, and is the same for every component. |

- The engine sends every node's `bounds` (6.3), in the node's own space, with the node's place in the world: when a node file loads, and when its nodes change, not with each frame. The panel places them in the view itself, so moving the view sends nothing, and a turned node's outline turns with it. The panel draws its part from them and finds the node under the pointer from them, so a click needs no answer from the player.
- A node without `bounds` covers no rectangle, such as one whose only component is a script. The panel draws a small marker at its place, so it can be seen and chosen.

### 12.4 Frames

- The engine draws a view into a canvas of the view's size, reads the canvas back, and sends its pixels.
- The engine sends a frame only when the editor has shown the last one, so a slow panel never fills the link.
- LÖVE holds a pixel as red, green, blue and alpha, and OpenECS's images as blue, green, red and alpha. The engine draws the view's canvas once more through a shader that swaps red and blue, then reads it back. So the graphics card does it, and the panel takes the pixels as they come.
- The engine clears a view's canvas to transparent, so the panel's grid shows behind the nodes (13.3). LÖVE's canvases hold colours multiplied by their alpha, and OpenECS's images do not. The same shader divides them, so the panel draws a frame as it comes.

### 12.5 What the editor learns from LÖVE

- The editor never loads a script. To show a type's properties, it asks the edit player, which loads the file as the game would and answers with the type's properties (6.2): their names, kinds, defaults and options, in their order. It answers with the types that the type needs too (6.6).
- When a Lua file of the project other than a node file changes on disk, such as a script or the manifest, the editor starts the edit player again, which takes about a tenth of a second, and asks again. So nothing of the old code stays in it.
- While the edit player is down, such as after an error in `main.lua`, the node view shows the error, and the inspector shows the values that the node file holds, without their kinds.

### 12.6 The running game

- While the game plays, the nodes panel and the inspector can show the running tree in place of a node file. A change made there changes the running game only, and is gone at Stop. The panels mark that they show the running game.
- The editor asks the play player for the tree. The engine sends each node's name, its children and its components' types, and sends the tree again when it changes, at most four times a second. A running node has no id of a file (9), so the engine gives each a number for the link.
- For the chosen nodes, the engine sends their places and their components' values ten times a second. A reference is sent as what it names: a file as its path, and a node or a component as the node's number.
- A value that the user changes is sent to the play player, which sets it between two frames, as a script sets a field. A node's active and a component's enabled are set through their functions (7).
- The engine sends none of it unless the editor asks, and an exported game holds none of it (8.1).
- A game that sets its own `love.run` does not run the engine's loop (8.1). The play player then reads the link when the game's frame ends, and Pause and Step do nothing.

## 13. The editor

### 13.1 Plugins and panels

- The editor is an OpenECS tool: a preset and plugins, in Lua unless a part needs C. The user never sees or writes them.
- It builds on OpenECS's standard plugins (OpenECS-std DESIGN): process starts the players, net carries the link, fs watches the project, compress and hash serve export, web downloads LÖVE, and ui and draw make the panels.
- Every panel is a panel type that a plugin registers (OpenECS DESIGN 4), and the preset only places them. No panel is built into the editor, so the user opens, moves and groups them as in any OpenECS tool.
- A panel that needs nothing of ONLR, such as the files panel, the asset viewer and the console, is a plugin that knows nothing of ONLR and serves any OpenECS tool: `files`, `viewer` and `console`. Each belongs in OpenECS-std, as its settings window does (OpenECS-std DESIGN 12).
- Such a plugin is told what ONLR needs through its functions. The files panel takes handlers: how a file opens, which files it makes, what a rename and a delete do, and what the question before a delete adds. It drags a file as a list of paths, as another application's files come. The console takes lines, and the folder that their files are in.
- A panel of ONLR's own, such as the inspector or the nodes panel, is built from generic parts, such as ui's elements. A part that it needs and that knows nothing of ONLR is added to the standard plugin that it belongs to, not written inside ONLR, and not worked around.

| Plugin         | Does                                                                                          |
| -------------- | --------------------------------------------------------------------------------------------- |
| `onlr_project` | Holds the open project: its manifest, its node files, the chosen nodes, the chosen tool and the history. It reads and writes the files, and watches the folder. |
| `onlr_player`  | Starts the players and speaks the link. It gives the node view, and the functions Play, Play This File, Pause, Step and Stop. |
| `onlr_views`   | The other panels of ONLR's own: the nodes panel, the inspector, the tools and the project settings. |
| `onlr_export`  | Export (14), and LÖVE's runtimes (15).                                                        |

- The project's data lives in `onlr_project`, not in a panel (OpenECS OVERVIEW 9.2). Panels show it, change it through its functions, and hear of changes through its events.
- Every panel can be open many times. What belongs to the project is one, in `onlr_project`: its files, the chosen nodes, the chosen tool, snapping and the history. So two node views of one file show the same nodes, two inspectors show the same chosen nodes, and a change made in one panel shows in every other at once.
- What belongs to one panel is its own state (OpenECS OVERVIEW 5.4): where a node view looks from and its zoom, which nodes a nodes panel has open, and which components an inspector has folded.
- The asset viewer shows a file of the project as what it is, with the standard loaders: an image with image, a sound with audio and mixer, and a text with syntax. It shows no video, since OpenECS-std's video does not read LÖVE's Ogg Theora.
- The console is a log whose lines may name a file and a line, which a click opens in the user's code editor. Opening a file at a line in the user's code editor runs a command that is a setting, `console.editor`.
- `onlr_project` tells of changes with events: a project opened or closed, files changed, saved or renamed, the chosen nodes, the tool, the types, and a file that changed on disk. Its functions and events are documented in its code.

### 13.2 Projects

- ONLR's preset gives OpenECS an `open` function (OpenECS DESIGN 13.6), so a project's folder named on the command line opens.
- The menu has New Project, which asks for an empty folder, and Open Project, which asks for a folder. The project settings panel has both too, and while no project is open it lists the projects opened last.
- The editor's session keeps the open project's folder, so the editor starts with the project it was closed with.
- The editor holds one project at a time. Opening another closes the one that is open, after asking about unsaved work.
- A new project holds the files that section 3.1 says the editor writes, the engine in `packages/onlr/`, empty `components/` and `shared/` folders, and `nodes/start.lua`, an empty node. Its manifest names that file as the start node, and the folder's name as the game's `name` and `id`.

### 13.3 The node view

- Many node files can be open at once, each in a node view of its own. One edit player draws them all, since each is a view (12.3). Play This File and the panels follow the node view that has the focus.
- The node view has three tools: move, turn and scale. Each draws its handles on the chosen nodes, and a drag changes their place. The node view draws them over the frame (12.3). The tools are a panel of their own, and every node view follows the tool chosen there.
- A click chooses the node that draws last under the pointer, and another click at the same place chooses the one under it. Shift adds to the choice, and a drag from empty space chooses every node whose middle is in the rectangle.
- A drag that starts on a node drags the chosen nodes with the tool: move by the pointer's way, turn by its angle around each node's place, and scale by its distance from it. The edit player draws each step (12.2), and the release is one change of the history.
- The wheel zooms around the pointer. A drag with the middle button, or with Alt, moves the view.
- Snapping to a grid is a toggle. It and the grid's size are settings of the project, kept in `.onlr/editor.lua`, a data file.
- The node view draws the window's frame: a rectangle from 0, 0, of the size of the manifest's `window`. So the user sees where the nodes that no camera holds show, such as a score.
- Dragging an image from the files panel into the node view makes a node with a sprite of it, and dragging a node file makes an instance of it (9).
- The editor does not tell a level from a coin. Any node file can be the start node and can be held in another (5, 9), so the manifest's start node is chosen from every node file.

### 13.4 The nodes panel and the inspector

- The nodes panel shows the tree of the node file whose view has the focus, from its first node.
- The inspector shows the chosen node's own fields (5): its name, its place, its `z` and whether it is active. Then it shows each of its components under its type's name. A component has one row for each property: its `label`, or else its name in words, `cellSize` as "Cell size", and the control of its kind (6.2).
- A typed value is taken at Return. The inspector shows a node's angle in degrees; the file keeps radians, as LÖVE does.
- The nodes panel moves the chosen node with buttons: up and down among its parent's children, out of its parent, and into the node above it.
- With many nodes chosen, the inspector shows the fields and the components that all of them have. A value that differs among them shows empty, and a change sets it on all of them, as one change of the history.
- A reference (6.2) is set by dragging onto its row what it names: a file from the files panel, or a node from the nodes panel or the node view. A value is typed or chosen with its control, and is not dragged in the node view.
- A type or a property that the editor does not find, such as after a script was renamed outside the editor, shows in the inspector as the node file writes it. The user can give its values to another type or property. Until then they are kept (4.2).
- The types that adding a component offers are the files of the project's `components/` (3.1), and of the `components/` of the engine and of each package (11.2).
- Duplicating or pasting nodes gives the copies new ids. A property of a copy that names another node of the copies names that node's copy; one that names a node outside them is kept.
- A new script starts from ONLR's template: the type's table, empty functions for `load`, `update` and `draw`, and `return`.

### 13.5 Instances

- The nodes panel shows an instance's nodes, from its base, marked as an instance's. A change to one of them, from any panel, is written as a change of the instance (9).
- The inspector marks every value that an instance's change sets. A click on the mark puts back the base's value, and takes it out of the change.
- Open Base opens the base's node file in a node view.
- A node that comes from the base cannot be deleted or moved in the instance, since an instance removes nothing (9). The editor offers to turn it off instead.
- Save as Node File writes the chosen node, with all under it, to a new node file, and puts an instance of it in its place, as one change of the history. A property of the old file that named one of those nodes names it through the instance (9). A property among them that named a node outside them is left out of the new file, and set by a change of the instance, which names the old file's node. Undoing it puts the nodes back, and leaves the new file.
- New Variant makes a node file whose first node is an instance of the chosen node file (9).

### 13.6 Changes and saving

- Each change of a node file or of the manifest is a record that can be undone. `onlr_project` keeps them in one history for the project. One record can change many files, such as a deleted node and the properties that named it.
- Deleting a node, with all under it, also clears every property that names one of those nodes or one of their components, and drops every change of an instance that names one of them, in every node file of the project, in the same record. Removing a component clears the properties that name it in the same way. So no file names a node that is gone.
- When the editor reads a file that names a node that does not exist, such as after a merge in git, the inspector marks the property or the change, and offers to clear it (9).
- Undoing or redoing a change of a file that no node view shows opens a view of it.
- A node file with changes marks its panel as unsaved, so OpenECS asks before it closes (OpenECS OVERVIEW 5.5). A file that no view shows keeps its changes until the next save, and the editor asks about them before it closes the project.
- When a file goes back to what is on disk, because the user does not save its changes, or keeps a change made outside the editor, every record that changed it is taken out of the history.
- Play saves every node file with changes, and the manifest, before it starts the play player (12.1). So the game that plays is the project's files, and the play player is sent none. One game plays at a time: Play while a game plays stops it first.
- A file of the project that changes on disk is read again. When the editor's copy has unsaved changes too, the editor asks which to keep.
- A node view of a file that is renamed follows it, and one of a file that is gone shows no file.

### 13.7 Files

- The files panel shows the project's folder, apart from what starts with a dot. It makes folders, scripts and node files, renames and moves them, and deletes them after asking. The question names the node files that name the file. A deleted file goes to the system's trash, or to `.onlr/trash/` when the system has none.
- Opening a file opens a node file in a node view, a script in the user's code editor, and any other file in the asset viewer.
- Renaming, moving and deleting files are not in the history. Before a rename or a move, the editor saves every file with changes. Then it renames the file, changes every path and type name that names it, in every node file and in the manifest, and saves them. The user undoes it by renaming or moving the file back, and gets a deleted file back from the system's trash.

## 14. Export

### 14.1 The `.love` file

- A `.love` file is a zip archive of the project's folder, with `main.lua` at its root.
- The user chooses the folder that an export is written to, and the editor keeps it for the project in `.onlr/`. A folder inside the project is left out of every export, as `exclude`'s files are.
- It leaves out every file and folder whose name starts with a dot, such as `.onlr/` and `.luarc.json`, and what `exclude` in the project's manifest names.
- It holds every other file, as it is. The editor does not leave out a file that no node file names, since a script may name it in a text. Scripts stay source: LuaJIT's bytecode is tied to its version.
- The licences travel with their parts: the engine's is in `packages/onlr/`, and a library's is in the library's folder.

### 14.2 Builds

A build is made from the `.love` file and LÖVE's runtime for the platform (15.2), by copying and joining files. It runs no tool of the target's platform.

| Target        | The build                                                                                                         |
| ------------- | ----------------------------------------------------------------------------------------------------------------- |
| Linux x86_64  | LÖVE's files, with the `.love` file joined to the end of LÖVE's executable, in a `.tar.gz` archive that keeps the files' permissions. A launcher named after the game starts it. |
| Windows x86_64 | `love.exe` with the `.love` file joined to its end, named after the game, beside LÖVE's libraries, in a zip archive. |

- LÖVE runs a `.love` file that is joined to the end of its executable.
- A Windows build keeps LÖVE's icon and details.
- A build holds LÖVE's `license.txt`, which lists the licences of LÖVE and of the libraries inside it.

## 15. LÖVE

### 15.1 Version

- ONLR is made for LÖVE 11.5, and a project names the version it is made for (3.2). Each version of ONLR serves one version of LÖVE. When a project names another, the editor offers to move it to ONLR's, as it does for the engine (3.3).
- The engine avoids the functions that LÖVE's development version, 12.0, removes or renames, so the move to it stays small.

### 15.2 Runtimes

- A runtime is LÖVE for one version and one platform, as files in a folder.
- ONLR's archive holds the runtime of the editor's own platform, which the players run. On Linux it is the contents of LÖVE's AppImage, unpacked, so it runs without the system's AppImage support.
- The runtime of another platform is downloaded at the first export for it: from LÖVE's releases, and for Linux from ONLR, which hosts the AppImage's contents as a `.tar.gz`, since only Linux unpacks an AppImage. The editor checks it against SHA-256 hashes that ONLR ships, and keeps it in the user's data folder, by version and platform.
- A setting names a folder to use as a runtime instead, such as a LÖVE the user built.

## 16. Tests

- The samples are the tests. A sample is a small project that shows one part of ONLR. It has a test of the engine, a test of the editor, or both.
- A sample's test of the engine runs the sample in LÖVE with the offscreen driver; the sample checks itself and ends with a status.
- That test is the sample's `test.lua`, a plain module that the sample's `main.lua` loads when LÖVE gets the argument `--test`. It runs beside the game, a frame at a time, checks the game through the engine's functions, and quits with status 0 when every check passed.
- The tests share one helper, `samples/check.lua`. Before a test runs, the sample gets the helper and the engine in its `packages/`, as a project holds the engine (3.1). The repository does not keep those copies.
- The player and the link have a sample of their own, `samples/link`, which is no project: a plain LÖVE program that listens as the editor does, starts both players on other samples, and speaks the link with them.
- A sample's test of the editor is its `editortest.lua`, an OpenECS test (OpenECS DESIGN 17.5): it opens the sample, acts as a user would, and checks the files that the editor writes. It runs on a copy of the sample, since it writes the sample's files.
- `samples/editor` is a project as the editor writes one, so its test checks that a change and its undo give the first text again.
- One sample has thousands of nodes. It is the measure of speed: its test reports the time of a frame.
- A change that breaks a sample changes the sample in the same piece of work.

## 17. Versions and branches

- The engine uses semantic versioning. Its manifest names its version (8.3).
- A file's `format` is a number that changes when an older engine or editor cannot read the newer file (4.1). Nothing converts a file of an older format: while ONLR has no users, a new format may break projects.
- `dev` is the default branch, where work is merged. `main` holds what is stable: it changes only through a pull request from `dev`, which the owner merges.

## Glossary

**AppImage.** A way to ship a Linux program as one file. LÖVE's Linux release is one.

**Canvas.** A picture in the graphics card's memory that LÖVE draws into instead of the window.

**Component type.** A Lua file that returns a table with a component's properties and functions.

**Definition.** A LuaLS annotation that tells a code editor a type's fields or a function's parameters.

**Edit player.** The player that draws views for the editor.

**Entry.** The table that a node file holds for one node, one component or one change of an instance.

**Frame.** One picture that LÖVE draws: of the game, or of a view.

**Group.** A node that draws with all under it as one, through a component's `drawTree`.

**Library.** Lua code that its author wrote for LÖVE games to use.

**Link.** The connection between the editor and a player.

**LuaJIT.** The implementation of Lua that LÖVE runs. Its language is Lua 5.1 with additions.

**LuaLS.** The Lua language server, which completes and checks Lua code in code editors.

**LuaSocket.** A Lua library for network connections, which LÖVE ships.

**Metatable.** A table that tells Lua where to look when another table lacks a field.

**Offscreen driver.** A video driver of SDL that opens no window.

**Package.** A library made ready for ONLR: a folder of `packages/` with the library, its components and its node files.

**Play player.** The player that runs the game when the user plays it.

**Player.** LÖVE, started by the editor on the project.

**Plugin.** A module that gives OpenECS panels and functions.

**Preset.** The file that tells OpenECS which plugins and panels a tool starts with.

**Quad.** LÖVE's object for a rectangle of an image, with which LÖVE draws only that part of it.

**Root.** The node that the game runs under the top node, with all that is under it, until a script loads another in its place.

**Runtime.** LÖVE for one version and one platform, as files in a folder.

**SDL.** The library through which LÖVE and OpenECS use windows, input and graphics.

**Transform.** LÖVE's object for a position, a rotation and a scale together.

**Top node.** The node that the game loads once and keeps, above every root.

**Tree.** The nodes that the game runs: the top node and all under it, the root too.

**Variant.** A node file whose first node is an instance of another node file.

**View.** A node file as the edit player draws it: seen from a point, at a zoom and a size.
