---@type string, Addon
local _, addon = ...
local fsCompare = addon.Modules.Sorting.Comparer
local fsFrame = addon.WoW.Frame
local fsUnit = addon.WoW.Unit
local fsEnumerable = addon.Collections.Enumerable
local fsInspector = addon.Modules.Inspector
local fsConfig = addon.Configuration
local fsSortedFrames = addon.Modules.Sorting.SortedFrames
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api
local capabilities = addon.WoW.Capabilities
local events = addon.WoW.Events

---@class SortedUnits: IInitialise, IProcessEvents
local M = {}
addon.Modules.Sorting.SortedUnits = M

-- setting a value of false disables this module
local cacheEnabled = true

-- true means cached values are up to date
local friendlyCacheValid = false
local enemyCacheValid = false

-- the amount of times we returned a cached value
local friendlyCacheHits = 0
local enemyCacheHits = 0

-- the amount of times we returned a non-cached value
local friendlyCacheMisses = 0
local enemyCacheMisses = 0

-- the cached values
local cachedEnemyUnits = {}
local cachedFriendlyUnits = {}

-- log stats ever X hits/misses
local currentStatsTick = 0
local logStatsInterval = 50

---@class CycleInstruction
---@field Roles table
---@field Cycles number

-- instructions to apply in-order
---@type CycleInstruction[]|nil
local friendlyCycleInstructions = nil

---@type CycleInstruction[]|nil
local enemyCycleInstructions = nil

local function InvalidateFriendlyCache()
    friendlyCacheValid = false
end

local function InvalidateEnemyCache()
    enemyCacheValid = false
end

local function OnPetEvent(event, petOwner)
    -- UNIT_PET fires for both allies and enemies
    if wow.UnitIsFriend("player", petOwner) then
        InvalidateFriendlyCache()
    else
        InvalidateEnemyCache()
    end
end

local function OnInspectorInfo()
    InvalidateFriendlyCache()
end

local function OnConfigChanged()
    InvalidateFriendlyCache()
    InvalidateEnemyCache()
end

local function FriendlyUnitsFromFrames()
    local frames = fsSortedFrames:FriendlyFrames(false)
    local units = fsEnumerable
        :From(frames)
        :Map(function(x)
            return fsFrame:GetFrameUnit(x)
        end)
        :ToTable()

    return units
end

local function CycleRoles(units, isFriendly, cycles, roles)
    cycles = tonumber(cycles) or 1

    if cycles <= 0 then
        return
    end

    -- roles can be:
    -- 1) array: { "DAMAGER", "HEALER" }
    -- 2) map/set: { ["DAMAGER"] = true, ["HEALER"] = true }
    if not roles then
        return
    end

    if isFriendly and not capabilities.HasRoleAssignments() then
        return
    end

    if not isFriendly and (not capabilities.HasEnemySpecSupport() or not wow.GetSpecializationInfoByID) then
        return
    end

    -- normalize roles into a set for O(1) lookups
    local roleSet = {}
    local roleArray = {}

    if roles[1] ~= nil then
        -- array form
        for i = 1, #roles do
            local r = roles[i]
            if r ~= nil then
                roleSet[r] = true
            end
        end

        roleArray = roles
    else
        -- already a set/map form
        roleSet = roles

        for role, _ in pairs(roles) do
            roleArray[#roleArray + 1] = role
        end
    end

    local rolesString = table.concat(roleArray)
    fsLog:Debug("Cycling %s units %d time(s) for %s roles.", isFriendly and "friendly" or "enemy", cycles, rolesString)

    -- collect indices of units that match any of the desired roles (in current order)
    local matchIdx = {}
    for i = 1, #units do
        local unit = units[i]
        local role

        if isFriendly then
            role = wow.UnitGroupRolesAssigned(unit)
        else
            local specId = fsInspector:EnemyUnitSpec(unit)
            if specId then
                -- GetSpecializationInfoByID returns role as 5th return value
                local _, _, _, _, specRole = wow.GetSpecializationInfoByID(specId)
                role = specRole
            end
        end

        if role and roleSet[role] then
            matchIdx[#matchIdx + 1] = i
        end
    end

    local n = #matchIdx
    if n <= 1 then
        return
    end

    -- reduce cycles to the minimum required rotations
    cycles = cycles % n
    if cycles == 0 then
        return
    end

    -- snapshot current matching units in order
    local temp = {}
    for i = 1, n do
        temp[i] = units[matchIdx[i]]
    end

    -- rotate matching units within their own slots
    for i = 1, n do
        -- move backwards by cycles
        local sourceIndex = i - cycles

        -- wrap around if we go below 1
        while sourceIndex <= 0 do
            sourceIndex = sourceIndex + n
        end

        units[matchIdx[i]] = temp[sourceIndex]
    end
end

local function ApplyCycleInstructions(units, isFriendly, instructions)
    if not instructions or #instructions == 0 then
        return
    end

    fsLog:Debug("Applying %d cycle instructions for %s units.", #instructions, isFriendly and "friendly" or "enemy")

    for i = 1, #instructions do
        local inst = instructions[i]
        if inst and inst.Roles and inst.Cycles and inst.Cycles > 0 then
            CycleRoles(units, isFriendly, inst.Cycles, inst.Roles)
        end
    end
end

local function ShouldCache(units)
    if #units == 0 then
        return false
    end

    -- I'm trying to fix a bug where sometimes in the TBC arena prep room the units aren't in the right order until the gates open (timer sort)
    -- and I think the same bug is causing ElvUI on rare occurrence to show only the player frame in solo shuffle until you /reload
    -- this shouldn't be necessary, but I don't know what's causing the bug so I'm grasping at straws here
    -- TODO: I think I fixed this now in FriendlyUnits() by getting units from frames first before falling back, needs testing to confirm
    for i = 1, #units do
        local unit = units[i]

        if unit ~= "player" and unit ~= "pet" and unit ~= "target" then
            return true
        end
    end

    return false
end

local function LogStatsTick()
    currentStatsTick = currentStatsTick + 1

    if currentStatsTick < logStatsInterval then
        return
    end

    M:LogStats()
    currentStatsTick = 0
end

---@return string[]
function M:FriendlyUnits()
    local hit = false
    local cache = true
    local units

    if cacheEnabled and friendlyCacheValid then
        hit = true
        units = cachedFriendlyUnits
    else
        -- very important:
        -- historically we used to get units from fsUnit:FriendlyUnits() here first then fallback to frames
        -- but there is this ridiculous bug in solo shuffle where on rare occurrence it seems IsInRaid() returns false for blizzard, but true for me
        -- which means blizzard have party frame units but I get raid frame units
        -- this causes sorting to fail in the restricted environment as it can't map the units (there is no UnitIsUnit in RE)
        -- so to fix/avoid this, always get units from frames first and it's fairly safe to cache the result but not perfect
        -- as frames can change without us knowing, but for most cases it's safe enough to cache
        units = FriendlyUnitsFromFrames()
        M:Sort(units, true)
    end

    if not units or #units == 0 then
        -- fallback to reliable method
        units = fsUnit:FriendlyUnits()
        M:Sort(units, true)
    end

    if cacheEnabled then
        if cache then
            cachedFriendlyUnits = units
            friendlyCacheValid = #units > 0 and ShouldCache(units)
        end

        if hit then
            friendlyCacheHits = friendlyCacheHits + 1
        else
            friendlyCacheMisses = friendlyCacheMisses + 1
        end

        LogStatsTick()
    end

    return units or {}
end

---@return string[]
function M:ArenaUnits()
    local hit = false
    local units

    if cacheEnabled and enemyCacheValid then
        hit = true
        units = cachedEnemyUnits
    else
        units = fsUnit:ArenaUnits()
        units = M:Sort(units, false)
    end

    -- don't try fallback from arena frames as this seems to cause issues with erroneous units popping up
    -- so just retry EnemyUnits() on next attempt
    if cacheEnabled then
        cachedEnemyUnits = units
        enemyCacheValid = #units > 0

        if hit then
            enemyCacheHits = enemyCacheHits + 1
        else
            enemyCacheMisses = enemyCacheMisses + 1
        end

        LogStatsTick()
    end

    return units or {}
end

function M:Sort(units, isFriendly)
    local sortEnabled

    if isFriendly then
        sortEnabled = fsCompare:FriendlySortMode()
    else
        sortEnabled = fsCompare:EnemySortMode()
    end

    if sortEnabled then
        local start = wow.GetTimePreciseSec()
        local sortFunction = isFriendly and fsCompare:SortFunction(units) or fsCompare:EnemySortFunction(units)

        if sortFunction then
            table.sort(units, sortFunction)
            local stop = wow.GetTimePreciseSec()
            fsLog:Debug("%s units table.sort() took %fms.", isFriendly and "Friendly" or "Enemy", (stop - start) * 1000)
        end
    end

    if isFriendly then
        ApplyCycleInstructions(units, isFriendly, friendlyCycleInstructions)
    else
        ApplyCycleInstructions(units, isFriendly, enemyCycleInstructions)
    end

    return units
end

function M:InvalidateCache()
    InvalidateFriendlyCache()
    InvalidateEnemyCache()
end

function M:CycleFriendlyRoles(roles, cycles)
    if not roles then
        fsLog:Error("SortedUnits:CycleFriendlyRoles() - roles must not be nil.")
        return
    end

    local n = tonumber(cycles) or 1
    if n <= 0 then
        return
    end

    if not friendlyCycleInstructions then
        friendlyCycleInstructions = {}
    end

    friendlyCycleInstructions[#friendlyCycleInstructions + 1] = {
        Roles = roles,
        Cycles = n,
    }

    InvalidateFriendlyCache()
end

function M:CycleEnemyRoles(roles, cycles)
    if not roles then
        fsLog:Error("SortedUnits:CycleEnemyRoles() - roles must not be nil.")
        return
    end

    local n = tonumber(cycles) or 1
    if n <= 0 then
        return
    end

    if not enemyCycleInstructions then
        enemyCycleInstructions = {}
    end

    enemyCycleInstructions[#enemyCycleInstructions + 1] = {
        Roles = roles,
        Cycles = n,
    }

    InvalidateEnemyCache()
end

function M:ResetFriendlyCycles()
    friendlyCycleInstructions = nil
    InvalidateFriendlyCache()
end

function M:ResetEnemyCycles()
    enemyCycleInstructions = nil
    InvalidateEnemyCache()
end

function M:LogStats()
    fsLog:Debug("Friendly cache %d hits %d misses, enemy cache %d hits %d misses.", friendlyCacheHits, friendlyCacheMisses, enemyCacheHits, enemyCacheMisses)
end

---Returns the frame number for the given unit.
---@param unit string unit token
---@return integer? frameNumber
---@return string? resolvedUnit
function M:FrameNumberForUnit(unit)
    local isFriendly = fsUnit:IsFriendlyUnit(unit)
    local units = isFriendly and M:FriendlyUnits() or M:ArenaUnits()
    local resolvedUnit = fsUnit:ResolveUnit(unit) or unit

    for index, u in ipairs(units) do
        if u == resolvedUnit then
            return index, resolvedUnit
        end

        local isUnitOrSecret = wow.UnitIsUnit(u, resolvedUnit)

        if not wow.issecretvalue(isUnitOrSecret) and isUnitOrSecret then
            return index, resolvedUnit
        end
    end

    return nil, nil
end

function M:ProcessEvent(event, ...)
    if not cacheEnabled then
        return
    end

    if event == events.GROUP_ROSTER_UPDATE then
        InvalidateFriendlyCache()
    elseif event == events.PLAYER_ROLES_ASSIGNED then
        InvalidateFriendlyCache()
    elseif event == events.ARENA_OPPONENT_UPDATE then
        InvalidateEnemyCache()
    elseif event == events.ARENA_PREP_OPPONENT_SPECIALIZATIONS then
        InvalidateEnemyCache()
    elseif event == events.UNIT_PET then
        local unit = select(1, ...)
        OnPetEvent(event, unit)
    elseif event == events.PLAYER_ENTERING_WORLD then
        -- reset cycle instructions after loading screen
        friendlyCycleInstructions = nil
        enemyCycleInstructions = nil
    end
end

function M:Init()
    if not cacheEnabled then
        return
    end

    fsInspector:RegisterCallback(OnInspectorInfo)
    fsConfig:RegisterConfigurationChangedCallback(OnConfigChanged)

    fsLog:Debug("Initialised the sorted units caching module.")
end
