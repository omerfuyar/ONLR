-- Two types that need each other in a circle: the engine refuses them.
---@class circle_b : onlr.Component
local Circle = {}

Circle.needs = { "circle_a" }

return Circle
