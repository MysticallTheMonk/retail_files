---@diagnostic disable: undefined-global
---@type string, Addon
local _, addon = ...
---@type WowApi
local wow = {
    -- fields
    C_PvP = C_PvP,
    C_Map = C_Map,

    -- constants
    MAX_RAID_MEMBERS = MAX_RAID_MEMBERS or 40,
    MEMBERS_PER_RAID_GROUP = MEMBERS_PER_RAID_GROUP or 5,

    -- frames
    CreateFrame = CreateFrame,
    UIParent = UIParent,
    CompactPartyFrame = CompactPartyFrame,
    PartyFrame = PartyFrame,
    CompactRaidFrameContainer = CompactRaidFrameContainer,
    CompactArenaFrame = CompactArenaFrame,
    CompactArenaFrameTitle = CompactArenaFrameTitle,
    CompactArenaFrameMember1 = CompactArenaFrameMember1,
    CompactRaidFrameContainer_SetFlowSortFunction = CompactRaidFrameContainer_SetFlowSortFunction,
    CompactRaidFrameManager_GetSetting = CompactRaidFrameManager_GetSetting or function(_)
        return false
    end,

    EditModeManagerFrame = EditModeManagerFrame,

    -- settings
    SlashCmdList = SlashCmdList,
    SettingsPanel = SettingsPanel,
    InterfaceOptions_AddCategory = InterfaceOptions_AddCategory,
    InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory,
    InterfaceOptionsFramePanelContainer = InterfaceOptionsFramePanelContainer,
    Enum = Enum,
    EventRegistry = EventRegistry,
    Settings = Settings,

    -- cvars
    GetCVarBool = GetCVarBool,
    GetCVar = GetCVar,

    -- macro
    GetMacroInfo = GetMacroInfo,
    EditMacro = EditMacro,

    -- unit functions
    UnitName = UnitName,
    GetUnitName = GetUnitName,
    UnitGUID = UnitGUID,
    UnitExists = UnitExists,
    UnitIsUnit = UnitIsUnit,
    UnitInRaid = UnitInRaid,
    UnitIsPlayer = UnitIsPlayer,
    GetRaidRosterInfo = GetRaidRosterInfo,
    GetArenaOpponentSpec = GetArenaOpponentSpec,
    GetSpecializationInfoByID = GetSpecializationInfoByID,
    GetSpecialization = GetSpecialization,
    GetInspectSpecialization = GetInspectSpecialization,
    UnitGroupRolesAssigned = UnitGroupRolesAssigned,
    UnitIsGroupLeader = UnitIsGroupLeader,
    PromoteToLeader = PromoteToLeader,

    -- state functions
    IsInInstance = IsInInstance,
    IsInGroup = IsInGroup or function()
        return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
    end,

    IsInRaid = IsInRaid,
    InCombatLockdown = InCombatLockdown,

    -- group size functions
    GetNumGroupMembers = GetNumGroupMembers,
    GetNumArenaOpponentSpecs = GetNumArenaOpponentSpecs or GetNumArenaOpponents,

    -- utility
    wipe = wipe,
    CopyTable = CopyTable,
    strjoin = function(delimiter, ...)
        if strjoin then
            return strjoin(delimiter, unpack(...))
        end

        local joined = ""

        for i, str in ipairs(...) do
            if i > 1 then
                joined = joined .. delimiter .. str
            else
                joined = str
            end
        end

        return joined
    end,

    -- secure functions
    issecurevariable = issecurevariable,
    hooksecurefunc = hooksecurefunc,
    RegisterAttributeDriver = RegisterAttributeDriver,
    UnregisterAttributeDriver = UnregisterAttributeDriver,
    RegisterUnitWatch = RegisterUnitWatch,
    UnregisterUnitWatch = UnregisterUnitWatch,

    -- other
    ReloadUI = ReloadUI,
    C_Timer = C_Timer,
    GetLocale = GetLocale,
    GetRealmName = GetRealmName,
    GetRealZoneText = GetRealZoneText,

    -- addon related
    GetAddonInfo = C_AddOns and C_AddOns.GetAddonInfo or GetAddonInfo,
    GetAddOnEnableState = function(character, name)
        -- in wotlk private 3.4.3 C_AddOns exists but C_AddOns.GetAddOnEnableState doesn't
        if C_AddOns and C_AddOns.GetAddOnEnableState then
            -- argument order is reversed
            return C_AddOns.GetAddOnEnableState(name, character)
        end

        if GetAddOnEnableState then
            return GetAddOnEnableState(character, name)
        end

        local getAddonInfo = C_AddOns and C_AddOns.GetAddonInfo or GetAddonInfo
        local _, _, _, loadable, reason, _, _ = getAddonInfo(name)

        if loadable and not reason then
            return 1
        else
            return 0
        end
    end,
    GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata,

    -- time related
    GetTimePreciseSec = GetTimePreciseSec or function()
        return debugprofilestop() / 1000
    end,

    -- used for older clients that don't have the new attribute driver functions
    RegisterStateDriver = RegisterStateDriver,
    UnregisterStateDriver = UnregisterStateDriver,
    SecureHandlerWrapScript = SecureHandlerWrapScript,
    SecureHandlerSetFrameRef = SecureHandlerSetFrameRef,
    SecureHandlerExecute = SecureHandlerExecute,

    -- non-blizzard related
    IsRetail = function()
        return WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
    end,
    IsWotlk = function()
        return WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
    end,
    IsCata = function()
        return WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
    end,
    IsClassic = function()
        return WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
    end,
    IsWotlkPrivate = function()
        local version = GetBuildInfo()
        return version == "3.3.5"
    end,

    ---@class WowEvents
    Events = {
        -- Fired after ending combat, as regen rates return to normal.
        -- Useful for determining when a player has left combat.
        -- This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were involved with.
        -- It seems Blizzard do an update layout after combat ends, so even for the experimental mode we also need to re-sort.
        PLAYER_REGEN_ENABLED = "PLAYER_REGEN_ENABLED",

        -- Fired whenever you enter combat, as normal regen rates are disabled during combat.
        -- This means that either you are in the hate list of a NPC or that you've been taking part in a pvp action (either as attacker or victim).
        PLAYER_REGEN_DISABLED = "PLAYER_REGEN_DISABLED",

        -- Fires when the player logs in, /reloads the UI or zones between map instances.
        -- Basically whenever the loading screen appears.
        PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD",

        -- Fired whenever a group or raid is formed or disbanded, players are leaving or joining the group or raid.
        GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE",

        -- Fired when people within the raid group change their tank/healer/dps role.
        PLAYER_ROLES_ASSIGNED = "PLAYER_ROLES_ASSIGNED",

        -- Fired when a pet is created/destroyed which performs a frame layout.
        UNIT_PET = "UNIT_PET",

        -- Retail only even that's fired at the start of each arena match/round when the opponent specs have been loaded.
        ARENA_PREP_OPPONENT_SPECIALIZATIONS = "ARENA_PREP_OPPONENT_SPECIALIZATIONS",

        ARENA_OPPONENT_UPDATE = "ARENA_OPPONENT_UPDATE",

        -- Special event that's fired when the user closes edit mode.
        -- Can only be used directly on EventRegistry and not via RegisterScript()
        EditModeExit = "EditMode.Exit",

        -- Fires when changing console variables with an optional argument to C_CVar.SetCVar().
        CVAR_UPDATE = "CVAR_UPDATE",

        -- Fired when switching to a different layout from edit mode.
        EDIT_MODE_LAYOUTS_UPDATED = "EDIT_MODE_LAYOUTS_UPDATED",

        -- Fired when a unit's name updates (both ally and enemy units)
        UNIT_NAME_UPDATE = "UNIT_NAME_UPDATE",

        -- fired when some sort of timer starts, e.g. time until arena/bg gates open
        START_TIMER = "START_TIMER",

        -- fired when a macro is created/deleted/updated
        UPDATE_MACROS = "UPDATE_MACROS",

        -- fires at start/end of an arena match/round
        PVP_MATCH_STATE_CHANGED = "PVP_MATCH_STATE_CHANGED"
    },
}

addon.WoW.Api = wow

-- shims for older clients
local nextFrameId = 1

local function FrameShims(frame)
    -- classic
    if not frame.Text and frame.text then
        frame.Text = frame.text
    end

    -- wotlk private
    if not frame.Text then
        frame.Text = {
            SetFontObject = function(_, fontName)
                local textFrame = _G[frame:GetName() .. "Text"]
                return textFrame:SetFontObject(fontName)
            end,
            SetText = function(_, text)
                local textFrame = _G[frame:GetName() .. "Text"]
                textFrame:SetText(text)
            end,
        }

        local originalCreateFontString = frame.CreateFontString
        frame.CreateFontString = function(...)
            local fontString = originalCreateFontString(...)
            FrameShims(fontString)
            return fontString
        end
    end

    -- wotlk private
    frame.SetShown = frame.SetShown or function(self, show)
        if show then
            self:Show()
        else
            self:Hide()
        end
    end

    -- wotlk private
    frame.SetAttributeNoHandler = frame.SetAttributeNoHandler or function(self, ...)
        self:SetAttribute(...)
    end

    -- wotlk private
    frame.SetObeyStepOnDrag = frame.SetObeyStepOnDrag or function() end
end

wow.CreateFrame = function(frameType, name, parent, template, id)
    if not name and wow.IsWotlkPrivate() then
        -- wotlk private requires name to not be nil
        name = "FSDummyName" .. nextFrameId
        nextFrameId = nextFrameId + 1
    end

    -- wotlk private doesn't have this
    if template == "BackdropTemplate" and not BackdropTemplateMixin then
        template = nil
    end

    local frame = CreateFrame(frameType, name, parent, template, id)
    FrameShims(frame)
    return frame
end

wow.RegisterAttributeDriver = wow.RegisterAttributeDriver
    or function(frame, attribute, conditional)
        local attributeWithoutState = string.gsub(attribute, "state%-", "")
        wow.RegisterStateDriver(frame, attributeWithoutState, conditional)
    end

wow.UnregisterAttributeDriver = wow.UnregisterAttributeDriver
    or function(frame, attribute)
        local attributeWithoutState = string.gsub(attribute, "state%-", "")
        wow.UnregisterStateDriver(frame, attributeWithoutState)
    end

-- for unit tests
wow.CopyTable = wow.CopyTable or function(t)
    local new = {}

    for k, v in pairs(t) do
        new[k] = v
    end

    return new
end
