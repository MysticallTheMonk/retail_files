---@diagnostic disable: assign-type-mismatch
-- luacheck: ignore 113
---@diagnostic disable: undefined-global
---@type string, Addon
local _, addon = ...
---@type WowApi
local api = {
    -- fields
    C_PvP = C_PvP,
    C_Map = C_Map,
    C_Timer = C_Timer,
    C_AddOns = C_AddOns,
    C_TooltipInfo = C_TooltipInfo,

    -- constants
    MAX_RAID_MEMBERS = MAX_RAID_MEMBERS or 40,
    MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS or 4,
    MEMBERS_PER_RAID_GROUP = MEMBERS_PER_RAID_GROUP or 5,
    RAID_CLASS_COLORS = RAID_CLASS_COLORS,

    -- frames
    CreateFrame = CreateFrame,
    CompactRaidFrameContainer_SetFlowSortFunction = CompactRaidFrameContainer_SetFlowSortFunction,
    CompactRaidFrameManager_GetSetting = CompactRaidFrameManager_GetSetting,

    -- mouse
    GetCursorPosition = GetCursorPosition,

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
    GetUnitName = GetUnitName,
    UnitName = UnitName,
    UnitGUID = UnitGUID,
    UnitExists = UnitExists,
    UnitClass = UnitClass,
    UnitIsUnit = UnitIsUnit,
    UnitIsEnemy = UnitIsEnemy,
    UnitIsFriend = UnitIsFriend,
    UnitInRaid = UnitInRaid,
    UnitIsPlayer = UnitIsPlayer,
    UnitIsConnected = UnitIsConnected,
    UnitIsGroupLeader = UnitIsGroupLeader,
    UnitGroupRolesAssigned = UnitGroupRolesAssigned,
    UnitFactionGroup = UnitFactionGroup,
    GetRaidRosterInfo = GetRaidRosterInfo,
    GetArenaOpponentSpec = GetArenaOpponentSpec,
    GetSpecializationInfoByID = GetSpecializationInfoByID,
    GetSpecialization = GetSpecialization,
    GetInspectSpecialization = GetInspectSpecialization,
    GetSpecializationInfo = GetSpecializationInfo,
    PromoteToLeader = PromoteToLeader,

    -- inspect functions
    CanInspect = CanInspect,
    NotifyInspect = NotifyInspect,
    ClearInspectPlayer = ClearInspectPlayer,

    -- state functions
    IsInInstance = IsInInstance,
    IsInGroup = IsInGroup,
    IsInRaid = IsInRaid,
    InCombatLockdown = InCombatLockdown,
    GetInstanceInfo = GetInstanceInfo,

    -- group size functions
    GetNumGroupMembers = GetNumGroupMembers,
    GetNumArenaOpponentSpecs = GetNumArenaOpponentSpecs,
    GetNumArenaOpponents = GetNumArenaOpponents,
    GetNumRaidMembers = GetNumRaidMembers,
    GetNumPartyMembers = GetNumPartyMembers,

    -- utility
    wipe = wipe,
    CopyTable = CopyTable,

    -- secure functions
    issecurevariable = issecurevariable,
    hooksecurefunc = hooksecurefunc,
    RegisterAttributeDriver = RegisterAttributeDriver,
    UnregisterAttributeDriver = UnregisterAttributeDriver,
    -- used for older clients that don't have the new attribute driver functions
    RegisterStateDriver = RegisterStateDriver,
    UnregisterStateDriver = UnregisterStateDriver,
    RegisterUnitWatch = RegisterUnitWatch,
    UnregisterUnitWatch = UnregisterUnitWatch,
    SecureHandlerWrapScript = SecureHandlerWrapScript,
    SecureHandlerSetFrameRef = SecureHandlerSetFrameRef,
    SecureHandlerExecute = SecureHandlerExecute,

    -- class related
    GetClassInfo = GetClassInfo,
    GetNumSpecializationsForClassID = C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID or GetNumSpecializationsForClassID,
    GetSpecializationInfoForClassID = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoForClassID or GetSpecializationInfoForClassID,

    -- bg related
    GetNumBattlefieldScores = GetNumBattlefieldScores,
    GetBattlefieldScore = GetBattlefieldScore,

    -- other
    ReloadUI = ReloadUI,
    GetLocale = GetLocale,
    GetRealmName = GetRealmName,
    GetRealZoneText = GetRealZoneText,

    -- addon related
    -- don't fallback to GetAddOnEnableState as we let our shim handle that
    GetAddOnEnableState = C_AddOns and C_AddOns.GetAddOnEnableState or false,
    GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata,

    -- time related
    GetTimePreciseSec = GetTimePreciseSec,

    -- secrets
    issecretvalue = issecretvalue,

    -- client info
    GetBuildInfo = GetBuildInfo,
}

-- Fall back to _G for anything we didn't explicitly pin in api.
-- This avoids nil-snapshot issues for load-on-demand Blizzard frames.
-- note this hasn't ever actually happened, but better safe than sorry
addon.WoW.Api = setmetatable(api, { __index = _G })
