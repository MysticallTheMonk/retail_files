---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsProviders = addon.Providers
local fsUnit = addon.WoW.Unit
local fsEnumerable = addon.Collections.Enumerable
local fsCompare = addon.Collections.Comparer
local fsFrame = addon.WoW.Frame
local fsLog = addon.Logging.Log
local targetFrames = {}
local targetReverseFrames = {}
local targetPetFrames = {}
local targetEnemyFrames = {}
local targetEnemyPetFrames = {}
local focusEnemyFrames = {}
local targetBottomFrame = nil
local targetNextFrame = nil
local targetPreviousFrame = nil
local cycleNextFrame = nil
local cyclePreviousFrame = nil

---@class TargetingModule: IInitialise
local M = {}
addon.Modules.Targeting = M

local function GetFriendlyFrames(provider)
    local frames = fsFrame:PartyFrames(provider, true)

    if #frames == 0 then
        frames = fsFrame:RaidFrames(provider, true)
    end

    return frames
end

local function UpdateAdjacentTargets(friendlyUnits)
    assert(cycleNextFrame)
    assert(cyclePreviousFrame)
    assert(targetNextFrame)
    assert(targetPreviousFrame)

    cycleNextFrame:SetAttribute("FSUnitsCount", #friendlyUnits)
    cyclePreviousFrame:SetAttribute("FSUnitsCount", #friendlyUnits)
    targetNextFrame:SetAttribute("FSUnitsCount", #friendlyUnits)
    targetPreviousFrame:SetAttribute("FSUnitsCount", #friendlyUnits)

    for index, unit in ipairs(friendlyUnits) do
        -- need to prefix as Unit1/2/3 is reserved
        cycleNextFrame:SetAttribute("FSUnit" .. index, unit)
        cyclePreviousFrame:SetAttribute("FSUnit" .. index, unit)
        targetNextFrame:SetAttribute("FSUnit" .. index, unit)
        targetPreviousFrame:SetAttribute("FSUnit" .. index, unit)
    end
end

local function FilterPets(units)
    return fsEnumerable
        :From(units)
        :Where(function(x) return not fsUnit:IsPet(x) end)
        :ToTable()
end

local function UpdateTargets()
    local updatedCount = 0
    local start = wow.GetTimePreciseSec()
    local friendlyUnits = M:FriendlyNonPetUnits()

    -- if units has less than 5 items it's still fine as units[i] will just be nil
    for i, btn in ipairs(targetFrames) do
        local new = friendlyUnits[i] or "none"
        local current = btn:GetAttribute("unit")

        if current ~= new then
            btn:SetAttribute("unit", new)
            updatedCount = updatedCount + 1
        end
    end

    for i, btn in ipairs(targetPetFrames) do
        local new = fsUnit:PetFor(friendlyUnits[i] or "none")
        local current = btn:GetAttribute("unit")

        if current ~= new then
            btn:SetAttribute("unit", new)
            updatedCount = updatedCount + 1
        end
    end

    assert(targetBottomFrame)

    local bottomCurrentUnit = targetBottomFrame:GetAttribute("unit")
    local bottomNewUnit = friendlyUnits[#friendlyUnits] or "none"

    if bottomCurrentUnit ~= bottomNewUnit then
        targetBottomFrame:SetAttribute("unit", bottomNewUnit)
        updatedCount = updatedCount + 1
    end


    for i, btn in ipairs(targetReverseFrames) do
        local new = friendlyUnits[#friendlyUnits - i] or "none"
        local current = btn:GetAttribute("unit")

        if current ~= new then
            btn:SetAttribute("unit", new)
            updatedCount = updatedCount + 1
        end
    end

    local enemyUnits = M:EnemyNonPetUnits()

    for i, btn in ipairs(targetEnemyFrames) do
        local new = enemyUnits[i] or "none"
        local current = btn:GetAttribute("unit")

        if current ~= new then
            btn:SetAttribute("unit", new)
            updatedCount = updatedCount + 1
        end
    end

    for i, btn in ipairs(targetEnemyPetFrames) do
        local new = fsUnit:PetFor(enemyUnits[i] or "none")
        local current = btn:GetAttribute("unit")

        if current ~= new then
            btn:SetAttribute("unit", new)
            updatedCount = updatedCount + 1
        end
    end

    for i, btn in ipairs(focusEnemyFrames) do
        local new = enemyUnits[i] or "none"
        local current = btn:GetAttribute("unit")

        if current ~= new then
            btn:SetAttribute("unit", new)
            updatedCount = updatedCount + 1
        end
    end

    UpdateAdjacentTargets(friendlyUnits)

    local stop = wow.GetTimePreciseSec()
    fsLog:Debug(string.format("Update targets took %fms, %d updated.", (stop - start) * 1000, updatedCount))
end

local function InitAdjacentTargeting()
    cycleNextFrame = wow.CreateFrame("Button", "FSCycleNextFrame", wow.UIParent, "SecureActionButtonTemplate")
    cyclePreviousFrame = wow.CreateFrame("Button", "FSCyclePreviousFrame", wow.UIParent, "SecureActionButtonTemplate")
    targetNextFrame = wow.CreateFrame("Button", "FSTargetNextFrame", wow.UIParent, "SecureActionButtonTemplate")
    targetPreviousFrame = wow.CreateFrame("Button", "FSTargetPreviousFrame", wow.UIParent, "SecureActionButtonTemplate")

    local buttons = {
        cycleNextFrame,
        cyclePreviousFrame,
        targetNextFrame,
        targetPreviousFrame,
    }

    local downOrUp = wow.GetCVarBool("ActionButtonUseKeyDown") and "AnyDown" or "AnyUp"

    for _, button in ipairs(buttons) do
        button:SetAttribute("type", "target")
        button:RegisterForClicks(downOrUp)
        button:SetAttribute("RelatedButtonsCount", #buttons)

        for j, otherButton in ipairs(buttons) do
            wow.SecureHandlerSetFrameRef(button, "RelatedButton" .. j, otherButton)
        end
    end

    local setIndex = [[
        local index = ...
        local count = self:GetAttribute("RelatedButtonsCount")

        for i = 1, count do
            local button = self:GetFrameRef("RelatedButton" .. i)

            button:SetAttribute("FSIndex", index)
        end
    ]]

    for _, button in ipairs(buttons) do
        button:SetAttribute("SetIndex", setIndex)
    end

    wow.SecureHandlerWrapScript(
        cycleNextFrame,
        "OnClick",
        cycleNextFrame,
        [[
            local maxUnits = self:GetAttribute("FSUnitsCount")
            local index = (self:GetAttribute("FSIndex") or 0) + 1

            -- if we've reached the end, then start from the beginning
            if index > maxUnits then
                index = 1
            end

            self:RunAttribute("SetIndex", index)

            local unit = self:GetAttribute("FSUnit" .. index) or "none"
            self:SetAttribute("unit", unit)
        ]]
    )

    wow.SecureHandlerWrapScript(
        cyclePreviousFrame,
        "OnClick",
        cyclePreviousFrame,
        [[
            local maxUnits = self:GetAttribute("FSUnitsCount")
            local index = (self:GetAttribute("FSIndex") or 0) - 1

            if index <= 0 then
                index = maxUnits
            end

            self:RunAttribute("SetIndex", index)

            local unit = self:GetAttribute("FSUnit" .. index) or "none"
            self:SetAttribute("unit", unit)
        ]]
    )

    wow.SecureHandlerWrapScript(
        targetNextFrame,
        "OnClick",
        targetNextFrame,
        [[
            local maxUnits = self:GetAttribute("FSUnitsCount")
            local index = min((self:GetAttribute("FSIndex") or 0) + 1, maxUnits)

            self:RunAttribute("SetIndex", index)

            local unit = self:GetAttribute("FSUnit" .. index) or "none"
            self:SetAttribute("unit", unit)
        ]]
    )

    wow.SecureHandlerWrapScript(
        targetPreviousFrame,
        "OnClick",
        targetPreviousFrame,
        [[
            local maxUnits = self:GetAttribute("FSUnitsCount")
            local index = max((self:GetAttribute("FSIndex") or 0) - 1, 1)

            self:RunAttribute("SetIndex", index)

            local unit = self:GetAttribute("FSUnit" .. index) or "none"
            self:SetAttribute("unit", unit)
        ]]
    )
end

function M:FriendlyFrames()
    local frames = nil

    -- prefer Blizzard frames
    if fsProviders.Blizzard:Enabled() then
        frames = GetFriendlyFrames(fsProviders.Blizzard)
    end

    if not frames or #frames == 0 then
        local nonBlizzard = fsEnumerable
            :From(fsProviders:Enabled())
            :Where(function(provider)
                return provider ~= fsProviders.Blizzard
            end)
            :ToTable()

        for _, provider in ipairs(nonBlizzard) do
            frames = GetFriendlyFrames(provider)

            if #frames > 0 then
                break
            end
        end
    end

    if not frames or #frames == 0 then
        return {}
    end

    local start1 = wow.GetTimePreciseSec()

    local result = fsEnumerable
        :From(frames)
        :OrderBy(function(x, y)
            return fsCompare:CompareTopLeftFuzzy(x, y)
        end)
        :ToTable()

    local stop1 = wow.GetTimePreciseSec()
    local start2 = wow.GetTimePreciseSec()

    table.sort(frames, function (x, y)
        return fsCompare:CompareTopLeftFuzzy(x, y)
    end)

    local stop2 = wow.GetTimePreciseSec()
    fsLog:Debug(string.format("Testing took took %fms, v2 %fms.", (stop1 - start1) * 1000, (stop2 - start2) * 1000))

    return result
end

function M:FriendlyUnits()
    local frames = M:FriendlyFrames()

    if frames and #frames > 0 then
        return fsEnumerable
            :From(frames)
            :Map(function(x)
                return fsFrame:GetFrameUnit(x)
            end)
            :ToTable()
    end

    -- no frames found, fallback to units
    local units = fsUnit:FriendlyUnits()
    local sortEnabled = fsCompare:FriendlySortMode()

    if not sortEnabled then
        return units
    end

    table.sort(units, fsCompare:SortFunction(units))

    return units
end

function M:FriendlyNonPetUnits()
    return FilterPets(M:FriendlyUnits())
end

function M:EnemyFrames()
    local units = fsUnit:EnemyUnits()
    local sortEnabled = fsCompare:EnemySortMode()

    if not sortEnabled then
        return units
    end

    table.sort(units, fsCompare:EnemySortFunction())

    return units
end

function M:EnemyUnits()
    -- GladiusEx, sArena, and Blizzar all show enemies in group order
    -- arena1, arena2, arena3
    -- so we can just grab the units directly instead of extracting units from frames
    -- this has the benefit of not having to worry about frame visibility and event ordering shenanigans
    local units = fsUnit:EnemyUnits()
    local sortEnabled = fsCompare:EnemySortMode()

    if not sortEnabled then
        return units
    end

    table.sort(units, fsCompare:EnemySortFunction())

    return units
end

function M:EnemyNonPetUnits()
    return FilterPets(M:EnemyUnits())
end

function M:Run()
    assert(not wow.InCombatLockdown())

    UpdateTargets()
end

function M:Init()
    local targetFriendlyCount = 5
    local reverseFriendlyCount = 4
    local targetEnemyCount = 3
    local downOrUp = wow.GetCVarBool("ActionButtonUseKeyDown") and "AnyDown" or "AnyUp"

    if #targetFrames > 0 then
        targetFrames = {}
    end

    if #targetEnemyFrames > 0 then
        targetEnemyFrames = {}
    end

    if #targetReverseFrames > 0 then
        targetReverseFrames = {}
    end

    for i = 1, targetFriendlyCount do
        local button = wow.CreateFrame("Button", "FSTarget" .. i, wow.UIParent, "SecureActionButtonTemplate")
        button:RegisterForClicks(downOrUp)
        button:SetAttribute("type", "target")
        button:SetAttribute("unit", "none")

        -- pet
        local pet = wow.CreateFrame("Button", "FSTargetPet" .. i, wow.UIParent, "SecureActionButtonTemplate")
        pet:RegisterForClicks(downOrUp)
        pet:SetAttribute("type", "target")
        pet:SetAttribute("unit", "none")

        targetFrames[i] = button
        targetPetFrames[i] = pet
    end

    for i = 1, reverseFriendlyCount do
        -- reverse
        local reverse = wow.CreateFrame("Button", "FSTargetBottomMinus" .. i, wow.UIParent, "SecureActionButtonTemplate")
        reverse:RegisterForClicks(downOrUp)
        reverse:SetAttribute("type", "target")
        reverse:SetAttribute("unit", "none")

        targetReverseFrames[i] = reverse
    end

    for i = 1, targetEnemyCount do
        local target = wow.CreateFrame("Button", "FSTargetEnemy" .. i, wow.UIParent, "SecureActionButtonTemplate")
        target:RegisterForClicks(downOrUp)
        target:SetAttribute("type", "target")
        target:SetAttribute("unit", "none")

        local focus = wow.CreateFrame("Button", "FSFocusEnemy" .. i, wow.UIParent, "SecureActionButtonTemplate")
        focus:RegisterForClicks(downOrUp)
        focus:SetAttribute("type", "focus")
        focus:SetAttribute("unit", "none")

        local pet = wow.CreateFrame("Button", "FSTargetEnemyPet" .. i, wow.UIParent, "SecureActionButtonTemplate")
        pet:RegisterForClicks(downOrUp)
        pet:SetAttribute("type", "target")
        pet:SetAttribute("unit", "none")

        targetEnemyFrames[i] = target
        targetEnemyPetFrames[i] = pet
        focusEnemyFrames[i] = focus
    end

    -- target bottom
    targetBottomFrame = wow.CreateFrame("Button", "FSTargetBottom", wow.UIParent, "SecureActionButtonTemplate")
    targetBottomFrame:RegisterForClicks(downOrUp)
    targetBottomFrame:SetAttribute("type", "target")
    targetBottomFrame:SetAttribute("unit", "none")

    InitAdjacentTargeting()
end
