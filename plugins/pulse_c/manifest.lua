-- A native plugin's manifest: the same fields, with type = "native".
---@type ecs.Manifest
return {
  name = "pulse_c",
  version = "0.1.0",
  api = 2,
  type = "native", -- its code is libpulse_c.so in this folder, which shuild.c builds from Pulse.c
  description = "A panel in C that counts the seconds it has been open",
  depends = { draw = "0.1" },
}
