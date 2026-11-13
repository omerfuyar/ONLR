---@meta

-- The formats of the files that the editor writes. The first line of each such file
-- names one of these types, so a code editor completes and checks its fields.

---@class onlr.Project
---@field format integer
---@field name string
---@field id string
---@field gameVersion string
---@field loveVersion string
---@field scene string the scene that the game starts with
---@field window {width: integer, height: integer}
---@field exclude? string[]

---@class onlr.ComponentData
---@field type string a component type, as require takes it
---@field enabled? boolean true when left out
---@field [string] any the properties' values

---What an instance changes in one object under its root.
---@class onlr.Override
---@field name? string
---@field x? number
---@field y? number
---@field rotation? number
---@field scaleX? number
---@field scaleY? number
---@field z? number
---@field active? boolean
---@field components? onlr.ComponentData[] laid over the object's components, by type
---@field overrides? table<string, onlr.Override> when the object is an instance too

---@class onlr.ObjectData
---@field id string
---@field scene? string a scene's file: the object is an instance of that scene
---@field name? string an instance without one has its scene's
---@field x? number
---@field y? number
---@field rotation? number
---@field scaleX? number
---@field scaleY? number
---@field z? number
---@field active? boolean
---@field components? onlr.ComponentData[]
---@field children? onlr.ObjectData[]
---@field overrides? table<string, onlr.Override> in an instance: by the ids of the objects under its root

---A scene's file: one object, the root, and the format's number beside its fields.
---The colon only tells a code editor that a scene has an object's fields too.
---@class onlr.Scene : onlr.ObjectData
---@field format integer

---The manifest of the engine and of a pack. The project's manifest is onlr.Project.
---@class onlr.Pack
---@field format integer
---@field name string
---@field description string
---@field version string
---@field source string
---@field license string
---@field components string[] by their files' names
