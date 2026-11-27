# ONLR Not Love Runtime

ONLR is an editor and an engine layer for 2D games that run on [LÖVE 11.5](https://love2d.org) built with [OpenECS](https://github.com/omerfuyar/OpenECS). Its engine is a Lua library that gives a LÖVE game nodes and components. Its editor is where you arrange them, run the game and export it. It also ships useful, already existing Lua libraries built for LÖVE.

Libraries used in ONLR named packages. Like onlr (engine itself), bump (for box collision), moonshine (for post processing) etc. You can add any package by yourself if it doesn't ship with ONLR.

LÖVE stays unchanged as the runtime for every exported game built with ONLR. You can export `.love` files that any LÖVE runs, or ship LÖVE together with that file as single native executable.

## Using it

Download the archive for your platform from the [releases](https://github.com/omerfuyar/ONLR/releases), unpack it anywhere, and run `ONLR` (`ONLR.cmd` on Windows) script. It holds the editor (OpenECS), LÖVE 11.5 and included packages.

See `ONLR gallery` for an example project that shows what ONLR does. Presented as different scenes.

See [GUIDE.md](GUIDE.md) to learn how to use ONLR.

## Development

ONLR Uses the most recent code (dev branch) of OpenECS. So see the 

### Cloning

``` shell
git clone --recurse-submodules https://github.com/omerfuyar/ONLR
git clone --recurse-submodules https://github.com/omerfuyar/OpenECS
```

### Building

``` shell
cd OpenECS
gcc shuild.c -o shuild.ignore -O3
./shuild.ignore -b release

```

### Running

ONLR needs [LÖVE 11.5](https://love2d.org) as `love`, and is built with [shuild](https://github.com/omerfuyar/shuild), like OpenECS. Compile the build script once:

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
