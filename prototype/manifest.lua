-- The project's manifest. The editor reads it with its own Lua, and the game with LuaJIT.
-- A person may compute a value here, in Lua that both run. When the editor saves the file,
-- it writes the values only: code and comments such as these are not kept, so it asks first.
-- The line above return names the type, so a code editor completes and checks the fields.
---@type onlr.Project
return {
  format = 1,
  name = "Coin run",
  id = "org.example.coinrun",
  -- Two versions, each named for what it is the version of.
  gameVersion = "0.1.0",
  loveVersion = "11.5",
  -- The node file that the game starts with: its node is the first root.
  startNode = "nodes/level.lua",
  -- The node file of the top node, which the game loads once and keeps, and under which each root runs.
  topNode = "nodes/game.lua",
  -- In the names of LÖVE's t.window. LÖVE needs the size before it opens the window,
  -- and the project settings panel shows and changes it.
  window = {
    height = 720,
    resizable = true,
    width = 1280,
  },
  -- Any other of LÖVE's settings, under LÖVE's names: this game uses no physics.
  modules = {
    physics = false,
  },
  -- As love.graphics.setDefaultFilter. The engine sets it in the game and in the node view,
  -- so pixel art is sharp in both. love.load runs only in the game.
  defaultFilter = "nearest",
  exclude = {
    "notes/*",
  },
}
