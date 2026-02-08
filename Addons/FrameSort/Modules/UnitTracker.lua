---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsProviders = addon.Providers
local fsLog = addon.Logging.Log
local fsFrame = addon.WoW.Frame
local fsUnit = addon.WoW.Unit

---@class UnitTrackerModule : IInitialise
local M = {}
addon.Modules.UnitTracker = M

-- Cache: unitToken -> frame
local frameByUnit = {}
-- Reverse cache: frame -> unitToken (so we can clean up stale unit entries when frames get reassigned)
local unitByFrame = {}

local function ClearFrameMapping(frame)
    local oldUnit = unitByFrame[frame]

    if oldUnit then
        if frameByUnit[oldUnit] == frame then
            frameByUnit[oldUnit] = nil
        end

        unitByFrame[frame] = nil
    end
end

local function SetFrameMapping(frame, unit)
    if not frame or not unit then
        return
    end

    if fsFrame:IsForbidden(frame) then
        return
    end

    unit = fsUnit:NormaliseUnit(unit) or unit

    -- If this frame was previously mapped to another unit, clear that old mapping.
    ClearFrameMapping(frame)

    frameByUnit[unit] = frame
    unitByFrame[frame] = unit
end

local function OnSetUnit(frame, unit)
    SetFrameMapping(frame, unit)
end

local function FrameIsUsable(frame)
    if not frame or fsFrame:IsForbidden(frame) then
        return false
    end

    if frame.IsVisible and frame:IsVisible() then
        return true
    end

    return false
end

local function MatchesUnit(frameUnit, unit)
    if not frameUnit or not unit then
        return false
    end

    if frameUnit == unit then
        return true
    end

    local isUnitOrSecret = wow.UnitIsUnit(frameUnit, unit)
    if wow.issecretvalue(isUnitOrSecret) then
        return false
    end

    return isUnitOrSecret == true
end

local function FindUnitFrame(frames, unit)
    local fallback = nil

    for _, frame in ipairs(frames) do
        if frame and not fsFrame:IsForbidden(frame) then
            local frameUnit = fsFrame:GetFrameUnit(frame)

            if MatchesUnit(frameUnit, unit) then
                -- Prefer a usable/visible frame immediately
                if frame.IsVisible and frame:IsVisible() then
                    return frame
                end

                -- Otherwise remember a hidden match as fallback
                fallback = fallback or frame
            end
        end
    end

    return fallback
end

function M:GetFrameForUnit(unit)
    if not unit then
        fsLog:Error("UnitTracker:GetFrameForUnit() - unit must not be nil.")
        return nil
    end

    unit = fsUnit:NormaliseUnit(unit) or unit

    local cachedFrame = frameByUnit[unit]

    -- Purge forbidden cached frames immediately
    if cachedFrame and fsFrame:IsForbidden(cachedFrame) then
        ClearFrameMapping(cachedFrame)
        cachedFrame = nil
    end

    -- Validate cached frame still matches the unit
    if cachedFrame then
        local frameUnit = fsFrame:GetFrameUnit(cachedFrame)

        if frameUnit and MatchesUnit(frameUnit, unit) then
            -- Only return immediately if visible/usable; otherwise we'll try to find a better visible frame.
            if FrameIsUsable(cachedFrame) then
                return cachedFrame
            end
        else
            -- Frame no longer represents this unit; clear stale mapping.
            if unitByFrame[cachedFrame] == unit then
                unitByFrame[cachedFrame] = nil
            end

            if frameByUnit[unit] == cachedFrame then
                frameByUnit[unit] = nil
            end

            cachedFrame = nil
        end
    end

    local isFriendly = fsUnit:IsFriendlyUnit(unit)

    for _, provider in ipairs(fsProviders:Enabled()) do
        if isFriendly then
            local party = fsFrame:PartyFrames(provider, false)
            local partyFound = FindUnitFrame(party, unit)

            if partyFound then
                cachedFrame = partyFound
                SetFrameMapping(partyFound, unit)

                if FrameIsUsable(cachedFrame) then
                    return cachedFrame
                end
            end

            local raid = fsFrame:RaidFrames(provider, false)
            local raidFound = FindUnitFrame(raid, unit)

            if raidFound then
                cachedFrame = raidFound
                SetFrameMapping(raidFound, unit)

                if FrameIsUsable(cachedFrame) then
                    return cachedFrame
                end
            end
        else
            local arena = fsFrame:ArenaFrames(provider, false)
            local arenaFound = FindUnitFrame(arena, unit)

            if arenaFound then
                cachedFrame = arenaFound
                SetFrameMapping(arenaFound, unit)

                if FrameIsUsable(cachedFrame) then
                    return cachedFrame
                end
            end
        end
    end

    -- Fallback to whatever we found (may be hidden).
    if cachedFrame and not fsFrame:IsForbidden(cachedFrame) then
        return cachedFrame
    end

    return nil
end

function M:Init()
    if type(CompactUnitFrame_SetUnit) == "function" then
        wow.hooksecurefunc("CompactUnitFrame_SetUnit", OnSetUnit)
    else
        fsLog:Warning("CompactUnitFrame_SetUnit API not available for the unit tracker module.")
    end

    fsLog:Debug("Initialised the unit tracker module.")
end
