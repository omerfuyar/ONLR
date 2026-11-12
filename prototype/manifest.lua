-- The project's manifest. Data only: the editor reads it with its own Lua, and the game with LuaJIT.
-- The first line names the type, so a code editor completes and checks the fields.
---@type onlr.Project
return {
  format = 1,
  name = "Coin run",
  id = "org.example.coinrun",
  version = "0.1.0",
  love = "11.5",
  scene = "scenes/level.scene.lua",
  -- In the names of LÖVE's t.window. LÖVE needs the size before it opens the window,
  -- and the editor's game panel draws the game at this size.
  window = { width = 1280, height = 720 },
  exclude = { "notes/*" },
}
