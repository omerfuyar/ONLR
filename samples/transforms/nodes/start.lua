---@type onlr.NodeFile
return {
  format = 1,
  id = "st4rt0",
  name = "Start",
  posX = 100,
  posY = 50,
  children = {
    {
      id = "p4r3nt",
      name = "Parent",
      posX = 10,
      posY = 20,
      rot = math.pi / 2,
      sclX = 2,
      sclY = 2,
      children = {
        {
          id = "ch1ld0",
          name = "Child",
          posX = 5,
          posY = 0,
        },
      },
    },
    {
      id = "0th3r0",
      name = "Other",
      posX = -30,
      sclX = 0.5,
      sclY = 0.5,
    },
  },
}
