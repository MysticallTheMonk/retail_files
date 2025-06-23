local _, NS = ...
local Timers = NS.Timers
local Icons = NS.Icons
local Info = NS.Info
local IsInBrawl = _G.C_PvP.IsInBrawl

local Diminish = CreateFrame("Frame")
Diminish:RegisterEvent("PLAYER_LOGIN")
Diminish:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, ...)
end)

-- used for Diminish_Options
NS.Diminish = Diminish
_G.DIMINISH_NS = NS

local unitEvents = {
    target = "PLAYER_TARGET_CHANGED",
    party = "GROUP_ROSTER_UPDATE, GROUP_JOINED", -- csv
    player = "COMBAT_LOG_EVENT_UNFILTERED",
    nameplate = "NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED",
    arena = not NS.IS_CLASSIC and "ARENA_OPPONENT_UPDATE" or nil,
    focus = not NS.IS_CLASSIC and "PLAYER_FOCUS_CHANGED" or nil,
}

function Diminish:ToggleUnitEvent(events, enable)
    for event in gmatch(events or "", "([^,%s]+)") do -- csv loop
        if enable then
            if not self:IsEventRegistered(event) then
                self:RegisterEvent(event)
                --[==[@debug@
                NS.Debug("Registered %s for instance %s.", event, self.currInstanceType)
                --@end-debug@]==]
            end
        else
            if self:IsEventRegistered(event) then
                self:UnregisterEvent(event)
                --[==[@debug@
                NS.Debug("Unregistered %s for instance %s.", event, self.currInstanceType)
                --@end-debug@]==]
            end
        end
    end
end

function Diminish:ToggleForZone(dontRunEnable)
    self.currInstanceType = select(2, IsInInstance())
    local registeredOnce = false

    if NS.IS_RETAIL then
        if self.currInstanceType == "arena" then
            -- HACK: check if inside arena brawl, C_PvP.IsInBrawl() doesn't
            -- always work on PLAYER_ENTERING_WORLD so delay it with this event.
            -- Once event is fired it'll call ToggleForZone again
            self:RegisterEvent("PVP_BRAWL_INFO_UPDATED")
        else
            self:UnregisterEvent("PVP_BRAWL_INFO_UPDATED")
        end

        -- PVP_BRAWL_INFO_UPDATED triggered ToggleForZone
        if self.currInstanceType == "arena" and IsInBrawl() then
            self.currInstanceType = "pvp" -- treat arena brawl as a battleground
            self:UnregisterEvent("PVP_BRAWL_INFO_UPDATED")
        end
    end

    -- (Un)register unit events for current zone depending on user settings
    for unit, settings in pairs(NS.db.unitFrames) do -- DR tracking for focus/target etc each have their own seperate settings
        local events = unitEvents[unit]

        if settings.enabled then
            -- Loop through every zone/instance enabled and see if we're currently in that instance
            for zone, state in pairs(settings.zones) do
                if state and zone == self.currInstanceType then
                    registeredOnce = true
                    settings.isEnabledForZone = true
                    self:ToggleUnitEvent(events, true)
                    break
                else
                    settings.isEnabledForZone = false
                    self:ToggleUnitEvent(events, false)
                end
            end
        else -- unitframe is not enabled for tracking at all
            settings.isEnabledForZone = false
            self:ToggleUnitEvent(events, false)
        end
    end

    if dontRunEnable then
        -- PVP_BRAWL_INFO_UPDATED triggered ToggleForZone again,
        -- so dont run Enable() twice, just update vars
        return self:SetCLEUWatchVariables()
    end

    if registeredOnce then -- atleast 1 event has been registered for zone
        self:Enable()
    else
        self:Disable()
    end
end

function Diminish:SetCLEUWatchVariables()
    local cfg = NS.db.unitFrames

    local targetOrFocusWatchFriendly = false
    if cfg.target.watchFriendly and cfg.target.isEnabledForZone then
        targetOrFocusWatchFriendly = true
    elseif cfg.focus.watchFriendly and cfg.focus.isEnabledForZone then
        targetOrFocusWatchFriendly = true
    elseif cfg.nameplate.watchFriendly and cfg.nameplate.isEnabledForZone then
        targetOrFocusWatchFriendly = true
    end

    -- PvE mode
    self.isWatchingNPCs = NS.db.trackNPCs
    if not cfg.target.isEnabledForZone and not cfg.focus.isEnabledForZone and not cfg.nameplate.isEnabledForZone then
        -- PvE mode only works for target/focus/nameplate so disable mode if those frames are not active
        self.isWatchingNPCs = false
    end

    -- Check if we're tracking any friendly units and not just enemy only
    self.isWatchingFriendly = false
    if cfg.player.isEnabledForZone or cfg.party.isEnabledForZone or targetOrFocusWatchFriendly then
        self.isWatchingFriendly = true
    end

    -- Check if only PlayerFrame tracking is enabled for friendly, if it is
    -- we want to ignore all friendly units later in CLEU except where destGUID == playerGUID
    self.onlyPlayerWatchFriendly = cfg.player.isEnabledForZone
    if cfg.player.isEnabledForZone then
        if cfg.party.isEnabledForZone or targetOrFocusWatchFriendly then
            self.onlyPlayerWatchFriendly = false
        end
    end

    -- Check if we're only tracking friendly units so we can ignore enemy units in CLEU
    self.onlyFriendlyTracking = true
    if cfg.target.isEnabledForZone or cfg.focus.isEnabledForZone or cfg.arena.isEnabledForZone or cfg.nameplate.isEnabledForZone then
        self.onlyFriendlyTracking = false
    end

    -- Check if we're only tracking friendly party members so we can ignore outsiders
    self.onlyTrackingPartyForFriendly = cfg.party.isEnabledForZone
    if targetOrFocusWatchFriendly then
        self.onlyTrackingPartyForFriendly = false
    end
end

function Diminish:Disable()
    self:UnregisterAllEvents()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CVAR_UPDATE")
    Timers:ResetAll(true)

    --[==[@debug@
    Info("Disabled addon for zone %s.", self.currInstanceType)
    --@end-debug@]==]
end

function Diminish:Enable()
    Timers:ResetAll(true)

    self:SetCLEUWatchVariables()
    self:GROUP_ROSTER_UPDATE()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    --[==[@debug@
    Info("Enabled addon for zone %s.", self.currInstanceType)
    --@end-debug@]==]
end

function Diminish:InitDB()
    DiminishDB = DiminishDB and next(DiminishDB) ~= nil and DiminishDB or {
        profileKeys = {},
        profiles = {},
    }

    local playerName = UnitName("player") .. "-" .. GetRealmName()
    local profile = DiminishDB.profileKeys[playerName]

    if not profile or not DiminishDB.profiles[profile] then
        -- Profile doesn't exist or is deleted, reset to default
        DiminishDB.profileKeys[playerName] = "Default"
        profile = "Default"
    end

    -- Reset config if the config version is too old
    if DiminishDB.profiles[profile] then
        if not DiminishDB.profiles[profile].version then
            DiminishDB = {
                profileKeys = { [playerName] = "Default" },
                profiles = {},
            }
            profile = "Default"
        else
            local version = gsub(DiminishDB.profiles[profile].version, "%.", "")
            version = tonumber(version)
            if version <= 19 then
                DiminishDB = {
                    profileKeys = { [playerName] = "Default" },
                    profiles = {},
                }
                profile = "Default"
            end
        end
    end

    -- Copy any settings from default if they don't exist in current profile
    NS.CopyDefaults({
        [profile] = NS.DEFAULT_SETTINGS
    }, DiminishDB.profiles)

    -- Reference to active db profile
    -- Always use this directly or reference will be invalid
    -- after changing profile in Diminish_Options
    NS.db = DiminishDB.profiles[profile]
    NS.db.version = NS.DEFAULT_SETTINGS.version
    NS.activeProfile = profile

    if NS.IS_NOT_RETAIL and NS.db.unitFrames.player.usePersonalNameplate then
        NS.db.unitFrames.player.usePersonalNameplate = false
    end
    if NS.IS_CLASSIC then
        NS.db.unitFrames.focus.enabled = false
        NS.db.unitFrames.arena.enabled = false
    end

    -- Remove table values no longer found in default settings
    NS.CleanupDB(DiminishDB.profiles[profile], NS.DEFAULT_SETTINGS)

    if not C_AddOns.IsAddOnLoaded("Diminish_Options") then
        -- Cleanup functions/tables only used for Diminish_Options when it's not loaded
        NS.DEFAULT_SETTINGS = nil
        NS.CopyDefaults = nil
        NS.CleanupDB = nil
        Icons.OnFrameConfigChanged = nil
    end

    self.InitDB = nil
end

--------------------------------------------------------------
-- Events
--------------------------------------------------------------

local strfind = _G.string.find
local UnitIsUnit = _G.UnitIsUnit

function Diminish:PLAYER_LOGIN()
    self:InitDB()

    local Masque = LibStub and LibStub("Masque", true)
    NS.MasqueGroup = Masque and Masque:Group("Diminish")
    if EditModeManagerFrame and EditModeManagerFrame.UseRaidStylePartyFrames then
        NS.useCompactPartyFrames = EditModeManagerFrame:UseRaidStylePartyFrames()
    else
        NS.useCompactPartyFrames = GetCVarBool("useCompactPartyFrames")
    end
    self.PLAYER_GUID = UnitGUID("player")
    self.PLAYER_CLASS = select(2, UnitClass("player"))

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CVAR_UPDATE")
    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil
end

function Diminish:CVAR_UPDATE(name, value)
    if name == "USE_RAID_STYLE_PARTY_FRAMES" then
        NS.useCompactPartyFrames = value ~= "0"
        Icons:AnchorPartyFrames()
    end
end

if NS.IS_RETAIL then
    hooksecurefunc(EditModeManagerFrame, "OnSystemSettingChange", function()
        NS.useCompactPartyFrames = EditModeManagerFrame:UseRaidStylePartyFrames()
        if next(NS.db or {}) then -- is initialized
            Icons:AnchorPartyFrames()
        end
    end)

    function Diminish:PVP_BRAWL_INFO_UPDATED()
        if not IsInBrawl() then
            self:UnregisterEvent("PVP_BRAWL_INFO_UPDATED")
        else
            self:ToggleForZone(true)
        end
    end
end

function Diminish:PLAYER_ENTERING_WORLD()
    self:ToggleForZone()
end

function Diminish:PLAYER_TARGET_CHANGED()
    Timers:Refresh("target")
end

function Diminish:PLAYER_FOCUS_CHANGED()
    Timers:Refresh("focus")
end

function Diminish:NAME_PLATE_UNIT_ADDED(namePlateUnitToken)
    if UnitIsUnit("player", namePlateUnitToken) then
        if not NS.db.unitFrames.player.usePersonalNameplate then return end
    end

    Timers:Refresh(namePlateUnitToken)

    if DIMINISH_OPTIONS and DIMINISH_OPTIONS.TestMode:IsTesting() then
        Timers:Refresh("nameplate")
    end
end

function Diminish:NAME_PLATE_UNIT_REMOVED(namePlateUnitToken)
    Icons:ReleaseNameplate(namePlateUnitToken)
end

function Diminish:ARENA_OPPONENT_UPDATE(unitID, status)
    if status == "seen" and not strfind(unitID, "pet") then
        if IsInBrawl() and not NS.db.unitFrames.arena.zones.pvp then return end
        Timers:Refresh(unitID)
    end
end

function Diminish:GROUP_ROSTER_UPDATE()
    local members = min(GetNumGroupMembers(), 4)
    Icons:AnchorPartyFrames(members)

    -- Refresh every single party member, even if they have already just been refreshed
    -- incase unit IDs have been shifted
    for i = 1, 5 do
        if UnitExists("party"..i) then
            Timers:Refresh("party"..i)
        else
            Timers:RemoveActiveGUID("party"..i)
        end
    end
end
Diminish.GROUP_JOINED = Diminish.GROUP_ROSTER_UPDATE
hooksecurefunc("CompactRaidGroup_UpdateLayout", function()
    if next(NS.db or {}) then -- is initialized
        Diminish:GROUP_ROSTER_UPDATE()
    end
end)

-- Combat log scanning for DRs
do
    local COMBATLOG_PARTY_MEMBER = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY)
    local COMBATLOG_OBJECT_REACTION_FRIENDLY = _G.COMBATLOG_OBJECT_REACTION_FRIENDLY
    local COMBATLOG_OBJECT_TYPE_PLAYER = _G.COMBATLOG_OBJECT_TYPE_PLAYER
    local COMBATLOG_OBJECT_CONTROL_PLAYER = _G.COMBATLOG_OBJECT_CONTROL_PLAYER
    local CombatLogGetCurrentEventInfo = _G.CombatLogGetCurrentEventInfo
    local bit_band = _G.bit.band

    local IS_NOT_RETAIL = NS.IS_NOT_RETAIL
    local CATEGORY_STUN = NS.CATEGORIES.stun
    local CATEGORY_TAUNT = NS.CATEGORIES.taunt
    local CATEGORY_ROOT = NS.CATEGORIES.root
    local CATEGORY_INCAP = NS.CATEGORIES.incapacitate
    local CATEGORY_DISORIENT = NS.CATEGORIES.disorient
    local CATEGORY_KIDNEY = NS.CATEGORIES.kidney_shot
    local CATEGORY_OPENER_STUN = NS.CATEGORIES.opener_stun
    local CATEGORY_RNGSTUN = NS.CATEGORIES.random_stun
    local DRList = LibStub("DRList-1.0")

    function Diminish:COMBAT_LOG_EVENT_UNFILTERED()
        local _, eventType, _, srcGUID, _, srcFlags, _, destGUID, _, destFlags, _, spellID, _, _, auraType = CombatLogGetCurrentEventInfo()
        if not destGUID then return end -- sanity check

        if auraType == "DEBUFF" then
            if eventType ~= "SPELL_AURA_REMOVED" and eventType ~= "SPELL_AURA_APPLIED" and eventType ~= "SPELL_AURA_REFRESH" then return end

            local category = DRList:GetCategoryBySpellID(spellID)
            if not category or category == "knockback" then return end
            category = DRList:GetCategoryLocalization(category)

            local isMindControlled = false
            local isNotPetOrPlayer = false
            local isPlayer = bit_band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0
            if not isPlayer then
                if strfind(destGUID, "Player-") then
                    -- Players have same bitmask as player pets when they're mindcontrolled and MC aura breaks, so we need to distinguish these
                    -- so we can ignore the player pets but not actual players
                    isMindControlled = true
                end
                if not self.isWatchingNPCs and not isMindControlled then return end

                if bit_band(destFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) <= 0 then -- is not player pet or is not MCed
                    if IS_NOT_RETAIL then
                        if category ~= CATEGORY_STUN and category ~= CATEGORY_KIDNEY and category ~= CATEGORY_RNGSTUN and category ~= CATEGORY_OPENER_STUN then return end
                    else
                        if category ~= CATEGORY_STUN and category ~= CATEGORY_TAUNT and category ~= CATEGORY_ROOT and category ~= CATEGORY_INCAP and category ~= CATEGORY_DISORIENT then
                            -- only show taunt and stun for normal mobs (roots/incaps/disorient for special mobs), player pets will show all
                            return
                        end
                    end
                    isNotPetOrPlayer = true
                end
            else
                -- Ignore taunts for players
                if category == CATEGORY_TAUNT then return end
                if IS_NOT_RETAIL then
                    local isSrcPlayer = bit_band(srcFlags, COMBATLOG_OBJECT_CONTROL_PLAYER) > 0
                    if not isSrcPlayer then return end
                end
            end

            local isFriendly = bit_band(destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) ~= 0
            if isMindControlled then
                isFriendly = not isFriendly -- reverse values
            end

            if not isFriendly and self.onlyFriendlyTracking then return end

            if isFriendly then
                if not self.isWatchingFriendly then return end

                if self.onlyPlayerWatchFriendly then
                    -- Only store friendly timers for player
                    if destGUID ~= self.PLAYER_GUID  then return end
                end

                if self.onlyTrackingPartyForFriendly then
                    -- Only store friendly timers for party1-4 and player
                    if bit_band(destFlags, COMBATLOG_PARTY_MEMBER) == 0 then return end
                end
            end

            if eventType == "SPELL_AURA_REMOVED" then
                Timers:Insert(destGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, false)
            elseif eventType == "SPELL_AURA_APPLIED" then
                Timers:Insert(destGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, true)
            elseif eventType == "SPELL_AURA_REFRESH" then
                Timers:Update(destGUID, srcGUID, category, spellID, isFriendly, isNotPetOrPlayer, true)
            end
        end

        -------------------------------------------------------------------------------------------------------

        if eventType == "UNIT_DIED" or eventType == "PARTY_KILL" then
            if self.currInstanceType == "arena" and not IsInBrawl() then return end

            -- Delete all timers when player died
            if destGUID == self.PLAYER_GUID then
                if self.PLAYER_CLASS == "HUNTER" then
                    -- Don't delete if player is Feign Deathing
                    if NS.GetAuraDuration("player", 5384) then return end
                end

                return Timers:ResetAll()
            end

            -- Delete all timers for unit that died
            Timers:Remove(destGUID, false)
        end
    end
end
