-- A script's properties: the inspector shows a control for each kind, and the node view draws what they say.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m03",
  name = "Scripts",
  components = {
    room = {
      about = "components/showcase.lua declares properties of many kinds. Open this room in the editor and change them.",
      title = "Scripts and properties",
    },
  },
  children = {
    {
      id = "sh0wc0",
      name = "Row",
      posX = 80,
      posY = 140,
      components = {
        showcase = {
          colors = { { 0.9, 0.3, 0.35, 1 }, { 0.3, 0.6, 0.95, 1 } },
          follow = "t4rg3t",
        },
      },
    },
    {
      id = "t4rg3t",
      name = "Target",
      posX = 420,
      posY = 280,
      components = {
        onlr = {
          paint = { color = { 0.4, 0.9, 0.5, 1 } },
          shape = { kind = "circle", radius = 6 },
        },
      },
    },
  },
}
