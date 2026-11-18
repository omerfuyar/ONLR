-- Checks instances (DESIGN 9): changes laid over a base, added components and children, variants,
-- instances inside instances, and ids read in the file that writes them.
local check = require("check")
local onlr = require("onlr")

check.run(function()
  local tree = onlr.tree
  local children = tree.root:getChildren()
  local plain, changed, variant, chest, watcher = children[2], children[3], children[4], children[5], children[6]

  -- An instance is the base's nodes with the changes laid over them.
  check.equal({ plain.name, plain.posX, plain.posY, plain.components.coin.worth }, { "Coin", 400, 540, 1 }, "a change of the place")
  check.equal({ changed.name, changed.posX, changed:getZ(), changed.components.coin.worth }, { "Changed coin", 700, 3, 5 }, "changed values")
  check.equal(changed.components.coin.box, { width = 16, height = 32 }, "a group is laid over field by field")
  check.equal(changed.components.spin.speed, 2, "a component that the instance adds")
  check.equal(plain.components.spin, nil, "which no other instance has")

  -- Children that a change adds come after the base's, and what the instance does not want is turned off.
  local names = {}
  for i, child in ipairs(changed:getChildren()) do
    names[i] = child.name
  end
  check.equal(names, { "Glint", "Flag" }, "an added child")
  check.equal(changed:getChildren()[1]:isActive(), false, "a node of the base that is turned off")
  check.equal(plain:getChildren()[1]:isActive(), true, "and is on in another instance")

  -- An id is read in the file that writes it: each coin names its own glint, and a change names a node of the level.
  check.equal(plain.components.coin.glint, plain:getChildren()[1], "each instance's own node")
  check.equal(changed.components.coin.glint, changed:getChildren()[1], "each instance's own node, again")
  check.equal(changed.components.coin.owner, tree.find("Player"), "a change's id is of the file that holds the instance")

  -- From outside, a node inside an instance is named by a path, and its first node by the instance's id.
  check.equal(watcher.components.watcher.coin, changed, "the instance's first node")
  check.equal(watcher.components.watcher.glint, changed:getChildren()[1], "a node inside an instance")

  -- A variant: the bigger coin, changed again where the level holds it.
  check.equal({ variant.name, variant.sclX, variant.posX, variant.components.coin.worth }, { "Big coin", 2, 50, 5 }, "a variant")
  check.equal(variant:getChildren()[1].name, "Big glint", "a change through a variant")

  -- An instance inside an instance: the inner one's own changes are laid over first, then the outer one's.
  local inner = chest:getChildren()[1]
  check.equal({ inner.name, inner.posX, inner.posY, inner.components.coin.worth }, { "Chest coin", 10, 7, 2 }, "an inner instance")
  local glint = inner:getChildren()[1]
  check.equal({ glint.name, glint.posX, glint.posY }, { "Chest glint", 2, 3 }, "the outer change wins")
  check.equal(watcher.components.watcher.inner, inner.components.coin, "a component, by a path")

  -- spawn makes an instance while the game runs.
  local spawned = tree.spawn("nodes/bigcoin.lua", 30, 40)
  check.equal({ spawned.name, spawned.posX, spawned.posY, spawned:getParent() }, { "Big coin", 30, 40, tree.root }, "spawn")
  check.equal(spawned.components.coin.glint, spawned:getChildren()[1], "its ids are its own")
  check.equal(#tree.findAll("Big coin"), 2, "an instance's nodes are nodes of the tree")
  check.equal(#tree.findAllComponents("coin"), 5, "and so are their components")

  -- What cannot be made says why.
  check.fails(function() tree.spawn("nodes/self.lua") end, "cannot hold itself", "a node file that holds itself")
  check.fails(function() tree.spawn("nodes/lost.lua") end, "changes n0such, which names no node", "a change that names no node")
  check.fails(function() tree.spawn("nodes/none.lua") end, "no such file", "a missing node file")
end)
