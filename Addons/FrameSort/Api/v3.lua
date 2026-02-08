---@type string, Addon
local _, addon = ...
local fsSort = addon.Modules.Sorting
local fsRun = addon.Modules
local fsConfig = addon.Configuration
local fsFrame = addon.WoW.Frame
local fsInspector = addon.Modules.Inspector
local fsUnit = addon.WoW.Unit
local fsUnitTracker = addon.Modules.UnitTracker
local fsSortedUnits = addon.Modules.Sorting.SortedUnits
local fsProviders = addon.Providers
local fsEnumerable = addon.Collections.Enumerable
local fsCompare = addon.Modules.Sorting.Comparer
local fsMacroParser = addon.Modules.Macro.Parser
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api

---@class ApiV3
local M = {
    Sorting = {},
    Options = {},
    Inspector = {},
    Frame = {},
    Caching = {},
    Unit = {},
}
addon.Api.v3 = M

local playerSortModes = {
    Top = true,
    Middle = true,
    Bottom = true,
    Hidden = true,
}

local groupSortModes = {
    Role = true,
    Group = true,
    Alphabetical = true,
}

local areas = {
    ["Arena - 2v2"] = true,
    ["Arena - 3v3"] = true,
    ["Arena - 5v5"] = true,
    ["Arena - Default"] = true,
    EnemyArena = true,
    Dungeon = true,
    Raid = true,
    World = true,
}

local spacingAreas = {
    EnemyArena = true,
    Party = true,
    Raid = true,
}

---@param area Area
local function AreaOptions(area)
    local sorting = addon.DB.Options.Sorting
    local map = {
        ["Arena - 2v2"] = sorting.Arena.Twos,
        ["Arena - 3v3"] = sorting.Arena.Default,
        ["Arena - 5v5"] = sorting.Arena.Default,
        ["Arena - Default"] = sorting.Arena.Default,
        EnemyArena = sorting.EnemyArena,
        Dungeon = sorting.Dungeon,
        Raid = sorting.Raid,
        World = sorting.World,
    }

    return map[area]
end

local function SpacingAreaOptions(area)
    local spacing = addon.DB.Options.Spacing

    local map = {
        EnemyArena = spacing.EnemyArena,
        Party = spacing.Party,
        Raid = spacing.Raid,
    }

    return map[area]
end

local function VisualOrder(framesOrFunction)
    return fsEnumerable
        :From(framesOrFunction)
        :Where(function(x)
            return x.IsVisible and x:IsVisible()
        end)
        :OrderBy(function(x, y)
            return fsCompare:CompareTopLeftFuzzy(x, y)
        end)
        :ToTable()
end

---@param type number
local function GetFrames(type)
    local frames = {}

    for _, provider in ipairs(fsProviders:EnabledNotSelfManaged()) do
        frames[provider:Name()] = VisualOrder(fsFrame:GetFrames(provider, type))
    end

    return frames
end

---@param mode PlayerSortMode
local function ValidPlayerSortMode(mode)
    return type(mode) == "string" and playerSortModes[mode] == true
end

---@param mode GroupSortMode
local function ValidGroupSortMode(mode)
    return type(mode) == "string" and groupSortModes[mode] == true
end

---@param area Area
local function ValidArea(area)
    return type(area) == "string" and areas[area] == true
end

---@param area SpacingArea
local function ValidSpacingArea(area)
    return type(area) == "string" and spacingAreas[area] == true
end

---Protect our callers against internal errors/bugs.
---@param fn function the function to run
---@param name string name of the function for logging purposes
---@return any result this is technically not true as it can return multiple values, but doing this to ignore intellisense issues.
local function SafeCall(fn, name)
    local results = { pcall(fn) }

    if not results[1] then
        fsLog:Error("Api.v3.%s - error: %s.", name or "nil", tostring(results[2]))
        return nil
    end

    ---@diagnostic disable-next-line: redundant-return-value
    return unpack(results, 2)
end

---Register a callback to be invoked after sorting has been performed.
---@param callback function
function M.Sorting:RegisterPostSortCallback(callback)
    if not callback then
        fsLog:Error("Api.v3.Sorting:RegisterPostSortCallback was passed a nil parameter: callback.")
        return false
    end

    return SafeCall(function()
        fsSort:RegisterPostSortCallback(callback)
        return true
    end, "Sorting:RegisterPostSortCallback") or false
end

function M.Sorting:RegisterFrameProvider(provider)
    if not provider then
        fsLog:Error("Api.v3.Sorting:RegisterFrameProvider was passed a nil parameter: provider.")
        return false
    end

    return SafeCall(function()
        return fsProviders:RegisterFrameProvider(provider, true)
    end, "Sorting:RegisterFrameProvider") or false
end

---Returns a collection of party frames ordered by their visual representation.
function M.Sorting:GetPartyFrames()
    return SafeCall(function()
        return GetFrames(fsFrame.ContainerType.Party)
    end, "Sorting:GetPartyFrames") or {}
end

---Returns a collection of raid frames ordered by their visual representation.
function M.Sorting:GetRaidFrames()
    return SafeCall(function()
        return GetFrames(fsFrame.ContainerType.Raid)
    end, "Sorting:GetRaidFrames") or {}
end

---Returns a collection of enemy arena frames ordered by their visual representation.
function M.Sorting:GetArenaFrames()
    return SafeCall(function()
        return GetFrames(fsFrame.ContainerType.EnemyArena)
    end, "Sorting:GetArenaFrames") or {}
end

---Returns party frames if there are any, otherwise raid frames.
function M.Sorting:GetFrames()
    return SafeCall(function()
        local party = GetFrames(fsFrame.ContainerType.Party)

        for _, frames in pairs(party) do
            if #frames > 0 then
                return party
            end
        end

        return GetFrames(fsFrame.ContainerType.Raid)
    end, "Sorting:GetFrames") or {}
end

---Returns a sorted array of friendly unit tokens.
function M.Sorting:GetFriendlyUnits()
    return SafeCall(function()
        return fsSortedUnits:FriendlyUnits()
    end, "Sorting:GetFriendlyUnits") or {}
end

---Returns a sorted array of enemy unit tokens.
function M.Sorting:GetEnemyUnits()
    return SafeCall(function()
        return fsSortedUnits:ArenaUnits()
    end, "Sorting:GetEnemyUnits") or {}
end

---Gets the player sort mode.
---@param area Area
function M.Options:GetPlayerSortMode(area)
    if not area then
        fsLog:Error("Api.v3.Options:GetPlayerSortMode was passed a nil parameter: area.")
        return nil
    end

    if not ValidArea(area) then
        fsLog:Error("Api.v3.Options:GetPlayerSortMode was passed an invalid parameter: area = %s.", tostring(area))
        return nil
    end

    return SafeCall(function()
        local options = AreaOptions(area)
        return options and options.PlayerSortMode
    end, "Options:GetPlayerSortMode")
end

---Sets the player sort mode.
---@param area Area
---@param mode PlayerSortMode
function M.Options:SetPlayerSortMode(area, mode)
    if not area then
        fsLog:Error("Api.v3.Options:SetPlayerSortMode was passed a nil parameter: area.")
        return false
    end

    if not mode then
        fsLog:Error("Api.v3.Options:SetPlayerSortMode was passed a nil parameter: mode.")
        return false
    end

    if not ValidArea(area) then
        fsLog:Error("Api.v3.Options:SetPlayerSortMode was passed an invalid parameter: area = %s.", tostring(area))
        return false
    end

    if not ValidPlayerSortMode(mode) then
        fsLog:Error("Api.v3.Options:SetPlayerSortMode was passed an invalid parameter: mode = %s.", tostring(mode))
        return false
    end

    return SafeCall(function()
        local options = AreaOptions(area)

        if not options then
            return false
        end

        options.PlayerSortMode = mode

        fsConfig:NotifyChanged()
        fsRun:Run()
        return true
    end, "Options:SetPlayerSortMode") or false
end

---Sets the group sort mode.
---@param area Area
---@param mode GroupSortMode
function M.Options:SetGroupSortMode(area, mode)
    if not area then
        fsLog:Error("Api.v3.Options:SetGroupSortMode was passed a nil parameter: area.")
        return false
    end

    if not mode then
        fsLog:Error("Api.v3.Options:SetGroupSortMode was passed a nil parameter: mode.")
        return false
    end

    if not ValidArea(area) then
        fsLog:Error("Api.v3.Options:SetGroupSortMode was passed an invalid parameter: area = %s.", tostring(area))
        return false
    end

    if not ValidGroupSortMode(mode) then
        fsLog:Error("Api.v3.Options:SetGroupSortMode was passed an invalid parameter: mode = %s.", tostring(mode))
        return false
    end

    return SafeCall(function()
        local options = AreaOptions(area)

        if not options then
            return false
        end

        options.GroupSortMode = mode

        fsConfig:NotifyChanged()
        fsRun:Run()
        return true
    end, "Options:SetGroupSortMode") or false
end

---Gets the group sort mode.
---@param area Area
function M.Options:GetGroupSortMode(area)
    if not area then
        fsLog:Error("Api.v3.Options:GetGroupSortMode was passed a nil parameter: area.")
        return nil
    end

    if not ValidArea(area) then
        fsLog:Error("Api.v3.Options:GetGroupSortMode was passed an invalid parameter: area = %s.", tostring(area))
        return nil
    end

    return SafeCall(function()
        local options = AreaOptions(area)
        return options and options.GroupSortMode
    end, "Options:GetGroupSortMode")
end

---Gets the Enabled flag.
---@param area Area
function M.Options:GetEnabled(area)
    if not area then
        fsLog:Error("Api.v3.Options:GetEnabled was passed a nil parameter: area.")
        return nil
    end

    if not ValidArea(area) then
        fsLog:Error("Api.v3.Options:GetEnabled was passed an invalid parameter: area = %s.", tostring(area))
        return nil
    end

    return SafeCall(function()
        local options = AreaOptions(area)

        if not options then
            return nil
        end

        return options.Enabled
    end, "Options:GetEnabled")
end

---Enables/disables sorting.
---@param area Area
---@param enabled boolean
function M.Options:SetEnabled(area, enabled)
    if not area then
        fsLog:Error("Api.v3.Options:SetEnabled was passed a nil parameter: area.")
        return false
    end

    if type(enabled) ~= "boolean" then
        fsLog:Error("Api.v3.Options:SetEnabled was passed an invalid parameter: enabled = %s.", tostring(enabled))
        return false
    end

    if not ValidArea(area) then
        fsLog:Error("Api.v3.Options:SetEnabled was passed an invalid parameter: area = %s.", tostring(area))
        return false
    end

    return SafeCall(function()
        local options = AreaOptions(area)

        if not options then
            return false
        end

        options.Enabled = enabled

        fsConfig:NotifyChanged()

        if enabled then
            fsRun:Run()
        end
        return true
    end, "Options:SetEnabled") or false
end

---Enables/disables reverse sorting.
---@param area Area
function M.Options:GetReverse(area)
    if not area then
        fsLog:Error("Api.v3.Options:GetReverse was passed a nil parameter: area.")
        return nil
    end

    if not ValidArea(area) then
        fsLog:Error("Api.v3.Options:GetReverse was passed an invalid parameter: area = %s.", tostring(area))
        return nil
    end

    return SafeCall(function()
        local options = AreaOptions(area)
        return options and options.Reverse
    end, "Options:GetReverse")
end

---Enables/disables reverse sorting.
---@param area Area
---@param reverse boolean
function M.Options:SetReverse(area, reverse)
    if not area then
        fsLog:Error("Api.v3.Options:SetReverse was passed a nil parameter: area.")
        return false
    end

    if type(reverse) ~= "boolean" then
        fsLog:Error("Api.v3.Options:SetReverse was passed an invalid parameter: reverse = %s.", tostring(reverse))
        return false
    end

    if not ValidArea(area) then
        fsLog:Error("Api.v3.Options:SetReverse was passed an invalid parameter: area = %s.", tostring(area))
        return false
    end

    return SafeCall(function()
        local options = AreaOptions(area)

        if not options then
            return false
        end

        options.Reverse = reverse

        fsConfig:NotifyChanged()
        fsRun:Run()
        return true
    end, "Options:SetReverse") or false
end

---Gets the current spacing values.
---@param area SpacingArea
function M.Options:GetSpacing(area)
    if not area then
        fsLog:Error("Api.v3.Options:GetSpacing was passed a nil parameter: area.")
        return nil
    end

    if not ValidSpacingArea(area) then
        fsLog:Error("Api.v3.Options:GetSpacing was passed an invalid parameter: area = %s.", tostring(area))
        return nil
    end

    return SafeCall(function()
        return SpacingAreaOptions(area)
    end, "Options:GetSpacing")
end

---Registers a callback to invoke when configuration changes.
---@param callback function
function M.Options:RegisterConfigurationChangedCallback(callback)
    if type(callback) ~= "function" then
        fsLog:Error("Api.v3.Options:RegisterConfigurationChangedCallback was passed an invalid parameter: callback = %s.", tostring(callback))
        return false
    end

    return SafeCall(function()
        fsConfig:RegisterConfigurationChangedCallback(callback)
        return true
    end, "Options:RegisterConfigurationChangedCallback") or false
end

---Adds/removes spacing.
---@param area SpacingArea
---@param horizontal number
---@param vertical number
function M.Options:SetSpacing(area, horizontal, vertical)
    if not area then
        fsLog:Error("Api.v3.Options:SetSpacing was passed a nil parameter: area.")
        return false
    end

    if type(horizontal) ~= "number" then
        fsLog:Error("Api.v3.Options:SetSpacing was passed an invalid parameter: horizontal = %s.", tostring(horizontal))
        return false
    end

    if type(vertical) ~= "number" then
        fsLog:Error("Api.v3.Options:SetSpacing was passed an invalid parameter: vertical = %s.", tostring(vertical))
        return false
    end

    if not ValidSpacingArea(area) then
        fsLog:Error("Api.v3.Options:SetSpacing was passed an invalid parameter: area = %s.", tostring(area))
        return false
    end

    return SafeCall(function()
        local options = SpacingAreaOptions(area)

        if not options then
            return false
        end

        options.Horizontal = horizontal
        options.Vertical = vertical

        fsConfig:NotifyChanged()
        fsRun:Run()
        return true
    end, "Options:SetSpacing") or false
end

---Returns the class specialization id of the specified unit, or 0/nil if unknown.
---@param unit string
---@return number|nil
function M.Inspector:GetUnitSpecId(unit)
    if not unit then
        fsLog:Error("Api.v3.Inspector:GetUnitSpecId was passed a nil parameter: unit.")
        return nil
    end

    if type(unit) ~= "string" then
        fsLog:Error("Api.v3.Inspector:GetUnitSpecId was passed an invalid parameter: unit = %s.", tostring(unit))
        return nil
    end

    return SafeCall(function()
        if fsUnit:IsEnemyUnit(unit) then
            local specId = fsInspector:EnemyUnitSpec(unit)

            if specId then
                return specId
            end
        end

        -- attempt friendly even if the unit is an enemy, because they may have previously been friendly and we've cached their spec
        return fsInspector:FriendlyUnitSpec(unit)
    end, "Inspector:GetUnitSpecId")
end

---Registers a callback to be invoked when spec information changes.
---@param callback function
---@return number|nil
function M.Inspector:RegisterCallback(callback)
    if not callback then
        fsLog:Error("Api.v3.Inspector:RegisterCallback was passed a nil parameter: callback.")
        return nil
    end

    if type(callback) ~= "function" then
        fsLog:Error("Api.v3.Inspector:RegisterCallback was passed an invalid parameter: callback = %s.", tostring(callback))
        return nil
    end

    return SafeCall(function()
        fsInspector:RegisterCallback(callback)
        return true
    end, "Inspector:RegisterSpecInformationCallback") or false
end

---Purges the spec cache.
---@return boolean
function M.Inspector:PurgeCache()
    return SafeCall(function()
        fsInspector:PurgeCache()
        return true
    end, "Inspector:PurgeCache") or false
end

---Returns the unit token from the given frame.
---@param frame table
function M.Frame:UnitFromFrame(frame)
    if not frame then
        fsLog:Error("Api.v3.Frame:UnitFromFrame was passed a nil parameter: frame.")
        return nil
    end

    if type(frame) ~= "table" and type(frame) ~= "userdata" then
        fsLog:Error("Api.v3.Frame:UnitFromFrame was passed an invalid parameter: frame = %s.", tostring(frame))
        return nil
    end

    return SafeCall(function()
        return fsFrame:GetFrameUnit(frame)
    end, "Frame:UnitFromFrame")
end

---Returns the ordered frame number for the specified unit.
---@param unit string
---@return number|nil
function M.Frame:FrameNumberForUnit(unit)
    if not unit then
        fsLog:Error("Api.v3.Frame:FrameNumberForUnit was passed a nil parameter: unit.")
        return nil
    end

    if type(unit) ~= "string" then
        fsLog:Error("Api.v3.Frame:FrameNumberForUnit was passed an invalid parameter: unit = %s.", tostring(unit))
        return nil
    end

    return SafeCall(function()
        return fsSortedUnits:FrameNumberForUnit(unit)
    end, "Frame:FrameNumberForUnit")
end

---Returns the party/raid/arena frame for the given unit.
---@param unit string
---@return table|nil
function M.Frame:FrameForUnit(unit)
    if not unit then
        fsLog:Error("Api.v3.Frame:FrameForUnit was passed a nil parameter: unit.")
        return nil
    end

    if type(unit) ~= "string" then
        fsLog:Error("Api.v3.Frame:FrameForUnit was passed an invalid parameter: unit = %s.", tostring(unit))
        return nil
    end

    return SafeCall(function()
        return fsUnitTracker:GetFrameForUnit(unit)
    end, "Frame:FrameForUnit")
end

---Shifts the friendly frames down by 'cycles' or 1 for each role.
---@param cycles number|nil
---@return boolean cycled
function M.Frame:CycleFriendlyRoles(roles, cycles)
    if wow.InCombatLockdown() then
        fsLog:NotifyCombatLockdown()
        return false
    end

    if not roles then
        fsLog:Error("Api.v3.Frame:CycleFriendlyRoles was passed a nil parameter: roles.")
        return false
    end

    if type(roles) ~= "table" then
        fsLog:Error("Api.v3.Frame:CycleFriendlyRoles was passed an invalid parameter: roles = %s.", tostring(roles))
        return false
    end

    return SafeCall(function()
        fsSortedUnits:CycleFriendlyRoles(roles, cycles)
        fsRun:Run()
        return true
    end, "Frame:CycleFriendlyRoles") or false
end

---Shifts the enemy frames down by 'cycles' or 1 for each role.
---@param cycles number|nil
---@return boolean cycled
function M.Frame:CycleEnemyRoles(roles, cycles)
    if wow.InCombatLockdown() then
        fsLog:NotifyCombatLockdown()
        return false
    end

    if not roles then
        fsLog:Error("Api.v3.Frame:CycleEnemyRoles was passed a nil parameter: roles.")
        return false
    end

    if type(roles) ~= "table" then
        fsLog:Error("Api.v3.Frame:CycleEnemyRoles was passed an invalid parameter: roles = %s.", tostring(roles))
        return false
    end

    return SafeCall(function()
        fsSortedUnits:CycleEnemyRoles(roles, cycles)
        fsRun:Run()
        return true
    end, "Frame:CycleEnemyRoles") or false
end

---Resets the friendly frame cycling.
function M.Frame:ResetFriendlyCycles()
    if wow.InCombatLockdown() then
        fsLog:NotifyCombatLockdown()
        return false
    end

    return SafeCall(function()
        fsSortedUnits:ResetFriendlyCycles()
        fsRun:Run()
        return true
    end, "Frame:ResetFriendlyCycles") or false
end

---Resets the enemy frame cycling.
function M.Frame:ResetEnemyCycles()
    if wow.InCombatLockdown() then
        fsLog:NotifyCombatLockdown()
        return false
    end

    return SafeCall(function()
        fsSortedUnits:ResetEnemyCycles()
        fsRun:Run()
        return true
    end, "Frame:ResetEnemyCycles") or false
end

---Invalidates the unit cache.
function M.Caching:Invalidate()
    return SafeCall(function()
        fsSortedUnits:InvalidateCache()
        return true
    end, "Caching:Invalidate") or false
end

---Returns the unit for the specified FrameSort variable
function M.Unit:ResolveVariable(variable)
    return SafeCall(function()
        local friendlyUnits = fsSortedUnits:FriendlyUnits()
        local enemyUnits = fsSortedUnits:ArenaUnits()

        return fsMacroParser:UnitForSelector(variable, friendlyUnits, enemyUnits)
    end, "Unit:ResolveVariable") or nil
end
