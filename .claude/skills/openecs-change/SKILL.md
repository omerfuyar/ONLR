---
name: openecs-change
description: Make a change in OpenECS, OpenECS-std or OpenECS-examples that ONLR needs, and bring it into ONLR. Use when a fix or a feature belongs in OpenECS or a standard plugin rather than in ONLR's editor.
---

# A change in OpenECS for ONLR

CLAUDE.md, section The project, says when: a fix or a feature that belongs there is made there, not worked around in ONLR.

1. Work in `../OpenECS`, with `std/` and `examples/`, from their `dev`, on a branch named as OpenECS's CLAUDE.md says. Its CLAUDE.md and skills apply there: interface-change for the plugin interface, submodule-bump for `std/` and `examples/`, verify and pull-requests. A feature works from C and from Lua alike (OpenECS DESIGN 11.5).
2. Test it in OpenECS-examples, in the same piece of work.
3. Land it in the order of OpenECS's pull-requests skill. std's checks build OpenECS's `dev` with its examples, and the examples' build its std, so a std change with its test is red on both sides until OpenECS's pull request moves `std/` and `examples/` to both branches; merge that first, then one pull request per repository.
4. Write nothing of ONLR's into OpenECS's documents.
5. Once it is in OpenECS's `dev`, build it and lay out `OpenECS/` again (the verify skill), then use it in ONLR. ONLR's checks build OpenECS's `dev`, so an ONLR pull request that relies on it waits for step 3.
