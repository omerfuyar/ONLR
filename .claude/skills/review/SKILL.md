---
name: review
description: Review an area of ONLR - the engine, the runner and the link, the editor, export, the packages, the samples and the build, or the documents against the code - and record what to improve in TODO.md's Review. Use when asked to review, audit or find improvements. It changes no code.
---

# Review an area

OpenECS's review skill (`../OpenECS/.claude/skills/review/SKILL.md`) holds the method: what to read, what to look for in its order, how to split the work among agents and check each finding at its lines, and the form of a finding. This names ONLR's areas.

| Area | Files | DESIGN |
| ---- | ----- | ------ |
| Engine | `packages/onlr/` | 5 to 10 |
| Runner and link | `plugins/onlr/runner/`, `link.lua`, `runners.lua` | 12 |
| Editor | the rest of `plugins/onlr/`, `preset.lua` | 4, 13 |
| Export | `export.lua`, `runtimes.lua` | 14, 15 |
| Packages | `packages/*/components/`, ONLR's edits of a library | 11 |
| Samples and build | `samples/`, `shuild.c`, `.github/` | 16, 17 |
| Documents | OVERVIEW, DESIGN, GUIDE, README, hints and descriptions | all |

- Prove speed with the measure skill, and what a user sees with the verify skill's screenshots.
- The editor stands on OpenECS: read OpenECS's and OpenECS-std's DESIGN where it relies on them, and note what their newest features would make simpler.
- A finding is a line of TODO.md's `## Review`, under its area, P1 first: P1 a bug or a design flaw that grows with each feature, P2 worth doing before ONLR's first release, P3 when the code is touched; each with its lines, which way to fix it, and its Size.
