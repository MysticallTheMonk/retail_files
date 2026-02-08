---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local fsUnit = addon.WoW.Unit
local fsSortedUnits = addon.Modules.Sorting.SortedUnits
local fsSortedFrames = addon.Modules.Sorting.SortedFrames
local fsEnumerable = addon.Collections.Enumerable
local fsCompare = addon.Modules.Sorting.Comparer
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
local cycleNextDpsFrame = nil
local cyclePreviousDpsFrame = nil

---@class TargetingModule: IInitialise
local M = {}
addon.Modules.Targeting = M

local function FriendlyUnits()
    local sortEnabled = fsCompare:FriendlySortMode()

    if sortEnabled then
        return fsSortedUnits:FriendlyUnits()
    end

    -- sort not enabled, fallback to frames
    local frames = fsSortedFrames:FriendlyFrames()

    return fsEnumerable
        :From(frames)
        :Map(function(x)
            return fsFrame:GetFrameUnit(x)
        end)
        :ToTable()
end

local function UpdateAdjacentTargets(friendlyUnits)
    assert(cycleNextFrame)
    assert(cyclePreviousFrame)
    assert(targetNextFrame)
    assert(targetPreviousFrame)
    assert(cycleNextDpsFrame)
    assert(cyclePreviousDpsFrame)

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

    local dpsUnits = fsEnumerable
        :From(friendlyUnits)
        :Where(function(unit)
            return wow.UnitGroupRolesAssigned(unit) == wowEx.Role.Dps
        end)
        :ToTable()

    cycleNextDpsFrame:SetAttribute("FSUnitsCount", #dpsUnits)
    cyclePreviousDpsFrame:SetAttribute("FSUnitsCount", #dpsUnits)

    for index, unit in ipairs(dpsUnits) do
        cycleNextDpsFrame:SetAttribute("FSUnit" .. index, unit)
        cyclePreviousDpsFrame:SetAttribute("FSUnit" .. index, unit)
    end
end

local function FilterPets(units)
    return fsEnumerable
        :From(units)
        :Where(function(x)
            return not fsUnit:IsPet(x)
        end)
        :ToTable()
end

local function UpdateTargets()
    local updatedCount = 0
    local start = wow.GetTimePreciseSec()
    local friendlyUnits = FilterPets(FriendlyUnits())

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

    local enemyUnits = FilterPets(fsSortedUnits:ArenaUnits())

    for i, btn in ipairs(targetEnemyFrames) do
        local new = enemyUnits[i] or "none"
        local current = btn:GetAttribute("unit")

        if current ~= new then
            btn:SetAttribute("unit", new)
            updatedCount = updatedCount + 1
        end
    end

    for i, btn in ipairs(targetEnemyPetFrames) do
        local new = fsUnit:PetFor(enemyUnits[i] or "none", true)
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
    fsLog:Debug("Update targets took %fms, %d updated.", (stop - start) * 1000, updatedCount)
end

local function InitAdjacentTargeting()
    targetNextFrame = wow.CreateFrame("Button", "FSTargetNextFrame", wow.UIParent, "SecureActionButtonTemplate")
    targetPreviousFrame = wow.CreateFrame("Button", "FSTargetPreviousFrame", wow.UIParent, "SecureActionButtonTemplate")
    cycleNextFrame = wow.CreateFrame("Button", "FSCycleNextFrame", wow.UIParent, "SecureActionButtonTemplate")
    cyclePreviousFrame = wow.CreateFrame("Button", "FSCyclePreviousFrame", wow.UIParent, "SecureActionButtonTemplate")
    cycleNextDpsFrame = wow.CreateFrame("Button", "FSCycleNextDpsFrame", wow.UIParent, "SecureActionButtonTemplate")
    cyclePreviousDpsFrame = wow.CreateFrame("Button", "FSCyclePreviousDpsFrame", wow.UIParent, "SecureActionButtonTemplate")

    local buttons = {
        targetNextFrame,
        targetPreviousFrame,
        cycleNextFrame,
        cyclePreviousFrame,
        cycleNextDpsFrame,
        cyclePreviousDpsFrame,
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
            local maxUnits = self:GetAttribute("FSUnitsCount") or 0

            if maxUnits == 0 then
                return
            end

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
            local maxUnits = self:GetAttribute("FSUnitsCount") or 0

            if maxUnits == 0 then
                return
            end

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
            local maxUnits = self:GetAttribute("FSUnitsCount") or 0

            if maxUnits == 0 then
                return
            end

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
            local maxUnits = self:GetAttribute("FSUnitsCount") or 0

            if maxUnits == 0 then
                return
            end

            local index = max((self:GetAttribute("FSIndex") or 0) - 1, 1)

            self:RunAttribute("SetIndex", index)

            local unit = self:GetAttribute("FSUnit" .. index) or "none"
            self:SetAttribute("unit", unit)
        ]]
    )

    wow.SecureHandlerWrapScript(
        cycleNextDpsFrame,
        "OnClick",
        cycleNextDpsFrame,
        [[
            local maxUnits = self:GetAttribute("FSUnitsCount") or 0

            if maxUnits == 0 then
                return
            end

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
        cyclePreviousDpsFrame,
        "OnClick",
        cyclePreviousDpsFrame,
        [[
            local maxUnits = self:GetAttribute("FSUnitsCount") or 0

            if maxUnits == 0 then
                return
            end

            local index = (self:GetAttribute("FSIndex") or 0) - 1

            if index <= 0 then
                index = maxUnits
            end

            self:RunAttribute("SetIndex", index)

            local unit = self:GetAttribute("FSUnit" .. index) or "none"
            self:SetAttribute("unit", unit)
        ]]
    )
end

function M:Run()
    if wow.InCombatLockdown() then
        fsLog:Error("Cannot run targeting module during combat.")
        return
    end

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
    fsLog:Debug("Initialised the targeting module.")
end
