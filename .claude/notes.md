# Notes

Notes for agents and the owner that belong in no other document: why the tools are set up as they are. They load only when read; CLAUDE.md names this file.

## Tools

- In a cloud session, `.claude/hooks/session-start.sh` installs at its start what `check.sh` and `test.sh` need: EGL with Mesa, LÖVE 11.5 from its AppImage, the Lua language server, and LÖVE's definitions in `build/love2d/`. Elsewhere it does nothing.
- LÖVE's AppImage is unpacked with `--appimage-extract`, which needs no FUSE, and its `AppRun` is run as `love`.
- `test.sh` runs LÖVE with SDL's offscreen driver, which needs EGL, and with OpenAL Soft's null driver, which needs no sound device. On a computer without a graphics card, Mesa draws in software.
- `.luarc.json` names LuaJIT for every Lua file, the plugins too: they run in OpenECS's Lua 5.5, so they keep to what both have. It turns off `duplicate-set-field`, since every sample defines `love.conf` and some define `love.draw`.
- `.luarc.json` names `build/love2d/library`, LÖVE's definitions from LuaCATS, at the commit that `checks.yml` names in `LOVE2D_DEFINITIONS`, and `OpenECS/include`, where the editor's plugins find the `ecs` module.
- `check.sh` checks Lua files with LuaLS over the whole folder and prints only the named files' problems, because LuaLS 3.15 finds nothing in a file that it checks alone.
- The copies of the engine that `test.sh` puts into each sample are ignored by git, so LuaLS does not see each class twice.
