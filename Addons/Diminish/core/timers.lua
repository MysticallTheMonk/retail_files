local _, NS = ...
local Timers = {}
NS.Timers = Timers

local StopTimers, StartTimers
local activeTimers = {}
local activeGUIDs = {}

local DR_TIME = NS.DR_TIME
local Icons = NS.Icons
local Debug = NS.Debug
local NewTable = NS.NewTable
local RemoveTable = NS.RemoveTable

local UnitGUID = _G.UnitGUID
local GetPlayerInfoByGUID = _G.GetPlayerInfoByGUID
local GetTime = _G.GetTime
local gsub = _G.string.gsub
local pairs = _G.pairs
local next = _G.next

local function TimerIsFinished(timer, timestamp)
    return (timestamp or GetTime()) >= (timer.expiration or 0)
end

function Timers:Insert(unitGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, isApplied, testMode)
    if isApplied then -- SPELL_AURA_APPLIED
        if NS.db.timerStartAuraEnd and not testMode then
            -- on timerStartAuraEnd=true mode we start timer on SPELL_AURA_REMOVED instead of SPELL_AURA_APPLIED.
            return
        end
    else -- SPELL_AURA_REMOVED
        if not NS.db.timerStartAuraEnd then
            if activeTimers[unitGUID] and activeTimers[unitGUID][category] then
                -- Update timer expiration without updating indicator color for this mode
                return self:Update(unitGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, nil, isApplied, true)
            end
        end
    end

    local timers = activeTimers[unitGUID]
    if timers and timers[category] then
        -- Timer already active, update everything
        return self:Update(unitGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, true)
    end

    if not timers then
        activeTimers[unitGUID] = {}
    end

    local drTime = --[[isNotPetOrPlayer and 20 or]] DR_TIME
    local timer = NewTable() -- table pooling from helpers.lua
    timer.expiration = GetTime() + (not testMode and drTime or random(6, drTime))
    timer.applied = not testMode and 1 or random(1, 3)
    timer.category = category
    timer.isFriendly = isFriendly
    timer.spellID = spellID
    timer.unitGUID = unitGUID
    timer.srcGUID = srcGUID
    timer.isNotPetOrPlayer = isNotPetOrPlayer
    timer.testMode = testMode

    local _, englishClass = GetPlayerInfoByGUID(unitGUID)
    timer.unitClass = englishClass

    activeTimers[unitGUID][category] = timer
    StartTimers(timer, isApplied, nil, nil, nil, not isApplied)
end

function Timers:Update(unitGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, updateApplied, isApplied, onAuraEnd)
    local timer = activeTimers[unitGUID] and activeTimers[unitGUID][category]
    if not timer then
        if isApplied or updateApplied then
            -- SPELL_AURA_APPLIED/BROKEN didn't detect DR, but REFRESH did
            Timers:Insert(unitGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, false, nil, true)
        end
        return
    end

    if updateApplied then
        timer.applied = (timer.applied or 0) + 1
    end

    local drTime = --[[isNotPetOrPlayer and 20 or]] DR_TIME
    timer.spellID = spellID
    timer.isFriendly = isFriendly
    timer.expiration = GetTime() + (not timer.testMode and drTime or random(6, drTime))

    StartTimers(timer, true, nil, true, nil, onAuraEnd)
end

function Timers:Remove(unitGUID, category, noStop)
    local timers = activeTimers[unitGUID]
    if not timers then return end

    if category then
        local timer = timers[category]
        if not timer then return end

        if not noStop then
            StopTimers(timer, nil, true)
        end

        if timers then
            RemoveTable(timers[category])
            timers[category] = nil -- remove ref to table in pool but not table itself
        end
    elseif category == false then
        -- Stop all active timers for guid (UNIT_DIED, PARTY_KILL)
        -- Only ran outside arena.

        for cat, t in pairs(timers) do
            -- UNIT_DIED is fired for Feign Death so ignore hunters here
            if t.unitClass == "HUNTER" then return end

            if not noStop then
                StopTimers(t, nil, true)
            end

            RemoveTable(t)
            timers[cat] = nil
        end
    end

    if not next(timers) then
        RemoveTable(timers)
        activeTimers[unitGUID] = nil
    end
end

function Timers:Refresh(unitID)
    local unitGUID = UnitGUID(unitID)
    local prevGUID = activeGUIDs[unitID]
    activeGUIDs[unitID] = unitGUID

    if unitID == "nameplate" then -- testmode when "nameplate" and not "nameplateX"
        unitGUID = UnitGUID("player")
    end

    if not unitGUID then return end

    -- Hide active timers belonging to previous guid
    -- Note, its probably faster to always just :Hide() frames but this
    -- will also delete any old timers
    if prevGUID and prevGUID ~= unitGUID and activeTimers[prevGUID] then
        for category, timer in pairs(activeTimers[prevGUID]) do
            StopTimers(timer, unitID, true)
        end
    else
        -- No prev guid available, hide ALL frames for this unitID instead
        if NS.iconFrames[unitID] then
            for category, frame in pairs(NS.iconFrames[unitID]) do
                if not Icons:ReleaseFrame(frame, unitID, nil, category) then
                    if frame.shown then
                        frame.shown = false
                        frame:Hide()
                    end
                end
            end
        end
    end

    -- Start or delete timers belonging to current guid
    if activeTimers[unitGUID] then
        local currTime = GetTime()

        for category, timer in pairs(activeTimers[unitGUID]) do
            if not TimerIsFinished(timer, currTime) then
                StartTimers(timer, true, unitID, nil, true)
            else
                StopTimers(timer, unitID)
            end
        end
    end
end

C_Timer.NewTicker(55, function()
    -- Remove inactive timers every X seconds incase they
    -- weren't detected in Refresh(), UNIT_DIED or OnHide script for removal
    if NS.Diminish.currInstanceType ~= "arena" then
        local currTime = GetTime()
        for guid, categories in pairs(activeTimers) do
            for cat, timer in pairs(categories) do
                if TimerIsFinished(timer, currTime) then
                    StopTimers(timer)
                end
            end
        end
    end

    -- Free table pool.
    -- Normally this is free'd on loading screens, but when we're outdoors i.e questing, there
    -- may not be a loading screen happening for a long period of time so attempt to free every 55s here instead
    -- to avoid too much memory filling up
    if not next(activeTimers) and NS.Diminish.currInstanceType == "none" then
        if not UnitAffectingCombat("player") then
            NS.ReleaseTables()
        end
    end
end)

function Timers:RemoveActiveGUID(unitID)
    activeGUIDs[unitID] = nil
end

function Timers:ResetAll(clearGUIDs)
    Icons:HideAll()

    for guid, categories in pairs(activeTimers) do
        for cat, t in pairs(categories) do
            RemoveTable(t)
            categories[cat] = nil
        end

        RemoveTable(activeTimers[guid])
        activeTimers[guid] = nil
    end

    NS.ReleaseTables()

    if clearGUIDs then
        for unitID, guid in pairs(activeGUIDs) do
            if not UnitExists(unitID) or UnitGUID(unitID) ~= guid then -- compare guids for nameplates
                activeGUIDs[unitID] = nil
            end
        end
    end

    if not activeGUIDs.player then
        -- cache on first Diminish:Enable()
        activeGUIDs.player = UnitGUID("player")
    end

    --[==[@debug@
    Debug("Stopped all timers.")
    --@end-debug@]==]
end

do
    local GetAuraDuration = NS.GetAuraDuration
    local CATEGORY_TAUNT = NS.CATEGORIES.taunt
    local CATEGORY_ROOT = NS.CATEGORIES.root
    local CATEGORY_INCAP = NS.CATEGORIES.incapacitate
    local CATEGORY_DISORIENT = NS.CATEGORIES.disorient
    local UnitIsQuestBoss = _G.UnitIsQuestBoss
    local UnitClassification = _G.UnitClassification

    local testModeUnits = {
        "player", "target", "nameplate",
        "party1", "party2", "party3",
    }
    if not NS.IS_CLASSIC then
        tinsert(testModeUnits, "focus")
        tinsert(testModeUnits, "arena1")
        tinsert(testModeUnits, "arena2")
        tinsert(testModeUnits, "arena3")
    end

    local function Start(timer, isApplied, unitID, isUpdate, isRefresh, onAuraEnd)
        local origUnitID
        if unitID == "player-party" then -- CompactRaidFrame for player (no partyX id available for player)
            unitID = "party"  -- just so we can use party settings below
            origUnitID = "player" -- real unit ID used for blizzard functions, player-party will be used for Diminish functions
        end

        -- Check if disabled
        local settings = NS.db.unitFrames[gsub(unitID, "%d", "")]
        if not settings or not settings.enabled then return end
        if not timer.testMode and not settings.isEnabledForZone then return end
        if not settings.watchFriendly and timer.isFriendly then return end
        if settings.disabledCategories[timer.category] then return end

        -- Show root/taunt/incap/disorients DR only for special mobs
        if NS.IS_RETAIL then
            if timer.isNotPetOrPlayer and (timer.category == CATEGORY_ROOT or timer.category == CATEGORY_TAUNT or timer.category == CATEGORY_INCAP or timer.category == CATEGORY_DISORIENT) then
                local classification = UnitClassification(unitID)
                if classification == "normal" or classification == "trivial" or classification == "minus" then
                    if not UnitIsQuestBoss(unitID) then
                        -- No need to keep tracking it, just delete timer and return
                        return Timers:Remove(timer.unitGUID, timer.category, true)
                    end
                end
            end
        end

        -- Add aura duration to DR timer(18s) if using display mode on aura start
        if isApplied and not NS.db.timerStartAuraEnd then
            if not timer.testMode --[[and not isRefresh]] then
                local _, expirationTime = GetAuraDuration(origUnitID or unitID, timer.spellID)

                if expirationTime and expirationTime > 0 then
                    timer.expiration = (expirationTime or GetTime()) + (--[[timer.isNotPetOrPlayer and 20 or]] DR_TIME)
                end
            end
        end

        Icons:StartCooldown(timer, origUnitID and "player-party" or unitID, onAuraEnd)
        --[==[@debug@
        Debug("%s timer %s:%s", isUpdate and "Updated" or "Started", origUnitID and "player-party" or unitID, timer.category)
        --@end-debug@]==]
    end

    local function Stop(timer, unitID, preventRemove, isFinished)
        Icons:StopCooldown(timer, unitID, isFinished)
        --[==[@debug@
        Debug("Stop/pause timer %s:%s", unitID, timer.category or "nil")
        --@end-debug@]==]

        if not preventRemove then
            -- f.cooldown OnHide script won't trigger :Remove() if the parent (unitframe) is hidden
            -- so attempt to remove timer here aswell if it isn't already being removed or we're just refreshing
            Timers:Remove(timer.unitGUID, timer.category, true)
        end
    end

    function StartTimers(timer, isApplied, unit, isUpdate, isRefresh, onAuraEnd)
        if timer.testMode then
            -- When testing, we want to show timers for all enabled frames
            for i = 1, #testModeUnits do
                Start(timer, isApplied, testModeUnits[i], isUpdate, isRefresh, onAuraEnd)
            end
            return
        end

        if unit then
            -- Start/update timer only for this unitID
            return Start(timer, isApplied, unit, isUpdate, isRefresh, onAuraEnd)
        end

        -- Start timer for EVERY unitID that matches timer unit guid.
        local unitGUID = timer.unitGUID
        for _unit, guid in pairs(activeGUIDs) do
            if guid == unitGUID then
                Start(timer, isApplied, _unit, isUpdate, isRefresh, onAuraEnd)

                if _unit == "player" then
                    if NS.db.unitFrames.party.isEnabledForZone then
                        Start(timer, isApplied, "player-party", isUpdate, isRefresh, onAuraEnd)
                    end
                end
            end
        end
    end

    function StopTimers(timer, unit, preventRemove)
        local isFinished = TimerIsFinished(timer) -- cache result for loops below

        if timer.testMode then
            for i = 1, #testModeUnits do
                Stop(timer, testModeUnits[i], preventRemove, isFinished)
            end
            return
        end

        if unit then
            return Stop(timer, unit, preventRemove, isFinished)
        end

        local unitGUID = timer.unitGUID
        for _unit, guid in pairs(activeGUIDs) do
            if guid == unitGUID then
                Stop(timer, _unit, preventRemove, isFinished)

                if _unit == "player" then
                    Stop(timer, "player-party", true, isFinished)
                end
            end
        end
    end
end
