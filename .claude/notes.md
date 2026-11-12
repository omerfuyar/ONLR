# Notes

Notes for agents and the owner that belong in no other document: why the tools are set up as they are. A tool made from the template may keep, change or remove this file.

## Tools

- `.github/scripts/check.sh` gives clang-tidy the flags of `shuild.c`. It reads OpenECS's headers, the plugins' definition headers among them, from the release that `OPENECS` names, as `shuild.c`'s `-o` does.
- The checks follow OpenECS-std's: its `.clang-tidy`, and its names for a plugin's functions (OpenECS-std DESIGN.md, section 1.3).
- The check `Format` uses clang-format 18, Ubuntu 24.04's. Another version may format some lines differently; format with 18.
