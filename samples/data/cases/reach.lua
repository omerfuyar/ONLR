-- A data file cannot reach LÖVE, the engine or another file: these names are nil here.
return {
  format = 1,
  love = love ~= nil,
  require = require ~= nil,
  io = io ~= nil,
  os = os ~= nil,
  loadstring = loadstring ~= nil,
  getfenv = getfenv ~= nil,
  sum = math.max(1, 2) + #table.concat({ "a", "b" }),
}
