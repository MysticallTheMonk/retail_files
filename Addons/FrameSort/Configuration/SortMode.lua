---@type string, Addon
local _, addon = ...

---@class GroupSortModeEnum
addon.Configuration.GroupSortMode = {
    Group = "Group",
    Role = "Role",
    Alphabetical = "Alphabetical",
}

---@class PlayerSortModeEnum
addon.Configuration.PlayerSortMode = {
    Top = "Top",
    Middle = "Middle",
    Bottom = "Bottom",
    Hidden = "Hidden",
}

---@alias PlayerSortMode
---| "Top"
---| "Middle"
---| "Bottom"
---| "Hidden"

---@alias GroupSortMode
---| "Group"
---| "Role"
---| "Alphabetical"
