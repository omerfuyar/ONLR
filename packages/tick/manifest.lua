-- The package's manifest. Data only: the editor reads it, and the game never loads it.
---@type onlr.Package
return {
  format = 1,
  name = "tick",
  description = "Timers: a function called after a delay, or every few seconds",
  -- The package's own version, which grows when ONLR changes the package, and the licence of ONLR's files in it.
  version = "0.1.0",
  license = "0BSD",
  -- The library that it wraps, as its author ships it in library/: its version, where it comes from, and its licence.
  library = {
    version = "0.1.1",
    source = "https://github.com/rxi/tick",
    license = "MIT",
  },
  -- Its component type is the file of components/: components/timers.lua is tick.timers.
}
