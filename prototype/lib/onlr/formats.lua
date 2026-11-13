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
---@field window {width: integer, height: integer}
---@field exclude? string[]

---A component's entry: its properties' values.
---@class onlr.ComponentData
---@field enabled? boolean true when left out
---@field [string] any the properties' values

---A node's components, by their types' names. A dot in a name is a table in a table:
---bump.body is bump = { body = { ... } }.
---@alias onlr.ComponentsData table<string, onlr.ComponentData | table<string, onlr.ComponentData>>

---What an instance changes in one node under it.
---@class onlr.Override
---@field name? string
---@field posX? number
---@field posY? number
---@field rot? number
---@field sclX? number
---@field sclY? number
---@field z? number
---@field active? boolean
---@field components? onlr.ComponentsData laid over the node's components, name by name
---@field children? onlr.NodeData[] nodes of the instance's own, added under this node
---@field overrides? table<string, onlr.Override> when the node is an instance too

---@class onlr.NodeData
---@field id string
---@field instance? string a node file: the node is an instance of it
---@field name? string an instance without one has its file's
---@field posX? number
---@field posY? number
---@field rot? number
---@field sclX? number
---@field sclY? number
---@field z? number
---@field active? boolean
---@field components? onlr.ComponentsData
---@field children? onlr.NodeData[]
---@field overrides? table<string, onlr.Override> in an instance: by the ids of the nodes under it

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
