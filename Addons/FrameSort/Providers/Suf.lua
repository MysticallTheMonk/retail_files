---@type string, Addon
local _, addon = ...
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local events = addon.WoW.Events
local M = {}
local sortCallbacks = {}
local useEvents = false

fsProviders.Suf = M
table.insert(fsProviders.All, M)

local function RequestSort(reason)
    for _, callback in ipairs(sortCallbacks) do
        callback(M, reason)
    end
end

local function OnEvent(_, event)
    RequestSort(event)
end

function M:Name()
    return "Shadowed Unit Frames"
end

function M:Enabled()
    return wowEx.IsAddOnEnabled("ShadowedUnitFrames")
end

function M:RegisterRequestSortCallback(callback)
    if not callback then
        fsLog:Bug("SUF:RegisterRequestSortCallback() - callback must not be nil.")
        return
    end

    sortCallbacks[#sortCallbacks + 1] = callback
end

function M:RegisterContainersChangedCallback() end

function M:ProcessEvent(event)
    if not useEvents then
        return
    end

    if event == events.GROUP_ROSTER_UPDATE then
        RequestSort(event)
    elseif event == events.PLAYER_ROLES_ASSIGNED then
        RequestSort(event)
    elseif event == events.PLAYER_SPECIALIZATION_CHANGED then
        RequestSort(event)
    elseif event == events.UNIT_PET then
        RequestSort(event)
    end
end

function M:Containers()
    local containers = {}

    if not M:Enabled() then
        return
    end

    if SUFHeaderparty then
        ---@type FrameContainer
        local party = {
            Frame = SUFHeaderparty,
            Type = fsFrame.ContainerType.Party,
            LayoutType = fsFrame.LayoutType.NameList,
        }

        containers[#containers + 1] = party
    end

    if SUFHeaderarena then
        ---@type FrameContainer
        local arena = {
            Frame = SUFHeaderarena,
            Type = fsFrame.ContainerType.EnemyArena,
            LayoutType = fsFrame.LayoutType.NameList,
        }

        containers[#containers + 1] = arena
    end

    return containers
end

function M:Init()
    if not M:Enabled() then
        return
    end

    local canHook = true

    if not ShadowUF then
        fsLog:Bug("ShadowUF is nil.")
        canHook = false
    end

    if ShadowUF and not ShadowUF.OnInitialize then
        fsLog:Bug("ShadowUF:OnInitialize is nil.")
        canHook = false
    end

    if canHook then
        wow.hooksecurefunc(ShadowUF, "OnInitialize", function()
            -- user may have disabled party/arena frames, so don't log if they are missing
            -- suf also doesn't load arena header unless inside arena
            if SUFHeaderparty then
                SUFHeaderparty:HookScript("OnEvent", OnEvent)
            end

            if SUFHeaderarena then
                SUFHeaderarena:HookScript("OnEvent", OnEvent)
            end

            if not SUFHeaderparty and not SUFHeaderarena then
                useEvents = true
            end
        end)
    else
        useEvents = true
    end
end
