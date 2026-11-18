-- An explosion: an emitter that emits at once and stops, and goes when its last particle dies.
---@type onlr.NodeFile
return {
  format = 1,
  id = "bur5t0",
  name = "Burst",
  components = {
    burst = {},
    particles = {
      emitter = {
        colors = { { 1, 0.8, 0.3, 1 }, { 1, 0.3, 0.1, 0 } },
        emissionRate = 400,
        emitterLifetime = 0.1,
        particleLifetime = { max = 0.8, min = 0.4 },
        sizes = { 1.5, 0.5 },
        speed = { max = 220, min = 80 },
        spread = 6.2832,
      },
    },
  },
}
