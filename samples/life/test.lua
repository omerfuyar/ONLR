-- Checks the life of a component (DESIGN 6.4): the order of the calls, turning off, pausing, removing and destroying.
local check = require("check")
local onlr = require("onlr")
local log = require("shared.log")

check.run(function()
  local tree = onlr.tree
  local root = tree.root
  local a, b, c = tree.find("A"), tree.find("B"), tree.find("C")

  -- The top node loads first, then the root. All load before any enable, and start comes when both have loaded.
  check.equal(log.take(), {
    "Keeper.load", "Keeper.enable",
    "Root.load", "A.load", "A.needy load, log true", "A1.load", "B.load", "C.load",
    "Root.enable", "A.enable", "A1.enable",
    "Keeper.start", "Root.start", "A.start", "A1.start",
  }, "loading")
  check.equal(tree.top.name, "Top", "the top node")
  check.equal(root:getParent(), tree.top, "the root is under the top node")
  check.equal(b:isActive(), false, "B is off")
  check.equal(c.components.log:isEnabled(), false, "C's log is off")

  -- A frame: each function for the whole tree before the next, in the tree's order.
  check.frames(1)
  local lines = log.take()
  local wanted = {}
  for _, name in ipairs({ "update", "lateUpdate", "draw" }) do
    for _, node in ipairs({ "Keeper", "Root", "A", "A1" }) do
      wanted[#wanted + 1] = node .. "." .. name
    end
  end
  local got = {}
  for _, line in ipairs(lines) do
    if not line:find("fixedUpdate") then
      got[#got + 1] = line
    end
  end
  check.equal(got, wanted, "one frame")

  -- Turning a node off takes effect at once, children first; on again, parents first, with updates from the next frame.
  a:setActive(false)
  check.equal(log.take(), { "A1.disable", "A.disable" }, "setActive(false)")
  check.equal(tree.find("A1"):isActive(), false, "a node under a node that is off")
  a:setActive(true)
  check.equal(log.take(), { "A.enable", "A1.enable" }, "setActive(true)")
  check.frames(1)
  lines = log.take()
  check.ok(not table.concat(lines, " "):find("A.update", 1, true), "no update in the frame it was turned on")
  check.ok(not table.concat(lines, " "):find("A.start", 1, true), "start is called once")
  check.frames(1)
  check.ok(table.concat(log.take(), " "):find("A.update", 1, true), "updates from the next frame on")

  -- A component is turned on and off the same way. C's log starts when it is first turned on.
  c.components.log:setEnabled(true)
  check.equal(log.take(), { "C.enable" }, "setEnabled(true)")
  check.frames(1)
  check.ok(table.concat(log.take(), " "):find("C.start", 1, true), "start at the end of the frame")
  c.components.log:setEnabled(false)
  check.equal(log.take(), { "C.disable" }, "setEnabled(false)")

  -- A paused node still draws, and gets no update or event. Pausing calls neither enable nor disable.
  root:setPaused(true)
  check.equal(a:isPaused(), true, "a node under a paused node")
  love.event.push("keypressed", "x", "x", false)
  check.frames(2)
  lines = log.take()
  local text = table.concat(lines, " ")
  check.ok(text:find("Keeper.update", 1, true) and text:find("Keeper.keypressed", 1, true), "the top node's own nodes run on")
  check.ok(not text:find("Root.update", 1, true) and not text:find("A.keypressed", 1, true), "a paused node gets no update or event")
  check.ok(text:find("Root.draw", 1, true) and text:find("A1.draw", 1, true), "a paused node draws")
  check.ok(not text:find("able", 1, true), "pausing calls neither enable nor disable")
  root:setPaused(false)
  check.frames(2)
  check.ok(table.concat(log.take(), " "):find("Root.update", 1, true), "resumed")

  -- node:send calls a function of the components' own.
  a:send("ping", 7)
  check.equal(log.take(), { "A.ping 7" }, "node:send")

  -- components: a missing component is nil, a folder's table is always there, and a misspelt name is an error.
  check.equal(a.components.group.member, nil, "a type that the node lacks")
  check.equal(a.components.onlr.sprite, nil, "the engine's types")
  check.fails(function() return a.components.lgo end, "no component type lgo", "a misspelt type")
  check.fails(function() return a.components.group.membre end, "no component type group.membre", "a misspelt type in a folder")
  check.fails(function() a.components.group.member = {} end, "cannot be changed", "an empty table of components cannot be changed")
  check.fails(function() a:addComponent("log") end, "already has", "a second component of a type")

  -- addComponent: needs are added with it, and load and enable are called before it returns.
  b:setActive(true)
  log.take()
  local node = tree.newNode("New")
  check.equal(node:getParent(), root, "a new node is under the root")
  local needy = node:addComponent("needy")
  check.equal(log.take(), { "New.load", "New.needy load, log true", "New.enable" }, "addComponent")
  check.equal(node.components.needy, needy, "the new component")
  check.fails(function() node:removeComponent("log") end, "needs its log", "removing what another needs")

  -- removeComponent: the component stays until the frame ends.
  node:removeComponent("needy")
  check.equal(node.components.needy, needy, "it stays until the frame ends")
  check.frames(1)
  check.equal(node.components.needy, nil, "then it is gone")
  check.ok(table.concat(log.take(), " "):find("New.needy destroy", 1, true), "its destroy was called")
  node:addComponent("needy")
  log.take()

  -- destroy: the node is marked at once, and ends when the frame ends, children first.
  a:destroy()
  check.equal(a:isDestroyed() and tree.find("A1"):isDestroyed(), true, "marked at once")
  check.equal(tree.find("A"), a, "it stays in the tree until the frame ends")
  check.frames(1)
  lines = log.take()
  local ends = {}
  for _, line in ipairs(lines) do
    if line:find("disable") or line:find("destroy") then
      ends[#ends + 1] = line
    end
  end
  check.equal(ends, { "A1.disable", "A.disable", "A1.destroy", "A.needy destroy", "A.destroy" }, "destroying")
  check.equal(tree.find("A"), nil, "taken out of the tree")
  check.fails(function() root:destroy() end, "loadRoot", "the root is not destroyed")
  check.fails(function() root:setParent(node) end, "cannot be moved", "the root cannot be moved")

  -- setParent: a node moved under the top node outlives the root.
  b:setParent(tree.top, 1)
  check.equal(tree.top:getChildren()[1], b, "moved to the first place")
  check.fails(function() b:setParent(b) end, "under itself", "a node under itself")

  -- loadRoot: the old root ends when the frame ends, and the top node's own nodes stay.
  tree.loadRoot("nodes/second.lua")
  check.equal(tree.root, root, "the root stays until the frame ends")
  log.take()
  check.frames(1)
  lines = log.take()
  text = table.concat(lines, " ")
  check.equal(tree.root.name, "Second", "the new root")
  check.ok(text:find("Root.destroy", 1, true) and text:find("New.destroy", 1, true), "the old root was destroyed")
  check.ok(text:find("Second.load Second.enable Second.start", 1, true), "the new root loaded and started")
  check.ok(not text:find("Keeper.destroy", 1, true) and not text:find("B.destroy", 1, true), "the top node's own nodes stay")
  check.equal(tree.top:getChildren()[#tree.top:getChildren()], tree.root, "the root is the top node's last child")
  check.equal(#tree.findAllComponents("log"), 3, "findAllComponents")
  check.equal(tree.findComponent("log"), b.components.log, "findComponent gives the first in the tree's order")
end)
