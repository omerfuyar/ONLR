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
| `LICENSE.md`               | The license, zlib.                                                                             |

Before you propose or change anything, read the Contents of OVERVIEW.md and DESIGN.md, then every section the task touches.

## Current stage

ONLR is being planned. Planning is the work: the documents are what you make. Write no code until the owner says the plan is done.

## Differences

**The project**

- LÖVE is never changed, and ONLR ships no changed LÖVE (OVERVIEW 11). Do not propose a design that needs one.
- OpenECS changes often. Know what it and its standard plugins can do, and read them again before you rely on them: [OVERVIEW.md](https://github.com/omerfuyar/OpenECS/blob/dev/OVERVIEW.md), [DESIGN.md](https://github.com/omerfuyar/OpenECS/blob/dev/DESIGN.md) and [OpenECS-std's DESIGN.md](https://github.com/omerfuyar/OpenECS-std/blob/dev/DESIGN.md). Do not bind ONLR's design to it: only DESIGN.md's section on the editor depends on OpenECS, and it links to OpenECS's documents and repeats nothing of theirs.
- The user of ONLR knows LÖVE, or learns it. Keep LÖVE's names and ways, so what they know stays true. They never see OpenECS's internals.
- Before recommending a library for the engine, check LÖVE first, as OpenECS's file says of SDL. Dependencies stay few (OVERVIEW 9).

**Working with the owner**

- Ask whenever instructions clash, in the same batch as the other questions.
- The owner is new to LÖVE and to engine design. Explain what a decision means for a game's author, not only what it is.

**Checks**

- Test little. Run a test only when a decision depends on its result, and never the same thing twice.
- The owner runs experiments on their own computer when asked. Give exact steps: the files, the commands, and what to report back.
- OpenECS's checks and scripts are not in this repository yet (TODO.md, Tasks). Until they are, a change is checked by reading it: links, section numbers and cross-references.

**Git**

- There are two long-lived branches. `dev` is the default, where work is merged. `main` holds what is stable.
- Merge your own work into `dev`, as the owner allowed. Open the pull request from `dev` into `main` when the owner asks; the owner merges it.
- No releases are planned, so nothing here follows OpenECS's releases or its release descriptions.
