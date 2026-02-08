---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local events = addon.WoW.Events
local capabilities = addon.WoW.Capabilities
local fsUnit = addon.WoW.Unit
local fsEnumerable = addon.Collections.Enumerable
local fsLog = addon.Logging.Log
---@class AutoLeaderModule : IInitialise, IProcessEvents, IRun
local M = {}
addon.Modules.AutoLeader = M

-- keep track of whether the healer had leader
-- so that if the healer passes leader onto someone else
-- then we don't want to re-promote the healer again
local healerHadLeader = false

local function Run()
    if healerHadLeader then
        return
    end

    local units = fsUnit:FriendlyUnits()
    local healer = fsEnumerable:From(units):First(function(unit)
        local role = wow.UnitGroupRolesAssigned(unit)
        return role == "HEALER"
    end)

    if not healer then
        return
    end

    if wow.UnitIsGroupLeader(healer) then
        healerHadLeader = true
        return
    end

    -- if we aren't leader, exit
    if not wow.UnitIsGroupLeader("player") then
        return
    end
    -- if we are the healer, exit
    if wow.UnitIsUnit("player", healer) then
        return
    end

    fsLog:Debug("Auto promoting healer unit %s to leader.", healer)
    wow.PromoteToLeader(healer)
end

local function OnStateChanged()
    if not capabilities.HasSoloShuffle() then
        return
    end

    local state = wow.C_PvP.GetActiveMatchState()

    if state == wow.Enum.PvPMatchState.PostRound or state == wow.Enum.PvPMatchState.Complete then
        -- reset our flag
        healerHadLeader = false
    end
end

local function CanRun()
    if not capabilities.HasSoloShuffle() or not capabilities.HasRoleAssignments() then
        return false
    end

    return (wow.UnitIsGroupLeader and wow.UnitIsUnit and wow.PromoteToLeader) ~= nil
end

function M:ProcessEvent(event)
    if event == events.PVP_MATCH_STATE_CHANGED then
        OnStateChanged()
    end
end

function M:Init()
    if not CanRun() then
        fsLog:Debug("AutoLeader module not loading because this wow client doesn't have solo shuffle.")
        return
    end

    fsLog:Debug("Initialised the auto leader module.")
end

function M:Run()
    if not addon.DB.Options.AutoLeader.Enabled then
        return
    end

    if not CanRun() then
        return
    end

    -- only run in the waiting room
    -- unfortunately this event fires too early for us to run our promote leader code
    -- as the group hasn't yet formed when this even fires
    -- https://warcraft.wiki.gg/wiki/API_C_PvP.GetActiveMatchState
    if wow.C_PvP.GetActiveMatchState() ~= wow.Enum.PvPMatchState.StartUp then
        return
    end

    Run()
end
