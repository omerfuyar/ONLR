-- The project file. Data only: the editor reads it with its own Lua, and the game with LuaJIT.
-- The first line names the type, so a code editor completes and checks the fields.
---@type onlr.Project
return {
  format = 1,
  name = "Coin run",
  id = "org.example.coinrun",
  version = "0.1.0",
  love = "11.5",
  engine = "0.1.0",
  scene = "scenes/level.scene.lua",
  width = 1280,
  height = 720,
  exclude = { "notes/*" },
}
