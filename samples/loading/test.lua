-- Checks loading (DESIGN 6.2): a file loads once, a preloaded node file loads with its holder,
-- and when the root changes the engine keeps the files that the new root names and lets go of the others.
local check = require("check")
local onlr = require("onlr")
local data = require("onlr.data")

check.run(function()
  local holder = onlr.tree.root.components.holder
  local one = holder.picture

  -- The root's own files, and those of the node file that it preloads.
  check.equal(data.isLoaded("image:images/one.png"), true, "the root's image")
  check.equal(data.isLoaded("node:nodes/bullet.lua"), true, "the preloaded node file")
  check.equal(data.isLoaded("image:images/two.png"), true, "the image that the preloaded node file names")
  check.equal(data.isLoaded("node:nodes/spark.lua"), false, "a node file without preload waits")
  check.equal(data.isLoaded("image:images/three.png"), false, "and so do its files")

  -- A node file without preload loads when it is first spawned.
  local spark = onlr.tree.spawn(holder.later)
  check.equal(data.isLoaded("image:images/three.png"), true, "loaded at the first spawn")
  local bullet = onlr.tree.spawn(holder.ahead)
  check.equal(bullet.components.holder.picture:typeOf("Image"), true, "a spawn of the preloaded file")
  check.equal(spark.name, "Spark", "the spawned node")

  -- The root changes: the new root names one.png too, so it is kept, and the others are let go.
  onlr.tree.loadRoot("nodes/next.lua")
  check.frames(1)
  check.equal(onlr.tree.root.name, "Next", "the new root")
  check.equal(onlr.tree.root.components.holder.picture, one, "a file that both roots name is kept")
  check.equal(data.isLoaded("image:images/two.png"), false, "a file that only the old root named is let go")
  check.equal(data.isLoaded("image:images/three.png"), false, "and one that it spawned")
  check.equal(data.isLoaded("node:nodes/bullet.lua"), false, "and the preloaded node file")
end)
