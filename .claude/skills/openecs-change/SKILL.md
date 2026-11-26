---
name: openecs-change
description: Make a change in OpenECS, OpenECS-std or OpenECS-examples that ONLR needs, and bring it into ONLR. Use when a fix or a feature belongs in OpenECS or a standard plugin rather than in ONLR's editor.
---

# A change in OpenECS for ONLR

CLAUDE.md, section The project, says when: a fix or a feature that belongs there is made there, not worked around in ONLR.

1. Work in `../OpenECS`, with `std/` and `examples/`, from their `dev`, on a branch named as OpenECS's CLAUDE.md says. Its CLAUDE.md and skills apply there: interface-change for the plugin interface, submodule-bump for `std/` and `examples/`, verify and pull-requests. A feature works from C and from Lua alike (OpenECS DESIGN 11.5).
2. Test it in OpenECS-examples, in the same piece of work.
3. Land it in the order of OpenECS's pull-requests skill: the branch has the same name in each repository, and OpenECS's moves `std/` and `examples/` to their heads. On a pull request, std's and the examples' checks build OpenECS's branch and each other's, so every pull request opens at once and the checks run together. std's and the examples' merge first, then OpenECS's, then the template's.
4. Write nothing of ONLR's into OpenECS's documents.
5. Build OpenECS from its branch and lay out `OpenECS/` again (the verify skill), then use it in ONLR, on a branch of the same name. On a pull request, ONLR's checks build OpenECS's branch of the same name, so ONLR's pull request opens with the others and merges after OpenECS's.
