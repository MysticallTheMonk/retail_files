---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local capabilities = addon.WoW.Capabilities
local fsLog = addon.Logging.Log
local fsSortedUnits = addon.Modules.Sorting.SortedUnits
local fsUnit = addon.WoW.Unit
local fsInspector = addon.Modules.Inspector
local events = addon.WoW.Events
local hasPlatynator = wowEx.IsAddOnEnabled("Platynator")
local eventsFrame
local wasFriendlyEnabled = false
local wasEnemyEnabled = false
---@class NameplatesModule : IInitialise
local M = {}
addon.Modules.Nameplates = M

local function SetPlatynatorText(nameplateUnit, text)
    if type(Platynator) ~= "table" or type(Platynator.API) ~= "table" or type(Platynator.API.SetUnitTextOverride) ~= "function" then
        return false
    end

    Platynator.API.SetUnitTextOverride(nameplateUnit, text, nil)
    return true
end

local function FrameText(unit, friendly, frameNumber)
    local config = addon.DB.Options.Nameplates
    local text = (friendly and config.FriendlyFormat or config.EnemyFormat) or "$framenumber"
    local name = (wow.UnitName and wow.UnitName(unit)) or "unknown"

    local specText = nil
    if capabilities.HasSpecializations() and wow.GetSpecializationInfoByID then
        local specId = friendly and fsInspector:FriendlyUnitSpec(unit) or fsInspector:EnemyUnitSpec(unit)
        if specId then
            local _, specName = wow.GetSpecializationInfoByID(specId)
            specText = specName
        end
    end

    local vars = {
        framenumber = tostring(frameNumber),
        unit = unit,
        name = name,
        spec = specText or "unknown",
    }

    -- case-insensitive replacement while preserving original text casing
    text = text:gsub("%$(%a+)", function(key)
        local value = vars[key:lower()]
        return value ~= nil and value or "$" .. key
    end)

    return text
end

local function SetNameplateText(unitFrame, unit, text)
    if hasPlatynator then
        if not SetPlatynatorText(unit, text) then
            fsLog:WarnOnce("Failed to set Platynator nameplate text for unit %s.", unit)
        end
    elseif unitFrame.name and type(unitFrame.name.SetText) == "function" then
        unitFrame.name:SetText(text)
    else
        fsLog:WarnOnce("Failed to set nameplate text for unit %s.", unit)
    end
end

local function RestoreNames()
    if not wow.C_NamePlate or not wow.C_NamePlate.GetNamePlates then
        return
    end

    for _, plate in ipairs(wow.C_NamePlate.GetNamePlates()) do
        local unitFrame = plate.UnitFrame

        if unitFrame and unitFrame.unit and wow.UnitExists(unitFrame.unit) then
            local isFriendly = fsUnit:IsFriendlyUnit(unitFrame.unit)
            local name = wow.UnitName(unitFrame.unit)

            if isFriendly and not addon.DB.Options.Nameplates.FriendlyEnabled then
                SetNameplateText(unitFrame, unitFrame.unit, name)
            elseif not isFriendly and not addon.DB.Options.Nameplates.EnemyEnabled then
                SetNameplateText(unitFrame, unitFrame.unit, name)
            end
        end
    end
end

local function OnUpdateName(unitFrame)
    if not unitFrame then
        return
    end

    local unit = unitFrame.unit

    if not unit then
        return
    end

    -- ignore pets and npcs
    if not wow.UnitIsPlayer(unitFrame.unit) then
        return
    end

    -- only operate on nameplates, as this hook is used by raid frames too
    if not string.find(unit, "nameplate") then
        return
    end

    local friendly = fsUnit:IsFriendlyUnit(unit)

    if friendly and not addon.DB.Options.Nameplates.FriendlyEnabled then
        if wasFriendlyEnabled then
            -- User has disabled the option, restore unit names
            RestoreNames()
        end

        wasFriendlyEnabled = false
        return
    end

    if not friendly and not addon.DB.Options.Nameplates.EnemyEnabled then
        if wasEnemyEnabled then
            RestoreNames()
        end

        wasEnemyEnabled = false
        return
    end

    local frameNumber, resolvedUnit = fsSortedUnits:FrameNumberForUnit(unit)

    if not frameNumber or not resolvedUnit then
        return
    end

    local text = FrameText(resolvedUnit, friendly, frameNumber)

    SetNameplateText(unitFrame, unit, text)

    wasFriendlyEnabled = addon.DB.Options.Nameplates.FriendlyEnabled
    wasEnemyEnabled = addon.DB.Options.Nameplates.EnemyEnabled
end

local function RefreshNameplates()
    if not wow.C_NamePlate or not wow.C_NamePlate.GetNamePlates then
        return
    end

    for _, plate in ipairs(wow.C_NamePlate.GetNamePlates()) do
        local unitFrame = plate.UnitFrame
        if unitFrame then
            OnUpdateName(unitFrame)
        end
    end
end

local function OnNameplateAdded(_, event, unit)
    local nameplate = unit and wow.C_NamePlate.GetNamePlateForUnit(unit)

    if not nameplate then
        return
    end

    local unitFrame = nameplate.UnitFrame
    if unitFrame then
        OnUpdateName(unitFrame)
    end
end

function M:CanRun()
    return CompactUnitFrame_UpdateName ~= nil or (wow.C_NamePlate and wow.C_NamePlate.GetNamePlates) ~= nil
end

function M:Run()
    RefreshNameplates()
end

function M:Init()
    if not M:CanRun() then
        fsLog:Warning("Nameplates module unable to run.")
        return
    end

    if CompactUnitFrame_UpdateName then
        wow.hooksecurefunc("CompactUnitFrame_UpdateName", OnUpdateName)
    end

    if hasPlatynator then
        eventsFrame = wow.CreateFrame("Frame")
        eventsFrame:RegisterEvent(events.NAME_PLATE_UNIT_ADDED)
        eventsFrame:SetScript("OnEvent", OnNameplateAdded)
    end

    fsLog:Debug("Initialised the nameplates module.")
end
