# CLAUDE.md

Instructions for AI agents working in this repository. Read this file fully before doing anything.

This is the only file written for agents. Everything else is written for humans. This file does not repeat project information; it tells you where to find it.

ONLR's editor is an OpenECS tool, and this repository is worked on as OpenECS is. OpenECS's [CLAUDE.md](https://github.com/omerfuyar/OpenECS/blob/dev/CLAUDE.md) applies here in full: how to work with the owner, the boundaries, git and writing documents. Read it first. This file names only what is different here.

## Where things are

| File                       | What it holds                                                                                  |
| -------------------------- | ---------------------------------------------------------------------------------------------- |
| [README.md](README.md)     | Short introduction.                                                                            |
| [OVERVIEW.md](OVERVIEW.md) | What ONLR is: its users, scope, principles and product decisions.                              |
| [DESIGN.md](DESIGN.md)     | How ONLR is built: the project's files, the engine, the runner and the link, the editor, export. |
| [GUIDE.md](GUIDE.md)       | The user's guide: how to make a game with ONLR, step by step.                                  |
| [TODO.md](TODO.md)         | Open questions and pending tasks.                                                              |
| `packages/`                | The engine, in `packages/onlr/`, which every project holds as its `packages/onlr/` (DESIGN.md, section 8.3), and the packages that ONLR ships, such as `packages/bump/` (DESIGN.md, section 11.2). |
| `plugins/`                 | The editor's plugin, `onlr`, with a file for each part and the runner's files in `onlr/runner/` (DESIGN.md, sections 12.1 and 13.1). The panels that know nothing of ONLR, `files`, `viewer` and `console`, are OpenECS-std's. |
| `preset.lua`               | The editor's preset: the plugins it needs, and where their panels go.                          |
| `samples/`                 | Small projects, which are the tests, `gallery/`, the demonstration of every feature, and `check.lua`, the tests' helper (DESIGN.md, section 16). |
| `shuild.c`                 | The build script: it puts the engine into the samples, runs the tests and starts the editor (DESIGN.md, section 16). |
| `dependencies/`            | Submodules: shuild and shu, which `shuild.c` builds with, and love2d, LÖVE's definitions from LuaCATS (DESIGN.md, section 4.3). |
| `.clang-format`            | How clang-format formats `shuild.c`, as OpenECS's does.                                        |
| `.github/`                 | Checks, the release workflow, rulesets, the releases' descriptions in `release-notes/`, and the scripts that agents and CI run: `check.sh`, `test.sh` and `package.sh`, which makes ONLR's archive (DESIGN.md, section 15.3). `scripts/assets/` makes the samples' images and sounds. |
| `.claude/`                 | Claude Code's settings, its hook for cloud sessions, `skills/` with the procedures for verifying, measuring, reviewing and changing OpenECS, and `notes.md`: why the tools are set up as they are. |
| `.luarc.json`              | How the Lua language server checks the repository's Lua files.                                 |
| `LICENSE.md`               | The license, zlib.                                                                             |

Before you propose or change anything, read the Contents of OVERVIEW.md and DESIGN.md, then every section the task touches.

## Current stage

The plan is done, and the implementation has started. Build it in small milestones, and keep DESIGN.md in step with the code: when the code shows a better way, or a gap, write the decision into DESIGN.md in the same piece of work, and tell the owner. Add each new part of the repository to the table above.

## Differences

**The project**

- LÖVE is never changed, and ONLR ships no changed LÖVE (OVERVIEW 11). Do not propose a design that needs one.
- Think from the editor's side too. A node file is read, written and tracked by the editor, not by a person: choose its format for that.
- Composition over inheritance, everywhere: in the engine, in the editor and in what users are given (OVERVIEW 11).
- Never be afraid of removing code and breaking things. ONLR has no users yet: delete a concept, a format or a whole design when a better one is found, and keep nothing for compatibility. Give versions little thought.
- OpenECS changes often. Know what it and its standard plugins can do, and read them again before you rely on them: [DESIGN.md](https://github.com/omerfuyar/OpenECS/blob/dev/DESIGN.md), [GUIDE.md](https://github.com/omerfuyar/OpenECS/blob/dev/GUIDE.md) and [OpenECS-std's DESIGN.md](https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md). Do not bind ONLR's design to it: only DESIGN.md's section on the editor depends on OpenECS, and it links to OpenECS's documents and repeats nothing of theirs.
- OpenECS, OpenECS-std and OpenECS-examples are the owner's too. When a fix or a feature belongs in one of them, make it there instead of working around it in ONLR:
  - Work in `../OpenECS`, with its `std/` and `examples/`, on a branch of that repository named as OpenECS's file says. OpenECS's CLAUDE.md and its skills apply there: pull-requests, interface-change for a change to the plugin interface, submodule-bump for moving `std/` and `examples/`, and a feature that works from C and from Lua alike.
  - A change to the core or a standard plugin gets a test in OpenECS-examples, in the same piece of work.
  - Merge it into OpenECS's `dev`, then build OpenECS again and lay out `OpenECS/` from it (Checks), before ONLR relies on it.
  - Write nothing of ONLR's into OpenECS's documents.
  - Ask first when the change is a matter of taste for other tools, such as a new look or a default; note it in TODO.md, Tasks, until the owner answers.
- The user of ONLR knows LÖVE, or learns it. Keep LÖVE's names and ways, so what they know stays true. They never see OpenECS's internals.
- Before recommending a library for the engine, check LÖVE first, as OpenECS's file says of SDL. Dependencies stay few (OVERVIEW 9).

**Working with the owner**

- Ask whenever instructions clash, in the same batch as the other questions.
- The owner is new to LÖVE and to engine design. Explain what a decision means for a game's author, not only what it is.

**Checks**

- The samples are the tests (DESIGN 16). Run the tests of what a change touches before each push, and all of them before a pull request.
- A significant feature that a game shows also goes into `samples/gallery`, in the same piece of work (DESIGN 16).
- A change that a user sees, such as a panel, a key or a component, goes into GUIDE.md in the same piece of work, as DESIGN does. Check the guide's steps by doing them, in the editor or in a game, with screenshots, as the verify skill says.
- Run an experiment only when a decision depends on its result, and never the same one twice.
- The owner runs experiments on their own computer when asked. Give exact steps: the files, the commands, and what to report back.
- Before each commit, run `.github/scripts/check.sh`: it checks the changed Lua files with the Lua language server when it is installed.
- People build and test with shuild: `./shuild --test`. `test.sh` runs the same, and prints only problems.
- Before each push, run `.github/scripts/test.sh` for the samples that the change touches, such as `.github/scripts/test.sh coinrun`, and with no names before a pull request. It needs LÖVE 11.5 as `love`, or where `LOVE` names it, and EGL. The editor's tests need OpenECS too, built in Debug and laid out as a release in `OpenECS/`, with its `include/`, as the checks lay it out; without it they are skipped, and the Lua check does not know the `ecs` module.
- The scripts print only problems. Read the logs in `build/tests/` only when a test fails.
- Look at what you changed, in the editor or in a game, offscreen, before you report it as done: a test that passes does not show that a change can be seen or used. The verify skill says how.
- ONLR runs on OpenECS's `dev`: lay out `OpenECS/` from `../OpenECS/build/Debug/bin` after building it, and use what `dev` holds. Nothing waits for an OpenECS release.
- Check documents by reading them: links, section numbers and cross-references.

**Git**

- Name your branch as OpenECS's file says, such as `docs/plan`, also when a session's own instructions name a generated branch. The owner wants proper names in pull requests.
- There are two long-lived branches. `dev` is the default, where work is merged. `main` holds what is stable.
- Merge your own work into `dev`, as the owner allowed. Open the pull request from `dev` into `main` when the owner asks; the owner merges it.
- Releases follow OpenECS's: a tag on `main`, a draft release that a workflow makes, and a description in `.github/release-notes/`, written as OpenECS's are. DESIGN 17 says how. Each release holds one release of OpenECS; tag only when the owner asks, and leave publishing the draft to the owner.
