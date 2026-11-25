# ONLR

ONLR is an editor and an engine for 2D games that run on [LÖVE](https://love2d.org). Its engine is a Lua library that gives a LÖVE game nodes and components. Its editor is where you arrange them, run the game and export it.

ONLR means "ONLR Not Love Runtime": LÖVE stays the runtime, unchanged. A game made with ONLR is a `.love` file that any LÖVE runs.

ONLR is being built. The engine, the editor and export work on Linux. Windows is not tested yet.

## Using it

Download the archive for your platform from the [releases](https://github.com/omerfuyar/ONLR/releases), unpack it anywhere, and run `ONLR`, or `ONLR.cmd` on Windows. It holds the editor, the engine and LÖVE 11.5: nothing else is installed. `ONLR gallery` opens a project that shows what ONLR does, and [GUIDE.md](GUIDE.md) shows how to make a game. This GUIDE.md describes the newest work, on `dev`; the archive holds the guide of its own release, which is the one to follow with it.

## Cloning

``` sh
git clone --recurse-submodules https://github.com/omerfuyar/ONLR
```

## Running

ONLR needs [LÖVE 11.5](https://love2d.org) as `love`, and is built with [shuild](https://github.com/omerfuyar/shuild), as OpenECS is. Compile the build script once:

``` sh
cc shuild.c -o shuild
```

- `./shuild` puts the engine, and the packages that a sample uses, into every sample. After it, LÖVE runs a sample: `love samples/coinrun`.
- `./shuild --editor samples/editor` starts the editor on a sample. The editor needs [OpenECS](https://github.com/omerfuyar/OpenECS): unpack its release into `OpenECS/` here, or name its folder with `--openecs`.
- `./shuild --test` runs the tests. The samples are the tests. The editor's tests need a Debug build of OpenECS in `OpenECS/`, and are skipped without it.
- `./shuild --help` lists every flag.

- [GUIDE.md](GUIDE.md): how to make a game with ONLR, step by step.
- [OVERVIEW.md](OVERVIEW.md): what ONLR is.
- [DESIGN.md](DESIGN.md): how it is built.
- [TODO.md](TODO.md): what is open.

The editor is an [OpenECS](https://github.com/omerfuyar/OpenECS) tool. ONLR's license is [0BSD](LICENSE.md).
