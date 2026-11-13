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
  scene = "scenes/level.scene.lua",
  -- In the names of LÖVE's t.window. LÖVE needs the size before it opens the window,
  -- and the project settings panel shows and changes it.
  window = {
    width = 1280,
    height = 720,
  },
  exclude = {
    "notes/*",
  },
}
