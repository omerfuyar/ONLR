-- What every effect type of the package shares: each is a component beside moonshine.chain on its node, whose
-- properties are the effect's parameters, named as moonshine names them. Required as require("moonshine.effect").
local effect = {}

---Makes a component type an effect of moonshine's, by the effect's name. params gives the parameters as moonshine
---takes them, from the component's properties; the chain sends each that changed, each frame.
---@param Type table the component type
---@param name string the effect's name in moonshine, such as "vignette"
---@param params fun(self: table): table<string, any>
function effect.declare(Type, name, params)
  Type.needs = { "moonshine.chain" }
  Type._effect = name
  Type._params = params

  function Type:load()
    self.node.components.moonshine.chain:_add(self)
  end

  function Type:destroy()
    local chain = self.node.components.moonshine.chain
    if chain then
      chain:_remove(self)
    end
  end
end

---A colour of the inspector, from 0 to 1, as the effects that take 0 to 255 take it.
---@param c number[]
---@return number[]
function effect.color255(c)
  return { c[1] * 255, c[2] * 255, c[3] * 255 }
end

---A vector of the inspector as the effects take two numbers.
---@param v {x: number, y: number}
---@return number[]
function effect.pair(v)
  return { v.x, v.y }
end

return effect
