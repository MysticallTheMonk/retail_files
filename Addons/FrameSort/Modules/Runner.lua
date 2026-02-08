---@type string, Addon
local _, addon = ...
local fsProviders = addon.Providers
local fsScheduler = addon.Scheduling.Scheduler
local fsInspector = addon.Modules.Inspector
local fsUnit = addon.WoW.Unit
local fsLog = addon.Logging.Log
local fsEnumerable = addon.Collections.Enumerable
local wow = addon.WoW.Api
local events = addon.WoW.Events
local M = addon.Modules
local timerFrame = nil
local run = false
local runAll = false
---@type { [FrameProvider]: boolean }
local runProviders = {}

local function Run(forceRunAll)
    local ok, result = pcall(function()
        local all = runAll or forceRunAll
        local providers = nil

        runAll = false

        if all then
            -- clear stale requests
            runProviders = {}
        else
            providers = {}

            for provider, _ in pairs(runProviders) do
                providers[#providers + 1] = provider
            end

            runProviders = {}
        end

        M:Run(providers)
    end)

    if not ok then
        fsLog:Error("Runner - error: %s.", tostring(result))
    end
end

local function OnUpdate()
    if not run then
        assert(timerFrame)
        timerFrame:SetScript("OnUpdate", nil)
        return
    end

    run = false
    Run()
end

local function ScheduleSort(provider)
    if provider then
        runProviders[provider] = true
    else
        runAll = true
    end

    run = true

    assert(timerFrame)
    timerFrame:SetScript("OnUpdate", OnUpdate)
end

local function OnProviderRequestedSort(provider, reason)
    fsLog:Debug("Provider '%s' requested sort due to '%s'.", provider and provider:Name() or "nil", reason or "nil")

    ScheduleSort(provider)
end

local function OnEnteringWorld()
    fsLog:Debug("Scheduling sort after loading screen.")

    ScheduleSort()
end

local function OnEnteringCombat()
    if not run then
        return
    end

    run = false

    -- we are entering combat, last chance to run a sort if one was scheduled
    -- there is a scenario with Gladius where an enemy stealthy comes out of stealth
    -- at the same time as the play enters combat, e.g. a rogue cheapshot on you
    -- at this time an ARENA_OPPONENT_UPDATE is sent with "seen" parameter
    -- which triggers gladius to reposition it's frames
    -- by default we would then schedule a sort to occur, but I think it's too late
    -- as OnUpdate may have already ran this frame, and the next frame we are in lockdown
    -- this is all conjecture, need to confirm what order of events this happens in
    -- and whether this is actually needed or not
    -- TODO: is this required, or will OnUpdate run anyway?
    fsLog:Debug("Running sort just before combat starts.")
    Run(true)
end

local function OnInspectorInfo()
    -- technically it's beneficial if we know at least 2 specs then perform a sort
    -- but from a practical standpoint it's probably better for performance to wait until we have quorum
    -- and it might help reduce frame flicker as it reduces sorting noise
    local units = fsUnit:FriendlyUnits()

    if #units == 0 then
        return
    end

    local nonPets = fsEnumerable
        :From(units)
        :Where(function(unit)
            return not fsUnit:IsPet(unit)
        end)
        :ToTable()

    local knownSpecs = 0

    for i = 1, #nonPets do
        local unit = nonPets[i]
        local spec = fsInspector:FriendlyUnitSpec(unit)

        if spec then
            knownSpecs = knownSpecs + 1
        end
    end

    -- re-sort every 5th spec known
    local everyNth = 5
    local shouldSort = knownSpecs > 0 and knownSpecs == #nonPets or knownSpecs % everyNth == 0

    if not shouldSort then
        return
    end

    fsLog:Debug("Scheduling sort as we have spec quorum of %d/%d.", knownSpecs, #nonPets)
    ScheduleSort()
end

function M:ProcessEvent(event)
    if event == events.PLAYER_REGEN_DISABLED then
        OnEnteringCombat()
    elseif event == events.PLAYER_ENTERING_WORLD then
        OnEnteringWorld()
    end
end

function M:Run(providers)
    fsScheduler:RunWhenCombatEnds(function()
        local start = wow.GetTimePreciseSec()
        fsLog:Debug("--- Starting run ---")

        -- run auto promotion first
        addon.Modules.AutoLeader:Run()

        -- run hide player next as it may impact the rest
        addon.Modules.HidePlayer:Run()

        -- now sort as it affects targeting and macros
        if providers and #providers > 0 then
            for _, provider in ipairs(providers) do
                addon.Modules.Sorting:Run(provider)
            end
        else
            addon.Modules.Sorting:Run()
        end

        addon.Modules.Targeting:Run()
        addon.Modules.Macro:Run()
        addon.Modules.Nameplates:Run()

        local stop = wow.GetTimePreciseSec()
        fsLog:Debug("Run time took %fms.", (stop - start) * 1000)
        fsLog:Debug("--- Finished run ---")
    end, "Runner")
end

---Initialises all modules.
function M:Init()
    addon.Modules.Sorting.SortedUnits:Init()
    addon.Modules.AutoLeader:Init()
    addon.Modules.HidePlayer:Init()
    addon.Modules.Sorting:Init()
    addon.Modules.Targeting:Init()
    addon.Modules.Macro:Init()
    addon.Modules.Inspector:Init()
    addon.Modules.UnitTracker:Init()
    addon.Modules.Nameplates:Init()

    for _, provider in ipairs(fsProviders.All) do
        provider:RegisterRequestSortCallback(OnProviderRequestedSort)
    end

    timerFrame = wow.CreateFrame("Frame")
    timerFrame:SetScript("OnUpdate", OnUpdate)

    fsInspector:RegisterCallback(OnInspectorInfo)
end
