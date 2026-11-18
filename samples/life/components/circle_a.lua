-- Two types that need each other in a circle: the engine refuses them.
---@class circle_a : onlr.Component
local Circle = {}

Circle.needs = { "circle_b" }

return Circle
