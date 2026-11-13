# CLAUDE.md

Instructions for AI agents working in this repository. Read this file fully before doing anything.

This is the only file written for agents. Everything else is written for humans. This file does not repeat project information; it tells you where to find it.

ONLR's editor is an OpenECS tool, and this repository is worked on as OpenECS is. OpenECS's [CLAUDE.md](https://github.com/omerfuyar/OpenECS/blob/dev/CLAUDE.md) applies here in full: how to work with the owner, the boundaries, git and writing documents. Read it first. This file names only what is different here.

## Where things are

| File                       | What it holds                                                                                  |
| -------------------------- | ---------------------------------------------------------------------------------------------- |
| [README.md](README.md)     | Short introduction.                                                                            |
| [OVERVIEW.md](OVERVIEW.md) | What ONLR is: its users, scope, principles and product decisions.                              |
| [DESIGN.md](DESIGN.md)     | How ONLR is built: the project's files, the engine, the player and the link, the editor, export. |
| [TODO.md](TODO.md)         | Open questions and pending tasks.                                                              |
| `prototype/`               | A sketch of a project's files, from the planning. Its engine is definitions only. The first sample replaces it, and it is then deleted. |
| `engine/`                  | The engine: the Lua library that every project holds as `packages/onlr/` (DESIGN.md, section 8.3). |
| `samples/`                 | Small projects, which are the tests, and `check.lua`, the tests' helper (DESIGN.md, section 16). |
| `.github/`                 | Checks, and the scripts that agents and CI run: `check.sh` and `test.sh`. `scripts/assets/` makes the samples' images and sounds. |
| `.claude/`                 | Claude Code's settings, its hook for cloud sessions, and `notes.md`: why the tools are set up as they are. |
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
- OpenECS changes often. Know what it and its standard plugins can do, and read them again before you rely on them: [OVERVIEW.md](https://github.com/omerfuyar/OpenECS/blob/dev/OVERVIEW.md), [DESIGN.md](https://github.com/omerfuyar/OpenECS/blob/dev/DESIGN.md) and [OpenECS-std's DESIGN.md](https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md). Do not bind ONLR's design to it: only DESIGN.md's section on the editor depends on OpenECS, and it links to OpenECS's documents and repeats nothing of theirs.
- OpenECS-std is the owner's too, and may change. When changing a standard plugin is the better solution, propose the change instead of working around the plugin, and note it in TODO.md, Tasks.
- The user of ONLR knows LÖVE, or learns it. Keep LÖVE's names and ways, so what they know stays true. They never see OpenECS's internals.
- Before recommending a library for the engine, check LÖVE first, as OpenECS's file says of SDL. Dependencies stay few (OVERVIEW 9).

**Working with the owner**

- Ask whenever instructions clash, in the same batch as the other questions.
- The owner is new to LÖVE and to engine design. Explain what a decision means for a game's author, not only what it is.

**Checks**

- The samples are the tests (DESIGN 16). Run the tests of what a change touches before each push, and all of them before a pull request.
- Run an experiment only when a decision depends on its result, and never the same one twice.
- The owner runs experiments on their own computer when asked. Give exact steps: the files, the commands, and what to report back.
- Before each commit, run `.github/scripts/check.sh`: it checks the changed Lua files with the Lua language server when it is installed.
- Before each push, run `.github/scripts/test.sh` for the samples that the change touches, such as `.github/scripts/test.sh coinrun`, and with no names before a pull request. It needs LÖVE 11.5 as `love`, or where `LOVE` names it, and EGL.
- The scripts print only problems. Read the logs in `build/tests/` only when a test fails.
- Check documents by reading them: links, section numbers and cross-references.

**Git**

- Name your branch as OpenECS's file says, such as `docs/plan`, also when a session's own instructions name a generated branch. The owner wants proper names in pull requests.
- There are two long-lived branches. `dev` is the default, where work is merged. `main` holds what is stable.
- Merge your own work into `dev`, as the owner allowed. Open the pull request from `dev` into `main` when the owner asks; the owner merges it.
- No releases are planned, so nothing here follows OpenECS's releases or its release descriptions.
