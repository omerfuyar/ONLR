-- Checks a node's place in the world (DESIGN 7 and 8.2): toWorld, toLocal, setWorldPosition and setParent.
local check = require("check")
local onlr = require("onlr")

check.run(function()
  local tree = onlr.tree
  local parent, child, other = assert(tree.find("Parent")), assert(tree.find("Child")), assert(tree.find("Other"))

  -- A child's place is in its parent: it moves, turns and scales with it.
  check.equal({ tree.root:toWorld(0, 0) }, { 100, 50 }, "the root's place")
  check.equal({ parent:toWorld(0, 0) }, { 110, 70 }, "a node's place in the world")
  -- The parent is turned a quarter clockwise and twice as large: its x axis points down.
  check.equal({ child:toWorld(0, 0) }, { 110, 80 }, "a child of a turned and scaled node")
  check.equal({ child:toWorld(1, 0) }, { 110, 82 }, "a point of the child's space")
  check.equal({ child:toLocal(110, 82) }, { 1, 0 }, "toLocal turns it back")
  check.equal({ parent:toLocal(parent:toWorld(3, 4)) }, { 3, 4 }, "there and back")

  -- The place is plain fields: the engine works the world out again when one changed.
  parent.posX = 20
  check.equal({ child:toWorld(0, 0) }, { 120, 80 }, "after the parent moved")
  tree.root.posY = 0
  check.equal({ child:toWorld(0, 0) }, { 120, 30 }, "after the root moved")

  -- setWorldPosition moves a node to a point of the world, whatever its parents' places are.
  child:setWorldPosition(200, 100)
  check.equal({ child:toWorld(0, 0) }, { 200, 100 }, "setWorldPosition")
  check.equal({ child.posX, child.posY }, { 40, -40 }, "which sets the place in the parent")

  -- setParent keeps the node's own place, so it moves with its new parent.
  child:setParent(other)
  check.equal(child:getParent(), other, "the new parent")
  check.equal({ child:toWorld(0, 0) }, { 100 - 30 + 20, -20 }, "its own place, in the new parent")
  child:setWorldPosition(200, 100)
  check.equal({ child:toWorld(0, 0) }, { 200, 100 }, "setWorldPosition after keeps it where it was")
  child:setParent(parent, 1)
  check.equal(parent:getChildren()[1], child, "setParent to an index")
end)
