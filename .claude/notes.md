# Notes

Notes for agents and the owner that belong in no other document: why the tools are set up as they are. They load only when read; CLAUDE.md names this file.

## Tools

- In a cloud session, `.claude/hooks/session-start.sh` installs at its start what `check.sh` and `test.sh` need: EGL with Mesa, LÖVE 11.5 from its AppImage, the Lua language server, and the submodules, LÖVE's definitions among them. Elsewhere it does nothing.
- LÖVE's AppImage is unpacked with `--appimage-extract`, which needs no FUSE, and its `AppRun` is run as `love`.
- `shuild.c`'s `--test`, which `test.sh` calls, runs LÖVE with SDL's offscreen driver, which needs EGL, and with OpenAL Soft's null driver, which needs no sound device. On a computer without a graphics card, Mesa draws in software.
- `.luarc.json` names LuaJIT for every Lua file, the plugins too: they run in OpenECS's LuaJIT 2.1, as the games run in LÖVE's, and keep to LuaJIT 2.1's syntax without its 3.0 extensions, which LÖVE 11.5's LuaJIT lacks. It turns off `duplicate-set-field`, since every sample defines `love.conf` and some define `love.draw`.
- `.luarc.json` names `dependencies/love2d/library`, LÖVE's definitions from LuaCATS, a submodule, and `OpenECS/include`, where the editor's plugins find the `ecs` module.
- `check.sh` checks Lua files with LuaLS over the whole folder and prints only the named files' problems, because LuaLS 3.15 finds nothing in a file that it checks alone.
- `.luarc.json` leaves every folder named `library` out of the check: a package's `library/` holds its library unchanged.
- The copies of the engine that `shuild.c` puts into each sample are ignored by git, so LuaLS does not see each class twice.
- The editor's tests and the plugins' Lua check need OpenECS in `OpenECS/`, laid out as a release has it. The hook does not make it, since the build takes long: clone OpenECS's `dev` with its submodules, run its `.github/scripts/install-linux.sh` and `.github/scripts/build.sh D`, copy `build/Debug/bin/.` into `OpenECS/` here, and run `OpenECS/OpenECS --definitions OpenECS/include`. `checks.yml` does the same, and keeps the result by OpenECS's commit. When OpenECS changes, it restores the built dependencies and C++ libraries as OpenECS-template's checks do, and ccache's compiled files from the last build, so only what changed compiles. The archive also holds `packages.txt`, the Debian packages of the libraries that OpenECS links, which the test job installs in place of all of OpenECS's build tools.
- An editor's test finds a control by its place in its panel, since a test cannot ask ui for an element's rectangle. When OpenECS-std changes ui's sizes, the places in `editortest.lua` change with them.
- In an editor's test, text typed right after a click on a field is lost when a `test.wait` with a time comes between them; a key such as Ctrl+A, or a `test.wait()` of one pass, does not lose it. The cause is not known.
