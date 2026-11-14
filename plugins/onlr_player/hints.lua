-- Hints for errors: what an error of Lua or LÖVE often means in a game, in plain words, and what to try.
-- Each hint has a pattern that the error's text matches, and a text; what the pattern captures fills the text's %s.

local hints = {}

local HINTS = {
  { "attempt to index local 'self' %(a (%w+) value%)",
    "self is a %s here, not the component. The function was called with a dot: call it with a colon, as in thing:move(1)." },
  { "attempt to call method '([%w_]+)' %(a nil value%)",
    "Nothing here has a function named %s. Check the name's spelling, and that the value is the component or node you mean." },
  { "attempt to call field '([%w_]+)' %(a nil value%)",
    "There is no function named %s in that table. Check the name's spelling, and whether the module that holds it was required." },
  { "attempt to index field 'components' %(a nil value%)",
    "The value is not a node. Check that the variable holds a node, such as self.node, and not a component or nil." },
  { "attempt to index field '([%w_]+)' %(a nil value%)",
    "%s is nil here. If it is a component, the node has none of that type: add it in the inspector, or name it in the type's needs. If it is a node, it may be destroyed or not found." },
  { "attempt to index local '([%w_]+)' %(a nil value%)",
    "%s is nil here. Check what set it: a function that finds a node or a component gives nil when there is none." },
  { "attempt to index global '([%w_]+)' %(a nil value%)",
    "There is no variable named %s. It may be misspelled, or a local of another file: require the module, or pass the value in." },
  { "attempt to call global '([%w_]+)' %(a nil value%)",
    "There is no function named %s. It may be misspelled, defined below this line as a local, or in a module that is not required." },
  { "attempt to perform arithmetic on [%a ]-'([%w_]+)' %(a nil value%)",
    "%s is nil in a calculation. A property that has no default, or a misspelled name, is nil." },
  { "attempt to compare (%w+) with (%w+)",
    "A %s is compared with a %s. One side is not the number or text you expect: it may be nil or a table." },
  { "attempt to concatenate [%a ]-'([%w_]+)' %(a (%w+) value%)",
    "%s is a %s, which .. cannot join. Use tostring(value) for what may be nil or a table." },
  { "module '([^']+)' not found",
    "No file answers to require(\"%s\"). The name is a path from the project's folder or from packages/, with dots for slashes and without .lua." },
  { "stack overflow", "A function calls itself without end. Look at the functions that the stack repeats." },
  { "'end' expected", "A block is not closed. Every function, if, for and while needs its end." },
  { "'=' expected near", "Lua read a name and expected an assignment. A call may lack its brackets, or a keyword is misspelled." },
  { "unexpected symbol near", "The text here is not Lua. Look for a missing comma, bracket or quote just before it." },
  { "'<eof>' expected near 'end'", "There is one end too many." },
  { "Could not open file ([^%s%.]+%.%w+)",
    "The file %s is not in the project. Paths start at the project's folder, and capital letters count." },
  { "bad argument #(%d+) to '([%w_]+)' %(([^)]+)%)",
    "Argument %s of %s is wrong: %s. A value may be nil where LÖVE needs a number, a text or an object." },
}

---Gives a hint for an error's text, or nil when no pattern matches.
---@param message string
---@return string?
function hints.of(message)
  for _, hint in ipairs(HINTS) do
    local captures = { message:match(hint[1]) }
    if #captures > 0 then
      local ok, text = pcall(string.format, hint[2], table.unpack(captures))
      return ok and text or hint[2]
    end
  end
  return nil
end

return hints
