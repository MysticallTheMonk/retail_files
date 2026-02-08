-- luacheck: ignore 113
---@diagnostic disable: undefined-global
---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api

---@class ClientCapabilities
local M = {}

addon.WoW.Capabilities = M

function M.HasModernDropdown()
    return MenuUtil and MenuUtil.CreateRadioMenu
end

function M.HasEnemySpecSupport()
    -- MoP onwards have these functions; early xpacs do not
    return wow.GetArenaOpponentSpec ~= nil and wow.GetSpecializationInfoByID ~= nil and (wow.GetNumArenaOpponentSpecs or wow.GetNumArenaOpponents) ~= nil
end

function M.HasArena()
    return LE_EXPANSION_LEVEL_CURRENT ~= nil and LE_EXPANSION_BURNING_CRUSADE ~= nil and LE_EXPANSION_LEVEL_CURRENT >= LE_EXPANSION_BURNING_CRUSADE
end

function M.Has5v5()
    return LE_EXPANSION_LEVEL_CURRENT ~= nil and LE_EXPANSION_BURNING_CRUSADE ~= nil and LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE
end

function M.CanOpenOptionsDuringCombat()
    if LE_EXPANSION_LEVEL_CURRENT == nil or LE_EXPANSION_MIDNIGHT == nil then
        return true
    end

    return LE_EXPANSION_LEVEL_CURRENT < LE_EXPANSION_MIDNIGHT
end

function M.HasC_PvP()
    return type(wow.C_PvP) == "table"
end

function M.HasC_Map()
    return type(wow.C_Map) == "table" and type(wow.C_Map.GetBestMapForUnit) == "function"
end

function M.HasC_Timer()
    return type(wow.C_Timer) == "table" and type(wow.C_Timer.After) == "function"
end

function M.HasSoloShuffle()
    return M.HasC_PvP() and type(wow.C_PvP.IsSoloShuffle) == "function" and type(wow.Enum) == "table" and wow.Enum.PvPMatchState ~= nil and type(wow.C_PvP.GetActiveMatchState) == "function"
end

function M.HasBrawl()
    return M.HasC_PvP() and type(wow.C_PvP.IsInBrawl) == "function"
end

function M.HasC_TooltipInfo()
    return type(wow.C_TooltipInfo) == "table" and type(wow.C_TooltipInfo.GetUnit) == "function"
end

function M.HasEditMode()
    return wow.EditModeManagerFrame ~= nil and wow.EditModeManagerFrame.UseRaidStylePartyFrames ~= nil and wow.EditModeManagerFrame.GetSettingValue ~= nil and wow.EventRegistry ~= nil
end

---Whether or not UnitGroupRolesAssigned is available.
function M.HasRoleAssignments()
    return type(wow.UnitGroupRolesAssigned) == "function"
end

---Specs were introduced in MoP, and prior expansions used a talent system.
---@return boolean
function M.HasSpecializations()
    return LE_EXPANSION_LEVEL_CURRENT ~= nil and LE_EXPANSION_MISTS_OF_PANDARIA ~= nil and LE_EXPANSION_LEVEL_CURRENT >= LE_EXPANSION_MISTS_OF_PANDARIA
end

---MoP for some reason ignores the raidOptionDisplayMainTankAndAssist cvar.
---@return boolean
function M.HasMainTankAndAssistFrames()
    return LE_EXPANSION_LEVEL_CURRENT ~= nil and (LE_EXPANSION_MISTS_OF_PANDARIA == nil or LE_EXPANSION_LEVEL_CURRENT ~= LE_EXPANSION_MISTS_OF_PANDARIA)
end

function M.HasPvPMatchState()
    return M.HasC_PvP() and type(wow.Enum) == "table" and wow.Enum.PvPMatchState ~= nil and type(wow.C_PvP.GetActiveMatchState) == "function"
end

function M.CanGetArenaNameplates()
    -- since 12.0.1 you can no longer do C_NamePlate:GetNamePlateForUnit("arenaX")
    local _, _, _, build = GetBuildInfo()
    return build < 120001
end
