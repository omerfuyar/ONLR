-- A node file that a person wrote: it computes its table, 5000 nodes in groups of 50 (DESIGN 4.1).
-- Each node has a sprite and a script, and every tenth has a z of its own.
local groups = {}
local count = 0

for g = 1, 100 do
  local children = {}
  for i = 1, 50 do
    count = count + 1
    children[i] = {
      id = ("n%05d"):format(count),
      name = "Dot",
      posX = i * 6,
      z = count % 10 == 0 and 1 or nil,
      components = {
        mover = {
          speed = 10 + count % 20,
        },
        onlr = {
          sprite = {
            image = "images/dot.png",
          },
        },
      },
    }
  end
  groups[g] = {
    id = ("g%05d"):format(g),
    name = "Row",
    posY = g * 2,
    children = children,
  }
end

---@type onlr.NodeFile
return {
  format = 1,
  id = "st4rt0",
  name = "Start",
  components = {
    onlr = {
      camera = {
        posX = 160,
        posY = 120,
      },
    },
  },
  children = groups,
}
