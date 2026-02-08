---@type string, Addon
local _, addon = ...
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsLuaEx = addon.Language.LuaEx
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local events = addon.WoW.Events
local M = {}
local useEvents = false
local sortCallbacks = {}

fsProviders.Grid2 = M
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
    return "Grid2"
end

function M:Enabled()
    return wowEx.IsAddOnEnabled("Grid2")
end

function M:RegisterRequestSortCallback(callback)
    if not callback then
        fsLog:Bug("Grid2:RegisterRequestSortCallback() - callback must not be nil.")
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
        return containers
    end

    if Grid2LayoutHeader1 then
        ---@type FrameContainer
        local party = {
            Frame = Grid2LayoutHeader1,
            Type = fsFrame.ContainerType.Party,
            LayoutType = fsFrame.LayoutType.NameList,
            ShowUnit = function(_, unitId)
                local inInstance, instanceType = wowEx.IsInInstance()

                if not inInstance then
                    return true
                end

                if instanceType ~= "raid" then
                    -- ignore dungeons as the map/zone can change quite a lot inside and we'd end up hiding players
                    return true
                end

                local selectedLayout = fsLuaEx:SafeGet(Grid2, { "db", "profile", "raidSizeType" })
                local onlyShowUnitsInRaid = 3

                if selectedLayout ~= onlyShowUnitsInRaid then
                    return true
                end

                local mythicRaidDifficulty = 16
                local _, _, difficultyId = wow.GetInstanceInfo()

                if difficultyId ~= mythicRaidDifficulty then
                    return true
                end

                local unitIndex = string.match(unitId, "%d+")
                local _, _, subgroup = wow.GetRaidRosterInfo(unitIndex)
                local include = subgroup >= 1 and subgroup <= 4

                return include
            end,
        }

        containers[#containers + 1] = party
    end

    return containers
end

function M:Init()
    if not M:Enabled() then
        return
    end

    local canHook = true

    if not Grid2Layout then
        fsLog:Bug("Grid2Layout is nil.")
        canHook = false
    end

    if Grid2Layout and not Grid2Layout.LoadLayout then
        fsLog:Bug("Grid2Layout:LoadLayout is nil.")
        canHook = false
    end

    if canHook then
        wow.hooksecurefunc(Grid2Layout, "LoadLayout", function()
            if Grid2LayoutHeader1 then
                Grid2LayoutHeader1:HookScript("OnEvent", OnEvent)
            else
                fsLog:Bug("Grid2LayoutHeader1 is nil.")
            end
        end)
    else
        useEvents = true
    end
end
