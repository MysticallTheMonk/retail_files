---@type string, Addon
local _, addon = ...
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsEnumerable = addon.Collections.Enumerable
local fsCompare = addon.Modules.Sorting.Comparer
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local events = addon.WoW.Events
local M = {}
local useEvents = false
local sortCallbacks = {}

fsProviders.GladiusEx = M
table.insert(fsProviders.All, M)

local function CalculateSpace(container)
    local frames = fsEnumerable
        :From(fsFrame:ExtractUnitFrames(container))
        :OrderBy(function(x, y)
            return fsCompare:CompareTopLeftFuzzy(x, y)
        end)
        :ToTable()

    if #frames <= 1 then
        return {
            Horizontal = 0,
            Vertical = 0,
        }
    end

    local first = frames[1]
    local second = frames[2]
    local vertical = first:GetBottom() - second:GetTop()

    return {
        Horizontal = 0,
        Vertical = vertical,
    }
end

local function RequestSort(reason)
    for _, callback in ipairs(sortCallbacks) do
        callback(M, reason)
    end
end

local function OnUpdateFrames()
    RequestSort("UpdateFrames hook")
end

function M:Name()
    return "GladiusEx"
end

function M:Enabled()
    return wowEx.IsAddOnEnabled("GladiusEx")
end

function M:RegisterRequestSortCallback(callback)
    if not callback then
        fsLog:Bug("GladiusEx:RegisterRequestSortCallback() - callback must not be nil.")
        return
    end

    sortCallbacks[#sortCallbacks + 1] = callback
end

function M:RegisterContainersChangedCallback() end

function M:ProcessEvent(event)
    if not useEvents then
        return
    end

    if event == events.ARENA_OPPONENT_UPDATE then
        RequestSort(event)
    elseif event == events.ARENA_PREP_OPPONENT_SPECIALIZATIONS then
        RequestSort(event)
    elseif event == events.GROUP_ROSTER_UPDATE then
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
        return containers
    end

    if GladiusExPartyFrame then
        ---@type FrameContainer
        local party = {
            Frame = GladiusExPartyFrame,
            Type = fsFrame.ContainerType.Party,
            LayoutType = fsFrame.LayoutType.Soft,
            Spacing = function()
                return CalculateSpace(GladiusExPartyFrame)
            end,
        }

        containers[#containers + 1] = party
    end

    if GladiusExArenaFrame then
        ---@type FrameContainer
        local arena = {
            Frame = GladiusExArenaFrame,
            Type = fsFrame.ContainerType.EnemyArena,
            LayoutType = fsFrame.LayoutType.Soft,
            Spacing = function()
                return CalculateSpace(GladiusExArenaFrame)
            end,
        }

        containers[#containers + 1] = arena
    end

    return containers
end

function M:Init()
    if not M:Enabled() then
        return
    end

    if GladiusEx and GladiusEx.UpdateFrames then
        wow.hooksecurefunc(GladiusEx, "UpdateFrames", OnUpdateFrames)
    else
        fsLog:Bug("GladiusEx:UpdateFrames is n il.")

        useEvents = true
    end
end
