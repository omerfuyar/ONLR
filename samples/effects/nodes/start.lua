-- The moonshine package's sample: a red square under a node that draws through two effects, desaturate and
-- colorgradesimple, at a place that is not the window's corner.
---@type onlr.NodeFile
return {
  format = 1,
  id = "eff000",
  name = "Start",
  children = {
    {
      id = "sc3ne0",
      name = "Scene",
      posX = 40,
      posY = 30,
      components = {
        moonshine = {
          chain = {},
          effect = {
            colorgradesimple = {},
            desaturate = {
              strength = 1,
            },
          },
        },
      },
      children = {
        {
          id = "squ4re",
          name = "Square",
          components = {
            onlr = {
              shape = {
                color = { 1, 0, 0, 1 },
                height = 10,
                width = 10,
              },
            },
          },
        },
      },
    },
  },
}
