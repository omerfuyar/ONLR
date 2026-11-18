---@type onlr.Project
return {
  format = 1,
  name = "Gallery",
  id = "org.onlr.samples.gallery",
  gameVersion = "0.1.0",
  loveVersion = "11.5",
  startNode = "nodes/rooms/01_nodes.lua",
  topNode = "nodes/top.lua",
  window = {
    height = 540,
    resizable = true,
    width = 960,
  },
  -- its pictures are pixel art, which the scale of 1.5 would blur
  defaultFilter = "nearest",
}
