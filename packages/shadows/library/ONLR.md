# ONLR's copy of Shädows

These are the files of [Shädows](https://github.com/matiasah/shadows)'s `src/shadows/`, at commit `ccb3597`
(2026-11-16), with its licence. They are changed so that the library sets no global, as every library in ONLR must
(TODO.md, Libraries), and so that it loads from a package's folder. ONLR maintains them.

Each change is marked with a comment that starts with `ONLR:`. To take a newer version, copy its `src/shadows/` here
and make the same changes:

1. Each file that starts with `module("shadows.X", package.seeall)` gets this line in its place, which keeps what the
   file defines in a table of its own, as `module` did, without the global `shadows` that `module` makes:

   ``` lua
   setfenv(1, setmetatable({}, { __index = _G })) -- ONLR: was module("shadows.X", package.seeall), which set the global shadows
   ```

   With sed, from this folder:

   ``` sh
   grep -rl '^module("shadows' --include='*.lua' . | xargs sed -i -E 's/^module\("(shadows[^"]*)", package\.seeall\)$/setfenv(1, setmetatable({}, { __index = _G })) -- ONLR: was module("\1", package.seeall), which set the global shadows/'
   ```

2. `init.lua` finds its files under `packages/` too, where a package's folder is, after its own test of `src/`.
3. `init.lua` preloads `shadows.BodyTransform`, which upstream finds by its path from the game's folder.

Then run the `lights` sample's test, which checks that the library sets no global.
