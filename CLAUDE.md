# CLAUDE.md

Instructions for AI agents working in this repository. Read this file fully before doing anything.

This repository is the template of OpenECS's tools. OpenECS's [CLAUDE.md](https://github.com/omerfuyar/OpenECS/blob/dev/CLAUDE.md) applies here in full: how to work with the owner, the boundaries, git and writing documents. Read it first. This file names only what is different here.

A tool made from this template is its owner's own repository; its owner may keep, change or remove this file.

## Where things are

| Path                   | What it holds                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| [README.md](README.md) | Short introduction, and how to run the tool.                                                                             |
| [GUIDE.md](GUIDE.md)   | The guide: how to make a tool from the template, one part at a time.                                                     |
| `preset.lua`           | The tool's preset.                                                                                                       |
| `plugins/`             | The tool's plugins, one folder each.                                                                                     |
| `test.lua`             | The tool's test.                                                                                                         |
| `shuild.c`             | Builds the plugins in C, with shuild.                                                                                    |
| `dependencies/`        | Submodules: shuild and shu, which `shuild.c` builds with.                                                                |
| `.github/`             | Checks, rulesets and the agents' check script.                                                                           |
| `.clang-format`        | How clang-format formats the C code, as OpenECS's does.                                                                  |
| `.clang-tidy`          | What clang-tidy checks in the C code: OpenECS-std's names for a plugin's functions, and common bugs.                     |
| `.claude/`             | Claude Code's settings and notes: it formats each C file it edits; `notes.md` says why the tools are set up as they are. |
| `LICENSE.md`           | The license, zlib.                                                                                                       |

OpenECS's OVERVIEW.md and DESIGN.md hold how OpenECS works. Before you propose or change anything, read their Contents, then every section the task touches.

## Differences

- The template follows OpenECS's `dev`: a change to OpenECS's plugin interface changes the template in the same piece of work, so its test passes.
- The template is not released with OpenECS: its `main` is what "Use this template" copies. `dev` is merged into `main` with a pull request that the owner reviews.
- The guide is for people who start a tool. It explains each part the first time it appears, and links to OpenECS's documents for the details, so one source of truth stays in OpenECS.
- Before each commit, run `.github/scripts/check.sh`: it formats the changed C files of `plugins/` and checks them with clang-tidy, and checks the changed Lua files with the Lua language server when it is installed. Both need OpenECS's release, as `shuild.c` does.
- The files' comments explain what OpenECS does with each part, as the examples' comments do (OpenECS DESIGN.md, section 17.6).
