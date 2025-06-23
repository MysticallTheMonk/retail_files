---@type string, Addon
local _, addon = ...
local fsEnumerable = addon.Collections.Enumerable
local fsCompare = addon.Collections.Comparer
local fsSort = addon.Modules.Sorting
local fsTarget = addon.Modules.Targeting
local fsConfig = addon.Configuration
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
---@type PlayerSortMode[]
local playerSortModes = {
    "Top",
    "Middle",
    "Bottom",
    "Hidden",
}
---@type GroupSortMode[]
local groupSortModes = {
    "Role",
    "Group",
    "Alphabetical",
}

---@class ApiV2
local M = {
    Sorting = {},
    Options = {},
    Debugging = {},
    Logging = {},
}
addon.Api.v2 = M

local function VisualOrder(framesOrFunction)
    return fsEnumerable
        :From(framesOrFunction)
        :Where(function(x)
            return x:IsVisible()
        end)
        :OrderBy(function(x, y)
            return fsCompare:CompareTopLeftFuzzy(x, y)
        end)
        :ToTable()
end

---@param mode PlayerSortMode
local function ValidatePlayerSortMode(mode)
    if not fsEnumerable:From(playerSortModes):Any(function(x)
        return x == mode
    end) then
        error("Invalid player sort mode: " .. (mode or "nil"))
    end
end

---@param mode GroupSortMode
local function ValidateGroupSortMode(mode)
    if not fsEnumerable:From(groupSortModes):Any(function(x)
        return x == mode
    end) then
        error("Invalid group sort mode: " .. (mode or "nil"))
    end
end

---@param area Area
local function AreaOptions(area)
    local sorting = addon.DB.Options.Sorting

    if area == "Arena - 2v2" then
        return sorting.Arena.Twos
    elseif area == "Arena - Default" then
        return sorting.Arena.Default
    elseif area == "Dungeon" then
        return sorting.Dungeon
    elseif area == "Raid" then
        return sorting.Raid
    elseif area == "World" then
        return sorting.World
    end

    error("Invalid sorting area: " .. (area or "nil"))
end

local function SpacingAreaOptions(area)
    local spacing = addon.DB.Options.Spacing

    if area == "EnemyArena" then
        return spacing.EnemyArena
    elseif area == "Party" then
        return spacing.Party
    elseif area == "Raid" then
        return spacing.Raid
    end

    error("Invalid spacing area: " .. (area or "nil"))
end

---@param type number
local function GetFrames(type)
    local frames = {}

    for _, provider in ipairs(fsProviders:Enabled()) do
        frames[provider:Name()] = VisualOrder(fsFrame:GetFrames(provider, type))
    end

    return frames
end

---Enables/disables logging.
function M.Logging:SetEnabled(enable)
    addon.DB.Options.Logging.Enabled = enable
    fsConfig:NotifyChanged()
end

---Register a callback to invoke after sorting has been performed.
---@param callback function
function M.Sorting:RegisterPostSortCallback(callback)
    if not callback then
        error("Callback function must not be nil.")
        return
    end

    fsSort:RegisterPostSortCallback(callback)
end

---Returns a collection of party frames ordered by their visual representation.
function M.Sorting:GetPartyFrames()
    return GetFrames(fsFrame.ContainerType.Party)
end

---Returns a collection of raid frames ordered by their visual representation.
function M.Sorting:GetRaidFrames()
    return GetFrames(fsFrame.ContainerType.Raid)
end

---Returns a collection of enemy arena frames ordered by their visual representation.
function M.Sorting:GetArenaFrames()
    return GetFrames(fsFrame.ContainerType.EnemyArena)
end

---Returns party frames if there are any, otherwise raid frames.
function M.Sorting:GetFrames()
    local party = GetFrames(fsFrame.ContainerType.Party)

    for _, frames in pairs(party) do
        if #frames > 0 then
            return party
        end
    end

    return GetFrames(fsFrame.ContainerType.Raid)
end

---Returns a sorted array of friendly unit tokens.
function M.Sorting:GetFriendlyUnits()
    return fsTarget:FriendlyUnits()
end

---Returns a sorted array of enemy unit tokens.
function M.Sorting:GetEnemyUnits()
    return fsTarget:EnemyUnits()
end

---Gets the player sort mode.
---@param area Area
function M.Options:GetPlayerSortMode(area)
    local options = AreaOptions(area)
    return options.PlayerSortMode
end

---Sets the player sort mode.
---@param area Area
---@param mode PlayerSortMode
function M.Options:SetPlayerSortMode(area, mode)
    ValidatePlayerSortMode(mode)

    local options = AreaOptions(area)
    options.PlayerSortMode = mode

    fsConfig:NotifyChanged()
    fsSort:Run()
end

---Sets the group sort mode.
---@param area Area
---@param mode GroupSortMode
function M.Options:SetGroupSortMode(area, mode)
    ValidateGroupSortMode(mode)

    local options = AreaOptions(area)
    options.GroupSortMode = mode

    fsConfig:NotifyChanged()
    fsSort:Run()
end

---Gets the group sort mode.
---@param area Area
function M.Options:GetGroupSortMode(area)
    local options = AreaOptions(area)
    return options.GroupSortMode
end

---Gets the Enabled flag.
---@param area Area
function M.Options:GetEnabled(area)
    local options = AreaOptions(area)
    return options.Enabled
end

---Enables/disables sorting.
---@param area Area
---@param enabled boolean
function M.Options:SetEnabled(area, enabled)
    local options = AreaOptions(area)
    options.Enabled = enabled

    fsConfig:NotifyChanged()

    if enabled then
        fsSort:Run()
    end
end

---Enables/disables reverse sorting.
---@param area Area
function M.Options:GetReverse(area)
    local options = AreaOptions(area)
    return options.Reverse
end

---Enables/disables reverse sorting.
---@param area Area
---@param reverse boolean
function M.Options:SetReverse(area, reverse)
    local options = AreaOptions(area)
    options.Reverse = reverse

    fsConfig:NotifyChanged()
    fsSort:Run()
end

---Gets the current spacing values.
---@param area SpacingArea
function M.Options:GetSpacing(area)
    return SpacingAreaOptions(area)
end

---Adds/removes spacing.
---@param area SpacingArea
---@param horizontal number
---@param vertical number
function M.Options:SetSpacing(area, horizontal, vertical)
    local options = SpacingAreaOptions(area)
    options.Horizontal = horizontal
    options.Vertical = vertical

    fsConfig:NotifyChanged()
    fsSort:Run()
end
