---@type string, Addon
local _, addon = ...
local fsEnumerable = addon.Collections.Enumerable
local fsCompare = addon.Collections.Comparer
local fsSort = addon.Modules.Sorting
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

---@class ApiV1
local M = {
    Sorting = {},
    Options = {},
    Debugging = {},
    Logging = {},
}
addon.Api.v1 = M

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
---@return table[]
local function AreaOptions(area)
    local sorting = addon.DB.Options.Sorting

    -- backwards compatibility for when there was only 1 arena mode
    if area == "Arena" then
        -- in v2 of the API, we'd ask the caller to specify which arena area
        -- then we can avoid returning multiple options which just introduces ambiguity
        return {
            sorting.Arena.Twos,
            sorting.Arena.Default,
        }
    elseif area == "Arena - 2v2" then
        return { sorting.Arena.Twos }
    elseif area == "Arena - Default" then
        return { sorting.Arena.Default }
    end

    local table = addon.DB.Options.Sorting[area]

    if table then
        return { table }
    end

    error("Invalid area: " .. (area or "nil"))
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

---Returns a collection of Blizzard party frames ordered by their visual representation.
function M.Sorting:GetPartyFrames()
    local blizzard = fsProviders.Blizzard
    local frames = fsFrame:PartyFrames(blizzard)

    return VisualOrder(frames)
end

---Returns a collection of Blizzard raid frames ordered by their visual representation.
function M.Sorting:GetRaidFrames()
    local blizzard = fsProviders.Blizzard
    local frames = fsFrame:RaidFrames(blizzard)

    return VisualOrder(frames)
end

---Returns a collection of Blizzard enemy arena frames ordered by their visual representation.
function M.Sorting:GetArenaFrames()
    local blizzard = fsProviders.Blizzard
    local frames = fsFrame:ArenaFrames(blizzard)

    return VisualOrder(frames)
end

---Returns party frames if there are any, otherwise raid frames.
function M.Sorting:GetFrames()
    local party = M.Sorting:GetPartyFrames()

    if #party > 0 then
        return party
    end

    return M.Sorting:GetRaidFrames()
end

---Gets the player sort mode.
---@param area Area
function M.Options:GetPlayerSortMode(area)
    local options = AreaOptions(area)
    -- in v2 of the API we can remove this ambiguity
    return options[1].PlayerSortMode
end

---Sets the player sort mode.
---@param area Area
---@param mode PlayerSortMode
function M.Options:SetPlayerSortMode(area, mode)
    ValidatePlayerSortMode(mode)

    local options = AreaOptions(area)

    for _, table in ipairs(options) do
        table.PlayerSortMode = mode
    end

    fsConfig:NotifyChanged()
    fsSort:Run()
end

---Sets the group sort mode.
---@param area Area
---@param mode GroupSortMode
function M.Options:SetGroupSortMode(area, mode)
    ValidateGroupSortMode(mode)

    local options = AreaOptions(area)

    for _, table in ipairs(options) do
        table.GroupSortMode = mode
    end

    fsConfig:NotifyChanged()
    fsSort:Run()
end

---Gets the group sort mode.
---@param area Area
function M.Options:GetGroupSortMode(area)
    local options = AreaOptions(area)
    return options[1].GroupSortMode
end

---Gets the Enabled flag.
---@param area Area
function M.Options:GetEnabled(area)
    local options = AreaOptions(area)
    return options[1].Enabled
end

---Enables/disables sorting.
---@param area Area
---@param enabled boolean
function M.Options:SetEnabled(area, enabled)
    local options = AreaOptions(area)

    for _, table in ipairs(options) do
        table.Enabled = enabled
    end

    fsConfig:NotifyChanged()

    if enabled then
        fsSort:Run()
    end
end

---Enables/disables reverse sorting.
---@param area Area
function M.Options:GetReverse(area)
    local options = AreaOptions(area)
    return options[1].Reverse
end

---Enables/disables reverse sorting.
---@param area Area
---@param reverse boolean
function M.Options:SetReverse(area, reverse)
    local options = AreaOptions(area)

    for _, table in ipairs(options) do
        table.Reverse = reverse
    end

    fsConfig:NotifyChanged()
    fsSort:Run()
end

---Enables/disables logging.
function M.Logging:SetEnabled(enable)
    addon.DB.Options.Logging.Enabled = enable
    fsConfig:NotifyChanged()
end

---Exposes the addon table to the public when enabled.
function M.Debugging:SetEnabled(enable)
    if enable then
        FrameSort = addon
    else
        ---@diagnostic disable-next-line: assign-type-mismatch
        FrameSort = nil
    end
end
