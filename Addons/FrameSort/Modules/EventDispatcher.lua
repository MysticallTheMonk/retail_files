---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local events = addon.WoW.Events
local capabilities = addon.WoW.Capabilities
local fsSortedUnits = addon.Modules.Sorting.SortedUnits
local fsRunner = addon.Modules
local fsProviders = addon.Providers
local fsInspector = addon.Modules.Inspector
local fsAutoLeader = addon.Modules.AutoLeader
local fsScheduler = addon.Scheduling.Scheduler
local fsLog = addon.Logging.Log
local eventsFrame = nil

-- the reason for this class is so we can guarantee the order events are processed in
---@class EventDispatcher : IInitialise
local M = {}
addon.Modules.EventDispatcher = M

local function OnEvent(_, event, ...)
    local args = { ... }

    if #args > 0 then
        for i = 1, #args do
            args[i] = tostring(args[i])
        end

        local argsString = table.concat(args, ", ")
        fsLog:Debug("Event: %s %s.", event, argsString)
    else
        fsLog:Debug("Event: %s.", event)
    end

    -- prioritise the scheduler
    fsScheduler:ProcessEvent(event)

    -- then pass to our sorted units cache in case it needs to be invalidated
    fsSortedUnits:ProcessEvent(event, ...)

    -- now pass to providers
    local providers = fsProviders:EnabledNotSelfManaged()

    for _, provider in ipairs(providers) do
        if provider.ProcessEvent then
            provider:ProcessEvent(event, ...)
        end
    end

    -- now the inspector
    fsInspector:ProcessEvent(event, ...)

    -- now the auto leader
    fsAutoLeader:ProcessEvent(event)

    -- lastly pass to runner
    fsRunner:ProcessEvent(event, ...)
end

function M:Init()
    eventsFrame = wow.CreateFrame("Frame")
    eventsFrame:SetScript("OnEvent", OnEvent)

    -- loading screen
    eventsFrame:RegisterEvent(events.PLAYER_ENTERING_WORLD)

    -- friendly unit change events
    eventsFrame:RegisterEvent(events.GROUP_ROSTER_UPDATE)
    eventsFrame:RegisterEvent(events.PLAYER_ROLES_ASSIGNED)

    if capabilities.HasSpecializations() then
        eventsFrame:RegisterEvent(events.PLAYER_SPECIALIZATION_CHANGED)
    end

    -- arena unit change events
    eventsFrame:RegisterEvent(events.ARENA_OPPONENT_UPDATE)

    if capabilities.HasSpecializations() and capabilities.HasEnemySpecSupport() then
        eventsFrame:RegisterEvent(events.ARENA_PREP_OPPONENT_SPECIALIZATIONS)
    end

    -- friendly/enemy pet unit events
    eventsFrame:RegisterEvent(events.UNIT_PET)

    -- cvars changed
    eventsFrame:RegisterEvent(events.CVAR_UPDATE)

    -- combat events
    eventsFrame:RegisterEvent(events.PLAYER_REGEN_ENABLED)
    eventsFrame:RegisterEvent(events.PLAYER_REGEN_DISABLED)

    -- arena events
    if capabilities.HasPvPMatchState() then
        eventsFrame:RegisterEvent(events.PVP_MATCH_STATE_CHANGED)
    end

    -- inspection
    if fsInspector:CanRun() then
        eventsFrame:RegisterEvent(events.INSPECT_READY)
    end
end
