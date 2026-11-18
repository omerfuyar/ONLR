-- What the components did, in order: each line is a node's name, a dot, and the function that was called.
local log = { lines = {} }

function log.add(line)
  log.lines[#log.lines + 1] = line
end

-- Gives the lines and starts an empty list.
function log.take()
  local lines = log.lines
  log.lines = {}
  return lines
end

return log
