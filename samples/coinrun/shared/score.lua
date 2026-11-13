-- Not a component, so not in components/: a plain Lua module, as in any LÖVE game.
-- What must outlive the root lives in such a module, since require gives the same table every time.
return {
  coins = 0,
}
