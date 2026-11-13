---@meta

-- The formats of the files that the editor writes. The first line of each such file
-- names one of these types, so a code editor completes and checks its fields.

---@class onlr.Project
---@field format integer
---@field name string
---@field id string
---@field version string
---@field love string
---@field scene string
---@field window {width: integer, height: integer}
---@field exclude? string[]

---@class onlr.ComponentData
---@field type string a component type, as require takes it
---@field enabled? boolean true when left out
---@field [string] any the properties' values

---What an instance changes in one object inside its prefab.
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
---@field prefab? string a prefab's file: the object is an instance of it
---@field name? string an instance without one has the prefab's
---@field x? number
---@field y? number
---@field rotation? number
---@field scaleX? number
---@field scaleY? number
---@field z? number
---@field active? boolean
---@field components? onlr.ComponentData[]
---@field children? onlr.ObjectData[]
---@field overrides? table<string, onlr.Override> in an instance: by the ids of the objects inside the prefab

---@class onlr.Scene
---@field format integer
---@field components? onlr.ComponentData[] the scene's own
---@field objects onlr.ObjectData[]

---@class onlr.Prefab : onlr.ObjectData
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
