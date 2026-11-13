-- Checks reading data files in their sandbox (DESIGN 4.1), and onlr.conf, which gives LÖVE the manifest's settings (DESIGN 3.2).
local check = require("check")
local onlr = require("onlr")
local data = require("onlr.data")

check.run(function()
  -- The manifest computed its values, and onlr.conf gave them to LÖVE.
  check.equal(love.window.getTitle(), "Data FILES", "the window's title is the game's name")
  check.equal({ love.graphics.getDimensions() }, { 320, 240 }, "the window's size")
  local _, _, flags = love.window.getMode()
  check.equal(flags.resizable, true, "another field of LÖVE's t.window")
  check.equal(love.filesystem.getIdentity(), "org.onlr.samples.data", "LÖVE's identity is the manifest's id")
  check.equal(love.physics, nil, "LÖVE's modules, under LÖVE's name")
  check.equal(love.graphics.getDefaultFilter(), "nearest", "the default filter")
  check.equal(onlr.tree.root.name, "Start", "the start node is the root")
  check.equal(onlr.tree.top.name, "", "the top node is an empty node when the manifest names none")

  -- A data file runs with the basic functions and string, table and math, and nothing else.
  check.equal(data.read("cases/reach.lua"), {
    format = 1, love = false, require = false, io = false, os = false, loadstring = false, getfenv = false, sum = 4,
  }, "what a data file reaches")
  data.read("cases/spoil.lua")
  check.equal(string.upper("a"), "A", "a data file changes nothing for the game")
  check.equal(data.read("manifest.lua").name, "Data FILES", "nor for another data file")

  -- The engine reads only the format that it knows, and says so of another.
  check.fails(function() data.read("cases/format.lua") end, "format 99", "another format")
  check.fails(function() data.read("cases/notable.lua") end, "returns a table", "no table")
  check.fails(function() data.read("cases/missing.lua") end, "no such file", "a missing file")
  check.fails(function() data.run("return {", "cases/broken.lua") end, "cases/broken.lua", "a file that is not Lua names its path")
end)
