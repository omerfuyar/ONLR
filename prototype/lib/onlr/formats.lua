---@meta

-- The formats of the files that the editor writes. The first line of each such file
-- names one of these types, so a code editor completes and checks its fields.

---@class onlr.Project
---@field format integer
---@field name string
---@field id string
---@field gameVersion string
---@field loveVersion string
---@field startNode string the node file that the game starts with, as its root
---@field keptNodes? string[] node files that the game loads once, before the first root, and keeps
---@field window {width: integer, height: integer}
---@field defaultFilter? "linear"|"nearest" as love.graphics.setDefaultFilter; linear when left out
---@field fixedRate? number how many times a second fixedUpdate is called; 60 when left out
---@field exclude? string[]

---A component's entry: its properties' values.
---@class onlr.ComponentData
---@field enabled? boolean true when left out
---@field [string] any the properties' values

---A node's components, by their types' names. A dot in a name is a table in a table:
---bump.body is bump = { body = { ... } }.
---@alias onlr.ComponentsData table<string, onlr.ComponentData | table<string, onlr.ComponentData>>

---What an instance changes in one node of its base.
---@class onlr.Change
---@field name? string
---@field posX? number
---@field posY? number
---@field rot? number
---@field sclX? number
---@field sclY? number
---@field z? number
---@field active? boolean
---@field components? onlr.ComponentsData laid over the node's components, name by name; one that the node lacks is added
---@field children? onlr.NodeData[] nodes of the instance's own, added under this node

---All that an instance is: its base, and what it changes in the base's nodes.
---@class onlr.InstanceData
---@field base string a node file
---@field changes? table<string, onlr.Change> by the changed node's id in the base's file, or by a path into an instance inside the base

---A node's entry. An instance has id and instance, and no other field.
---@class onlr.NodeData
---@field id string unique in its file
---@field instance? onlr.InstanceData
---@field name? string
---@field posX? number
---@field posY? number
---@field rot? number
---@field sclX? number
---@field sclY? number
---@field z? number
---@field active? boolean
---@field components? onlr.ComponentsData
---@field children? onlr.NodeData[]

---A node file: one node, and the format's number beside its fields.
---The colon only tells a code editor that the file has a node's fields too.
---@class onlr.NodeFile : onlr.NodeData
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
