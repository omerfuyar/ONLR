-- shadows: the room is dark but where two lights reach, and shapes in their way cast shadows.
---@type onlr.NodeFile
return {
  format = 1,
  id = "r00m15",
  name = "Lights",
  components = {
    room = {
      about = "shadows.world darkens the room. A white lamp circles the shapes, and a red beam sweeps; a box, a circle and a polygon cast shadows.",
      title = "Light and shadows (shadows)",
    },
    shadows = {
      world = {
        color = { 0.08, 0.08, 0.12, 1 },
      },
    },
  },
  children = {
    {
      id = "gr0d15",
      name = "Ground",
      posY = 54,
      components = {
        onlr = {
          shape = {
            color = { 0.85, 0.85, 0.8, 1 },
            height = 306,
            width = 640,
          },
        },
      },
    },
    {
      id = "b0x015",
      name = "Box",
      posX = 260,
      posY = 170,
      components = {
        onlr = {
          shape = {
            color = { 0.3, 0.5, 0.8, 1 },
            height = 40,
            width = 40,
          },
        },
        shadows = {
          shape = {
            box = { height = 40, width = 40 },
          },
        },
      },
    },
    {
      id = "c1rc15",
      name = "Circle",
      posX = 380,
      posY = 260,
      components = {
        onlr = {
          shape = {
            color = { 0.8, 0.5, 0.3, 1 },
            kind = "circle",
            radius = 22,
          },
        },
        shadows = {
          shape = {
            circle = { radius = 22 },
          },
        },
      },
    },
    {
      id = "p0ly15",
      name = "Triangle",
      posX = 420,
      posY = 150,
      components = {
        onlr = {
          shape = {
            color = { 0.4, 0.7, 0.4, 1 },
            kind = "polygon",
            points = { { x = 0, y = -24 }, { x = 22, y = 16 }, { x = -22, y = 16 } },
          },
        },
        shadows = {
          shape = {
            polygon = {
              points = { { x = 0, y = -24 }, { x = 22, y = 16 }, { x = -22, y = 16 } },
            },
          },
        },
      },
    },
    -- The lamp is a child of a node that turns, so it circles the middle.
    {
      id = "sw1n15",
      name = "Swing",
      posX = 340,
      posY = 205,
      components = {
        spin = { speed = 0.6 },
      },
      children = {
        {
          id = "l4mp15",
          name = "Lamp",
          posX = 130,
          components = {
            shadows = {
              light = { radius = 260 },
            },
          },
        },
      },
    },
    -- A beam turns with its node.
    {
      id = "b34m15",
      name = "Beam",
      posX = 60,
      posY = 330,
      components = {
        shadows = {
          light = {
            arc = 50,
            color = { 1, 0.3, 0.2, 1 },
            radius = 420,
          },
        },
        spin = { speed = 0.4 },
      },
    },
  },
}
