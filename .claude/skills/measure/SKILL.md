---
name: measure
description: Measure the speed of ONLR - a game's frame in LÖVE, or the editor in OpenECS - offscreen, with LuaJIT's profiler, before and after a change. Use for any claim about speed, and in reviews that rank work by its gain.
---

# Measure speed

OpenECS's measure skill (`../OpenECS/.claude/skills/measure/SKILL.md`) holds the method: jit.p's modes, jit.v's aborts, three runs and the middle one, and a gain within the spread of the runs is no gain. This says where ONLR measures. Write every measurement in the scratchpad, never in the repository.

## 1. A game's frame

`samples/speed` holds 5000 nodes and reports a frame's update and draw, also with nodes spawned and destroyed. Copy it to the scratchpad, wrap its measure in `require("jit.p").start("F", file)` and `stop()`, and run it:

```sh
SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null love . --test
```

- `love.graphics.getStats()` read inside the draw gives its draw calls and batched calls.
- Add a phase to the copy for what the change is about, such as `setZ` or `setActive` each frame.

## 2. The editor

Build OpenECS in Release (`../OpenECS`, `./shuild.ignore -b release`). Copy `samples/speed` to the scratchpad and write a test beside it whose `preset` is ONLR's `preset.lua` by its path from there, and `files = { "manifest.lua" }`. After `test.wait(6)`, so the preview has loaded, time what the change is about with `os.clock()`: clicks in the node view or the nodes panel, a drag of a node. Run it with `LOVE=love SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null ../OpenECS/build/Release/bin/OpenECS --test bench.lua`.

## 3. Report

Give before and after, the middle of three runs, the build, and what jit.p named; in the commit message and the pull request. Mark what could not be measured.
