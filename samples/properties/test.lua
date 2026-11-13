-- Checks properties (DESIGN 6.2): every kind, defaults, options, and what a component gets for each.
local check = require("check")
local onlr = require("onlr")
local component = require("onlr.component")

check.run(function()
  local first = assert(onlr.tree.find("First")).components.every
  local second = assert(onlr.tree.find("Second")).components.every
  local Every = require("components.every")

  -- The engine put each default in its declaration's place.
  check.equal(Every.speed, 1.5, "a default in the type")
  check.equal(Every.picture, nil, "a reference has no default")
  check.equal({ Every.plainBool, Every.plainNumber, Every.plainString, Every.plainColor }, { false, 0, "", { 1, 1, 1, 1 } },
    "the defaults of kinds that are given none")

  -- The inspector's order is the order of declaration.
  local names = {}
  for i, p in ipairs(component.type("every").properties) do
    names[i] = p.name
  end
  check.equal({ names[1], names[2], names[3], names[#names] }, { "flag", "count", "speed", "plainColor" }, "the order of declaration")
  check.equal(component.type("every").properties[3].decl.options.label, "Top speed", "an option")

  -- A component holds the values that its node file gives, and finds the others in its type.
  check.equal({ first.flag, first.count, first.speed, first.title, first.side }, { false, 7, 1.5, "hello", "right" }, "values")
  check.equal(rawget(first, "speed"), nil, "a default is found in the type")
  check.equal(first.tint, { 0, 0, 1, 1 }, "a colour")
  check.equal(second.tint, { 1, 0.5, 0, 1 }, "a colour's default")
  second.tint[1] = 0
  check.equal(Every.tint[1], 1, "a default that is a table is copied into each component")
  check.equal(first.offset, { x = 2, y = 3 }, "a vector")
  check.equal(first.points, { { x = 1, y = 2 } }, "a list of vectors")
  check.equal(second.points, {}, "a list's default is empty")
  check.equal(first.gone, nil, "a value that the type no longer declares is not given")

  -- References: the component gets what the value names.
  check.equal(first.picture:typeOf("Image"), true, "an image")
  check.equal(first.picture, first.frames[2], "components that name the same file share it")
  check.equal(first.beep:typeOf("Source"), true, "a sound")
  check.ok(first.beep ~= second.beep, "each component gets a source of its own")
  check.equal(first.font:getHeight() > second.font:getHeight(), true, "a font of the node file's size, and one of the option's")
  check.equal(second.font:typeOf("Font"), true, "without a file, LÖVE's default font")
  check.equal({ first.notes, first.next }, { "notes.txt", "nodes/start.lua" }, "a file and a node file are their paths")
  check.equal(first.target, onlr.tree.find("Second"), "a node, from its id")
  check.equal(first.other, second, "a component, from its node's id")
  check.equal(second.target, nil, "a reference that is not set")

  -- A group is a table with a field for each of its properties; the node file holds those that differ.
  check.equal({ first.box.width, first.box.height }, { 64, 16 }, "a group")
  check.equal(first.box.picture, first.picture, "a reference in a group")
  check.equal(second.box, { width = 32, height = 16 }, "a group's defaults")

  -- A property is a plain field, which other components read and set.
  second.count = 9
  check.equal(assert(onlr.tree.find("Second")).components.every.count, 9, "set as a plain field")

  -- An option that the kind does not take is an error when the type loads.
  check.fails(function() onlr.property.number(1, { choices = {} }) end, "a number takes no option choices", "an option of another kind")
  check.fails(function() onlr.property.string("", { lable = "x" }) end, "takes no option lable", "a misspelt option")
  check.fails(function() onlr.property.choice("up", { choices = { "left" } }) end, "not one of the choices", "a default that is no choice")
  check.fails(function() onlr.property.choice("up") end, "needs its choices", "a choice without choices")
  check.fails(function() onlr.property.integer(1.5) end, "whole number", "an integer's default")
  check.fails(function() onlr.property.list(5) end, "one property", "a list of no property")

  -- A path or an id that names nothing is an error, which names the node file, the node and the property.
  check.fails(function() onlr.tree.spawn("nodes/missing.lua") end, "nodes/missing.lua, node Mistake, property picture: images/nothing.png: no such file", "a missing file")
  check.fails(function() onlr.tree.spawn("nodes/badid.lua") end, "property target: the id n0such names no node", "an id of no node")
  check.fails(function() onlr.tree.spawn("nodes/badtype.lua") end, "property count: a integer, not a string", "a value of another kind")

  -- addComponent takes values as the component gets them; an image may be its path.
  local node = onlr.tree.newNode("Made")
  local made = node:addComponent("every", { count = 4, picture = "images/dot.png", tint = { 0, 1, 0, 1 } })
  check.equal({ made.count, made.speed, made.tint[2] }, { 4, 1.5, 1 }, "addComponent's values")
  check.equal(made.picture, first.picture, "addComponent loads a path")
  check.equal(made.font:typeOf("Font"), true, "and gives the defaults")
end)
