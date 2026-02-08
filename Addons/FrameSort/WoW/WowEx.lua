---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local capabilities = addon.WoW.Capabilities
local fsLog = addon.Logging.Log
local mockInInstance, mockInstanceType

local expansionNames = {
    [0] = "Classic",
    [1] = "The Burning Crusade",
    [2] = "Wrath of the Lich King",
    [3] = "Cataclysm",
    [4] = "Mists of Pandaria",
    [5] = "Warlords of Draenor",
    [6] = "Legion",
    [7] = "Battle for Azeroth",
    [8] = "Shadowlands",
    [9] = "Dragonflight",
    [10] = "The War Within",
    [11] = "Midnight",
}

---@class WowEx
local M = {
    Role = {
        None = "NONE",
        Tank = "TANK",
        Healer = "HEALER",
        Dps = "DAMAGER",
    },
}
addon.WoW.WowEx = M

M.IsInInstance = function()
    local inInstance, instanceType

    if mockInInstance and mockInstanceType then
        inInstance = mockInInstance
        instanceType = mockInstanceType
    else
        inInstance, instanceType = wow.IsInInstance()
    end

    return inInstance, instanceType
end

---Pretend we're in an instance for testing purposes.
M.MockInstance = function(inInstance, instanceType)
    mockInInstance = inInstance
    mockInstanceType = instanceType
end

---Clears the current mocked instance.
M.ClearMockInstance = function()
    mockInInstance = nil
    mockInstanceType = nil
end

---@return boolean
M.IsInstanceArena = function()
    local inInstance, instanceType = M.IsInInstance()

    if not inInstance then
        return false
    end

    return instanceType == "arena"
end

---@return boolean
M.IsInstanceBattleground = function()
    local inInstance, instanceType = M.IsInInstance()
    local isBg = inInstance and instanceType == "pvp"

    if isBg then
        return true
    end

    if type(wow.C_PvP) == "table" and type(wow.C_PvP.IsBattleground) == "function" then
        return wow.C_PvP.IsBattleground()
    end

    return false
end

---@return boolean
M.IsInstanceBrawl = function()
    local inInstance, _ = M.IsInInstance()

    if not inInstance then
        return false
    end

    if type(wow.C_PvP) == "table" and type(wow.C_PvP.IsInBrawl) == "function" then
        return wow.C_PvP.IsInBrawl()
    end

    return false
end

---@return number
M.ArenaOpponentsCount = function()
    -- prefer GetNumArenaOpponentSpecs as it seems reliable
    if capabilities.HasSpecializations() and capabilities.HasEnemySpecSupport() and wow.GetNumArenaOpponentSpecs then
        -- event if 0 is returned, still use it without fallback as it means spec information isn't available anyway
        return wow.GetNumArenaOpponentSpecs()
    end

    if wow.GetNumArenaOpponents then
        -- GetNumArenaOpponents sometimes lies and returns a greater number
        -- e.g. reports 4 enemies in 3v3
        -- seems to be related to pet classes where ally pets are classified as enemies for a split second
        local enemyCount = wow.GetNumArenaOpponents()

        -- compare our friendly group size to get a somewhat reasonable guestimate
        local allyCount = addon.WoW.WowEx.GroupMembersCount()

        return math.min(allyCount, enemyCount)
    end

    return 0
end

---@return number
M.GroupMembersCount = function()
    if wow.GetNumGroupMembers then
        return wow.GetNumGroupMembers()
    end

    if wow.GetNumRaidMembers then
        local count = wow.GetNumRaidMembers()

        if count > 0 then
            return count
        end
    end

    if wow.GetNumPartyMembers then
        local count = wow.GetNumPartyMembers()

        if count > 0 then
            return count
        end
    end

    return 0
end

---Wraps GetArenaOpponentSpec() and returns nil instead of 0
---@param id number
---@return number|nil
M.GetArenaOpponentSpecSafe = function(id)
    if type(id) ~= "number" then
        fsLog:Error("WowEx:GetArenaOpponentSpecSafe() - id must be a number, instead received %s.", type(id))
        return nil
    end

    if not wow.GetArenaOpponentSpec then
        return nil
    end

    local spec = wow.GetArenaOpponentSpec(id)

    if not spec or spec == 0 then
        return nil
    end

    return spec
end

---Wraps GetInspectSpecialization() and returns nil instead of 0
---@param unit string
---@return number|nil
M.GetInspectSpecializationSafe = function(unit)
    if type(unit) ~= "string" then
        fsLog:Error("WowEx:GetInspectSpecializationSafe() - unit must be a string, instead received %s.", type(unit))
        return nil
    end

    if not wow.GetInspectSpecialization then
        return nil
    end

    local spec = wow.GetInspectSpecialization(unit)

    if not spec or spec == 0 then
        return nil
    end

    return spec
end

M.IsAddOnEnabled = function(addonName)
    return wow.GetAddOnEnableState(addonName, wow.UnitName("player")) == 2
end

---Returns the current expansion name and build version.
---@return string expansionName
---@return string buildVersion
M.ExpansionAndBuildInfo = function()
    local buildVersion = "Unknown"

    if wow.GetBuildInfo then
        local version, _, _, _ = wow.GetBuildInfo()
        buildVersion = version or buildVersion
    end

    if LE_EXPANSION_LEVEL_CURRENT == nil then
        return "Unknown", buildVersion
    end

    local expansionName = expansionNames[LE_EXPANSION_LEVEL_CURRENT] or "Unknown"
    return expansionName, buildVersion
end

---Returns true if main tank and assist frames are enabled.
---@return boolean
M.MainTankAndAssistEnabled = function()
    return wow.GetCVarBool("raidOptionDisplayMainTankAndAssist") or false
end
