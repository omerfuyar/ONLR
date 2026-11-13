-- A manifest that a person wrote: it computes its values, in Lua that LuaJIT and the editor's Lua both run.
-- It runs with Lua's basic functions and string, table and math, and nothing else (DESIGN 4.1).
local scale = 2

---@type onlr.Project
return {
  format = 1,
  name = ("Data %s"):format(string.upper("files")),
  id = "org.onlr.samples.data",
  gameVersion = "0.1.0",
  loveVersion = "11.5",
  startNode = "nodes/start.lua",
  window = {
    height = math.floor(120 * scale),
    resizable = true,
    width = 160 * scale,
  },
  -- LÖVE's own settings, under LÖVE's names.
  modules = {
    physics = false,
  },
  defaultFilter = "nearest",
  fixedRate = 30,
}
