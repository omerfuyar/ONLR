-- A data file that changes string for itself changes it for no other file. getmetatable gives nothing for a text, so the
-- file cannot reach the strings' table, which is the game's string, either.
string.upper = nil
local strings = getmetatable("")
if strings then
  strings.__index.lower = nil
end
return {
  format = 1,
  reached = strings ~= nil,
}
