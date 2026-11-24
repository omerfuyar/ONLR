---
name: verify
description: Check a change to ONLR before a commit, a push or a pull request - the Lua check, the samples' tests, and screenshots of the editor or a game run offscreen. Use when asked to test, check or verify a change, and before reporting a visible change as done.
---

# Verify a change

CLAUDE.md, section Checks, holds the rules; DESIGN 16 says what the samples test. This is how to run them.

## 1. OpenECS, once per OpenECS change

The editor runs on OpenECS's `dev`. Build it in `../OpenECS` (its verify skill), then lay it out as the checks do:

```sh
rm -rf OpenECS && mkdir OpenECS && cp -r ../OpenECS/build/Debug/bin/. OpenECS/ && rm -rf OpenECS/examples
OpenECS/OpenECS --definitions OpenECS/include
```

## 2. Checks

1. Before each commit: `.github/scripts/check.sh`.
2. Before each push: `.github/scripts/test.sh` with the samples the change touches, such as `.github/scripts/test.sh editor coinrun`; with no names before a pull request.
3. A failing test's log is in `build/tests/`; search it (`grep -n "error\|failed"`), do not read it whole.

## 3. Look at it

A test that passes does not show that a change can be seen or used. Never open a window on the owner's screen: everything runs offscreen.

- **The editor:** copy a sample into `build/shots/`, write beside it a test that acts as a user and calls `test.screenshot("name.png")`, with `preset = "../../../preset.lua"` (as `samples/editor/editortest.lua` does), and run it:

  ```sh
  cd build/shots/SAMPLE && LOVE=love SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null ../../../OpenECS/OpenECS --test shots.lua
  ```

  `test.titleBar()`, `test.panels()` and `test.rect(id)` find what to click; `test.errors()` at the end shows what plugins reported.
- **A game:** `SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null love samples/SAMPLE` with a script that calls `love.graphics.captureScreenshot`. Never a bare `love samples/SAMPLE`.
- Read every picture before reporting the change as done.
