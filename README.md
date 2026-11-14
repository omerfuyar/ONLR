# ONLR

ONLR is an editor and an engine for 2D games that run on [LÖVE](https://love2d.org). Its engine is a Lua library that gives a LÖVE game nodes and components. Its editor is where you arrange them, run the game and export it.

ONLR means "ONLR Not Love Runtime": LÖVE stays the runtime, unchanged. A game made with ONLR is a `.love` file that any LÖVE runs.

ONLR is being built. The engine, the editor and export work on Linux. Windows is not tested yet.

## Cloning

``` sh
git clone --recurse-submodules https://github.com/omerfuyar/ONLR
```

## Running

ONLR needs [LÖVE 11.5](https://love2d.org) as `love`, and is built with [shuild](https://github.com/omerfuyar/shuild), as OpenECS is. Compile the build script once:

``` sh
cc shuild.c -o shuild
```

- `./shuild` puts the engine into every sample. After it, LÖVE runs a sample: `love samples/coinrun`.
- `./shuild --editor samples/editor` starts the editor on a sample. The editor needs [OpenECS](https://github.com/omerfuyar/OpenECS): unpack its release into `OpenECS/` here, or name its folder with `--openecs`.
- `./shuild --test` runs the tests. The samples are the tests. The editor's tests need a Debug build of OpenECS in `OpenECS/`, and are skipped without it.
- `./shuild --help` lists every flag.

- [OVERVIEW.md](OVERVIEW.md): what ONLR is.
- [DESIGN.md](DESIGN.md): how it is built.
- [TODO.md](TODO.md): what is open.

The editor is an [OpenECS](https://github.com/omerfuyar/OpenECS) tool. ONLR's license is [zlib](LICENSE.md).
