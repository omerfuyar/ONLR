# ONLR User's Guide

This guide shows how to make a game with ONLR, step by step. It is written for someone who knows LÖVE, or is learning it. It says what to do; [DESIGN.md](DESIGN.md) says how each part works, and its sections are named here in brackets, such as (DESIGN 6.2).

**See also:**

- What ONLR is, and what it leaves to LÖVE, is in [OVERVIEW.md](OVERVIEW.md).
- LÖVE's own functions are in [LÖVE's wiki](https://love2d.org/wiki/Main_Page). A script of ONLR calls them as any LÖVE game does.

---

## Contents

1. Starting
2. The editor
3. A first game
4. Scripts
5. Node files and instances
6. The camera and the window
7. Packages
8. Playing and fixing
9. Export
10. Keys

---

## 1. Starting

### 1.1 What ONLR is

A LÖVE game is code: `love.load`, `love.update` and `love.draw`, and whatever they call. ONLR adds **nodes** and **components** to it.

- A **node** is a thing in the game, such as the player, a coin or the score. It has a place, an angle, a scale and a name, and it may hold other nodes, its children, which move with it.
- A **component** is what a node does or shows. A node that draws a picture has `onlr.sprite`; a node that the player moves has your script `player`. A node holds any number of components, one of each type.
- A **node file** holds nodes: a level, a menu, or a coin. The game starts with one of them, and a node file can hold another, such as a level that holds ten coins.
- A **script** is a component type that you write: a Lua file in `components/`. It has the functions that LÖVE has, such as `update(dt)`, `draw()` and `keypressed(key)`, and LÖVE calls them for each node that has it.

The editor is where you arrange nodes, give them components, and set their values. You write the scripts in your own code editor. The game is still a LÖVE game: `love mygame` runs it, and every function of LÖVE works in it.

### 1.2 Getting ONLR

Download the archive for your platform from the [releases](https://github.com/omerfuyar/ONLR/releases), unpack it anywhere, and run `ONLR`, or `ONLR.cmd` on Windows. LÖVE 11.5 is inside, so nothing else is installed.

`ONLR gallery` opens the gallery: a project of rooms, each of which shows one thing that ONLR does. Play it, and open its node files to see how each room is made. Page Up and Page Down go from room to room.

To work on ONLR itself, or to run it from its repository, see [README.md](README.md).

### 1.3 A new project

1. Right click the editor's title bar and choose **New Project**, or press **New project** in the **Project** panel, a tab beside the inspector.
2. Choose an empty folder. The editor makes the project in it and opens it.

The project is a folder that LÖVE runs as it is (DESIGN 3.1):

``` text
mygame/
  main.lua          starts the engine; the game's own start goes in love.load
  conf.lua          gives LÖVE the project's settings
  manifest.lua      the project's settings
  components/       your scripts
  shared/           your Lua code that scripts share, such as a score
  nodes/            the node files; start.lua is the first one
  packages/         the engine, in onlr/, and the packages you add
```

Your pictures, sounds and fonts go in any folder you like, such as `images/`. Do not change `packages/onlr/`: it is the engine, and the editor replaces it when it updates the engine.

### 1.4 The project's settings

The **Project** panel shows `manifest.lua` (DESIGN 3.2):

- **Name** is the window's title and the name of the exports.
- **Start node** is the node file that the game starts with.
- **Top node** is a node file that the game loads once and keeps for the whole game, above every level, such as music that plays on in every level. Most games start without one.
- **Window width** and **height** are the window's size in pixels. A new project starts at 1920 by 1080. **Resizable** lets the player resize the window, and **Fullscreen** fills the screen.
- **Default filter** is how pictures are scaled: `nearest` keeps pixel art sharp, and `linear` makes large, smooth pictures smooth.
- **Fixed rate** is how many times a second `fixedUpdate` runs (4.2).

LÖVE draws a game at its own pixels from the window's top left. So a larger window, or a full screen, shows empty space around the game. **Scale to the window**, under Resizable and Fullscreen, scales the game to the window instead (6.2).

## 2. The editor

The editor is made of panels. Each can be moved, put beside another, or put in tabs, by dragging its tab. The **panels** list in the title bar's right-click menu opens a panel that was closed.

| Panel             | Where it starts         | What it does                                                                                     |
| ----------------- | ----------------------- | ------------------------------------------------------------------------------------------------ |
| Tools             | The bar across the top  | The tool and its pivot, snapping and the grid; Undo, Redo and Save; Play, Pause, Step and Stop; the window size to play in. |
| Nodes             | Left                    | The tree of the node file that is open: choose nodes, rename them, drag them into other nodes.   |
| Node view         | Middle                  | The node file drawn as the game draws it: choose nodes, and move, turn and scale them.           |
| Inspector         | Right                   | The chosen nodes' place and components, and their values.                                      |
| Project, Export   | Tabs beside the inspector | The project's settings (1.4), and export (9).                                                  |
| Asset viewer      | Under the inspector     | The picture, sound or text of the file chosen in the files panel.                                |
| Console           | Bottom                  | What the game prints, and its errors. A click on an error's file opens it in your code editor.   |
| Files             | A tab beside the console | The project's files: open, rename, move and delete them, and make folders, scripts and node files. |
| History           | A tab beside the console | Everything that you did, which a click undoes or redoes to.                                     |
| Search            | Ctrl+K, from anywhere   | Finds nodes, files, component types, your scripts' functions and the editor's commands.         |

A few things to know:

- **Choosing** is shared. A node chosen in the nodes panel is chosen in the node view and shown in the inspector, and the other way round.
- **A double click** on a node file, in the files panel, opens it in the node view. A double click on a script opens it in your code editor.
- **Every change can be undone** with Ctrl+Z, and choosing nodes is in the history too, so Ctrl+Z walks back through everything that you did. Renaming, moving and deleting files are not in the history: a deleted file goes to the system's trash.
- **Save** with Ctrl+S. Play saves first.
- **A right click** opens a menu wherever there is one: on a node, on empty space in the node view, on a component's heading in the inspector, and on a file.

### 2.1 The node view's tools

The tools bar chooses what a drag in the node view does. Each has a key, as in Unity:

| Tool  | Key | A drag                                                                                                |
| ----- | --- | ----------------------------------------------------------------------------------------------------- |
| Move  | W   | Moves the chosen nodes. A drag on the red or green arrow moves them along that axis alone.             |
| Turn  | E   | Turns them, by the pointer's angle around the ring. With Ctrl, in steps of 15 degrees.                 |
| Scale | R   | Scales them, by the pointer's distance. A drag on a grip scales one axis alone.                        |
| Rect  | T   | Sizes one node by its corners and edges, while the edges across stay.                                |
| Shape | Y   | Drags the corners and points of the chosen node's shape, and of any point that a script marks (4.3).  |

- **Own place**, **Own middle** and **Selection** choose what the chosen nodes turn and scale around: each its own place, each the middle of its own picture, or the middle of all of them together.
- **Snap** moves and sizes in steps of **Grid** pixels. Holding Ctrl while dragging turns snapping on or off for that drag.
- The wheel zooms. A drag with the middle button, or with Alt held, moves the view. **F** fits the view to the chosen nodes.
- A click chooses the node under the pointer, and Shift adds to the choice. A drag from empty space chooses every node in the rectangle.
- **H** hides the chosen nodes in the node view, and **L** locks them, so a click there does not choose them, as a background that you do not want to move by mistake. Each row of the nodes panel has Hide and Lock too. The game still shows them.

The grey rectangle, named "Window", is the game's window: what is outside any camera shows on the screen where it is drawn there.

## 3. A first game

This makes a small game: a square that the arrow keys move, coins that it takes, and a score. It shows the parts that every game uses.

### 3.1 The player

1. Open `nodes/start.lua`: double click it in the files panel, or it is open already in a new project.
2. Right click empty space in the node view and choose **Add Node Here**. Rename it `Player`: press F2 in the nodes panel, type the name and press Return.
3. In the inspector, choose `onlr.shape` in **Add component**, at the inspector's end; the types are in folders by their names, so it is under `onlr`. Its kind is a rectangle of 32 by 32. Set **Width** and **Height** to 24, and its **Origin** to 12 and 12, so the node's place is the square's middle.
4. Add `onlr.paint`. It draws the node's shape. Choose a colour.

A shape alone draws nothing in the game: it is the node's outline, which a paint draws, and which other components use too, such as a body of physics. So one value, the size, has one place, and everything that needs it reads it there.

### 3.2 The player's script

1. In the files panel, right click `components/` and choose **New script**, named `player`. The editor writes `components/player.lua` from a template. Double click it to open it in your code editor.
2. Write:

``` lua
local onlr = require("onlr")

---@class player : onlr.Component
local Player = {}

Player.speed = onlr.property.number(200, { description = "Pixels a second" })

function Player:update(dt)
  local dx, dy = 0, 0
  if love.keyboard.isDown("left") then dx = dx - 1 end
  if love.keyboard.isDown("right") then dx = dx + 1 end
  if love.keyboard.isDown("up") then dy = dy - 1 end
  if love.keyboard.isDown("down") then dy = dy + 1 end
  self.node.posX = self.node.posX + dx * self.speed * dt
  self.node.posY = self.node.posY + dy * self.speed * dt
end

return Player
```

3. Save the file. Choose the Player node, and choose `player` in **Add component**. The inspector shows **Speed**, 200, which you can change for this node without touching the script.
4. Press **Play**, or F5. The game opens in its own window, and the arrow keys move the square. Close the window, or press **Stop**, to end it.

`self` is the component, and `self.node` is its node. `self.speed` is the value that the inspector shows. Every node with a `player` has a component of its own, with its own speed.

### 3.3 A coin

A coin is a node file of its own, so that the level can hold many of them, and a change to the coin changes every one.

1. Make a script `coin`:

``` lua
local onlr = require("onlr")
local score = require("shared.score")

---@class coin : onlr.Component
local Coin = {}

Coin.worth = onlr.property.integer(1, { min = 1 })
Coin.reach = onlr.property.number(24, { description = "How near the player takes it" })

function Coin:start()
  self.player = onlr.tree.find("Player")
end

function Coin:update(dt)
  local player = self.player
  if player and not player:isDestroyed() then
    local x, y = self.node:toWorld(0, 0)
    local px, py = player:toWorld(0, 0)
    if (px - x) ^ 2 + (py - y) ^ 2 < self.reach ^ 2 then
      score.add(self.worth)
      self.node:destroy()
    end
  end
end

return Coin
```

2. Make `shared/score.lua`: right click `shared/` in the files panel and choose **New file**. It is plain Lua, not a component, so every script that loads it shares the same score:

``` lua
local score = { coins = 0 }

function score.add(worth)
  score.coins = score.coins + worth
end

return score
```

3. In the files panel, right click `nodes/` and choose **New node file**, named `coin`. It opens in a node view of its own.
4. Choose its first node, `Coin`, and give it `onlr.shape` with the kind **circle** and a radius of 8, `onlr.paint` in yellow, and `coin`.
5. Go back to `start.lua`'s node view, and drag `nodes/coin.lua` from the files panel into it, twice, at two places. Each is an **instance** of the coin: the coin's nodes, at its own place.

An instance shows in the accent colour in the nodes panel. Its values are the coin's, unless you change them on the instance: set one instance's **Worth** to 5, and only that coin is worth 5. The inspector marks the value, and a click on the mark puts the coin's value back.

### 3.4 The score

1. Add a node `Score` to `start.lua`, near the window's top left, and give it `onlr.text`.
2. Make a script `hud`, and give it to Score:

``` lua
local score = require("shared.score")

---@class hud : onlr.Component
local Hud = {}

function Hud:update(dt)
  self.node.components.onlr.text.text = "Coins: " .. score.coins
end

return Hud
```

3. Play. The square takes the coins, and the score counts them.

`self.node.components.onlr.text` is the node's text component, by its type's name. So one component reads and changes another's values, as `text` here.

## 4. Scripts

### 4.1 A component type

A script is a Lua file in `components/` that returns a table (DESIGN 6.1). Its name is its path: `components/player.lua` is `player`, and `components/enemies/bat.lua` is `enemies.bat`. A folder with an `init.lua` is one type, whose other files are its own modules: `components/player/init.lua` is `player`.

Types never inherit from each other. What two types share goes in a module of `shared/` that both load, or in a component of its own that both find on the node. A node with a `health` and a `player` is a player that can be hurt; a node with a `health` and an `enemy` is an enemy that can be.

### 4.2 Functions

The engine calls the functions that a type has, all of them optional (DESIGN 6.3):

| Function           | When                                                                                                  |
| ------------------ | ----------------------------------------------------------------------------------------------------- |
| `load()`           | Once, when the node enters the game, with its values set. Make here what the component holds.         |
| `start()`          | Once, before its first `update`, when every other node has loaded. Find other nodes here.              |
| `update(dt)`       | Each frame, with the seconds since the last one.                                                      |
| `fixedUpdate(dt)`  | At the project's fixed rate, with the same `dt` each time: what must behave the same at any frame rate. |
| `lateUpdate(dt)`   | Each frame, after every `update`: what follows another node.                                          |
| `draw()`           | Each frame. Draw at 0, 0 to draw at the node: its place, angle and scale are already applied.          |
| LÖVE's callbacks   | `keypressed(key)`, `mousepressed(x, y, button)`, `resize(w, h)` and every other one, when LÖVE sends it. |
| `enable()`, `disable()` | When the component starts and stops running, such as when it, or its node, is turned off.        |
| `destroy()`        | Once, when the node is destroyed or the level is replaced.                                            |

Code outside the functions runs in the editor too, when it draws the node view. So a script does its work in its functions, and the top of the file only declares.

### 4.3 Properties

A property is a value that the inspector shows and that each node sets (DESIGN 6.2). Declare it with a function of `onlr.property`, and read it as `self.name`:

| Function    | The inspector shows             | The script gets                     |
| ----------- | ------------------------------- | ----------------------------------- |
| `bool`      | A toggle                        | `true` or `false`                   |
| `integer`, `number` | A number, and a slider with `min` and `max` | A number              |
| `string`    | A text field                    | A text                              |
| `choice`    | One of its `choices`            | The chosen text                     |
| `color`     | A colour                        | What `love.graphics.setColor` takes |
| `image`, `sound`, `font` | A file of the project  | The LÖVE image, source or font, loaded |
| `file`, `nodeFile` | A file, or a node file   | Its path                            |
| `node`      | A node of the same node file    | The node                            |
| `component` | A node of the same file with a type | That node's component            |
| `vector`    | Two numbers                     | A table with `x` and `y`            |
| `group`, `list` | Properties together, or rows of one kind | A table, or a list          |

- A file is set by dragging it from the files panel onto the property, or with the property's button. A file from outside the project is copied into it first, since a LÖVE game reads only its own folder.
- A node is set by dragging it from the nodes panel or the node view onto the property, or with **Pick** and a click on the node.
- `description` is shown as the property's tooltip, `heading` puts a title above it, and `when` shows it only while another property has a value, as `{ kind = "circle" }`.
- `handles = true` on a `vector`, or a list of them, lets the Shape tool drag the points in the node view, as a patrol path's.

### 4.4 Nodes and other components

| To                                    | Write                                                       |
| ------------------------------------- | ----------------------------------------------------------- |
| Move this node                        | `self.node.posX = self.node.posX + 10`                      |
| Read another component of the node    | `self.node.components.onlr.sprite`, `self.node.components.player` |
| Find a node by its name               | `onlr.tree.find("Player")`                                  |
| Find a component by its type          | `onlr.tree.findComponent("player")`, `onlr.tree.findAllComponents("enemy")` |
| Make a node from a node file          | `onlr.tree.spawn("nodes/coin.lua", x, y)`                   |
| Destroy a node                        | `node:destroy()`; ask `node:isDestroyed()` before using a node that you kept |
| Go to another level                   | `onlr.tree.loadRoot("nodes/level2.lua")`                    |
| Turn a node or a component off and on | `node:setActive(false)`, `component:setEnabled(false)`      |
| Pause a node and all under it         | `node:setPaused(true)`: it still draws                      |
| Call a function on every component of a node | `node:send("hit", 10)` calls `hit(10)` in each that has it |
| A point of the node in the world      | `node:toWorld(0, 0)`                                        |

Nodes have no tags: a type is one. An empty script `enemy` on every enemy, and `onlr.tree.findAllComponents("enemy")` finds them all. The whole list is in DESIGN 7.2.

## 5. Node files and instances

- **Save as Node File**, in a node's right-click menu, moves the node and all under it into a node file of its own, and leaves an instance of it in its place. So a thing that you built in a level becomes one that every level can use.
- **New Variant**, in the menu of empty space in the nodes panel, makes a node file that is an instance of the open one, such as a big coin made from the coin: it changes what it needs, and follows the coin in the rest.
- **Open Base**, on an instance, opens the node file that it is an instance of.
- An instance changes values and adds components and children. It removes nothing: turn off what it does not want, with the node's **Active** or the component's **Enabled**.
- A script makes an instance with `onlr.tree.spawn`, as a gun makes a bullet. A `nodeFile` property with `preload = true` loads the node file with the level, so the first spawn does not wait for the disk.

## 6. The camera and the window

### 6.1 A camera

1. Put the level's nodes under one node, such as `World`, by dragging them onto it in the nodes panel.
2. Give `World` the component `onlr.camera.view`. It shows the nodes under it, moved so that the middle of the window shows its point.
3. Give it `onlr.camera.follow` too, and drag the Player onto its **Target**. The camera follows the player, smoothly.

What is not under the camera, such as the score, stays where it is on the screen. `onlr.camera.limits` keeps the camera inside the level's edges, and `onlr.camera.shake` shakes it when a script asks. A click's place in the level is `camera:toWorld(love.mouse.getPosition())` (DESIGN 10).

### 6.2 Scaling to the window

A game made for 640 by 360 shows at 640 by 360 pixels, whatever the window's size. To scale it to the window, press **Scale to the window** in the Project panel. The editor:

- copies ONLR's `push` package into the project, when it lacks it;
- makes `nodes/top.lua` the top node, when the project has none;
- gives the top node a `push.screen` of the window's size, so the game keeps the size that it was made at, and is scaled from it, with bars where the window's shape differs.

Then turn on **Resizable** or **Fullscreen**. In `push.screen`, **Pixel perfect** scales by whole numbers only and **Canvas** draws the game into a picture of its own size first, as pixel art needs (DESIGN 11.10). A camera under the screen names the game's size in its **Width** and **Height**.

**Window**, in the tools bar, plays the game in another size, such as a phone's, without changing the project, so you see how the game looks on a screen that it was not made on.

## 7. Packages

A package is a library of LÖVE's world with components for ONLR (DESIGN 11.2). ONLR ships these:

| Package     | For                                                                                  | Its components |
| ----------- | ------------------------------------------------------------------------------------ | -------------- |
| `anim8`     | Animations of a sprite sheet                                                         | `animation` |
| `audio`     | LÖVE's sound, as sources and a listener on nodes                                     | `source`, `listener` |
| `baton`     | Input actions: keys, mouse buttons and gamepads bound to a game's controls            | `input` |
| `bump`      | Collision of boxes, as a platformer needs                                            | `world`, `body` |
| `flux`      | Tweens: numbers that move to a value over time                                       | `tweens` |
| `moonshine` | Screen effects: blur, glow, vignette, CRT and more                                   | `chain`, `effect` |
| `particles` | LÖVE's particle systems                                                              | `emitter` |
| `physics`   | LÖVE's physics: bodies that fall, collide, bounce, turn and join                    | `world`, `body`, `fixture`, `joint` |
| `push`      | The game drawn at a fixed size and scaled to the window                              | `screen` |
| `shadows`   | Lights that cast shadows                                                             | `world`, `light`, `caster` |
| `sti`       | Tile maps made with [Tiled](https://www.mapeditor.org), and their collisions and objects | `map`, `bump`, `physics`, `objects` |
| `suit`      | Buttons, labels, sliders and text fields inside the game                             | `button`, `label`, `slider` and others |
| `tick`      | Timers                                                                               | `timers` |

- To add one, copy its folder from ONLR's `packages/`, beside the editor, into your project's `packages/`, such as `packages/bump/`. Its components show in **Add component** at once, named after it: `bump.body`. The editor does not yet add packages itself; Scale to the window is the one exception (6.2).
- Each package has a sample in ONLR's repository, `samples/`, and a room in the gallery, which show it at work.
- A package's library is loaded by its own name, as its author documents it: `require("bump")`. ONLR renames nothing, so the library's own documentation holds.
- Any other library works as in any LÖVE game: copy it into `packages/` and `require` it.

## 8. Playing and fixing

- **Play**, F5, saves the project and runs the game from its start node. **Play this file**, F6, runs the node file that is open instead, so a level is tried without playing up to it.
- **Pause**, F7, stops the game where it is, and **Step**, F8, runs one frame of it. **Stop** is Shift+F5.
- While the game plays, the editor turns brown, and the nodes panel and the inspector show the running game: choose a node there to see its values as they change, and change one to try it. What you change there is gone at Stop, so a value that you like is set again in the node file.
- The tools bar shows the game's frames a second, and how long a frame spends in `update` and in `draw`.
- The console shows what the game prints with `print`. An error names its file and line, which a click opens in your code editor, the node and the component that raised it, and often a hint of what it means. The game stops at the error, and the panels show the nodes as the error left them, until Stop.
- The node view runs your scripts' `drawEditor` and `bounds` if they have them, so a script can draw in the editor what it does not draw in the game, such as a path (DESIGN 6.5).
- The console's code editor is a setting, `console.editor`, in the editor's settings.

## 9. Export

The **Export** panel, a tab beside the inspector, writes the game into a folder that you name first, such as `out`. A name that starts at no root is a folder in the project, which every export leaves out of itself:

- **Export the .love file**: one file, which any LÖVE 11.5 runs.
- **Export a Linux build** and **Export a Windows build**: the game with LÖVE inside, in a `.tar.gz` or a `.zip`, which runs with nothing installed. The Windows build downloads LÖVE's runtime the first time.

Files whose names start with a dot, such as `.onlr/`, stay out, and so do the patterns of the manifest's `exclude`, such as `notes/*`. Every other file goes in, since a script may name a file in a text.

## 10. Keys

| Key            | Where             | Does                                                    |
| -------------- | ----------------- | ------------------------------------------------------- |
| Ctrl+Z, Ctrl+Y | Everywhere        | Undo, redo                                              |
| Ctrl+S         | Everywhere        | Save                                                    |
| Ctrl+K         | Everywhere        | Search                                                  |
| F5, F6         | Node view         | Play, Play this file                                     |
| F7, F8, Shift+F5 | Node view       | Pause, Step, Stop                                        |
| W, E, R, T, Y  | Node view         | Move, Turn, Scale, Rect and Shape tools                  |
| F              | Node view         | Fit the view to the chosen nodes                         |
| H, L           | Node view, nodes  | Hide, lock the chosen nodes in the node view             |
| Ctrl+D         | Node view, nodes  | Duplicate                                               |
| Delete         | Node view, nodes  | Delete                                                  |
| Ctrl+C, Ctrl+V | Node view         | Copy, paste nodes                                        |
| Ctrl+A         | Node view, nodes  | Choose every node                                        |
| Shift+A        | Node view, nodes  | Choose the chosen nodes' children too                    |
| F2             | Nodes             | Rename                                                  |
| Ctrl+F         | Nodes, console    | Search                                                  |
| Ctrl, in a drag | Node view        | Snap or not; turn in steps of 15 degrees                 |
