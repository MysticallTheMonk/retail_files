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

fsProviders.Cell = M
table.insert(fsProviders.All, M)

local function RequestSort(reason)
    for _, callback in ipairs(sortCallbacks) do
        callback(M, reason)
    end
end

local function OnHook(_, event)
    RequestSort(event)
end

function M:Name()
    return "Cell"
end

function M:Enabled()
    return wowEx.IsAddOnEnabled("Cell")
end

function M:RegisterRequestSortCallback(callback)
    if not callback then
        fsLog:Bug("Cell:RegisterRequestSortCallback() - callback must not be nil.")
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

    if CellPartyFrameHeader then
        ---@type FrameContainer
        local party = {
            Frame = CellPartyFrameHeader,
            Type = fsFrame.ContainerType.Party,
            LayoutType = fsFrame.LayoutType.NameList,
        }

        containers[#containers + 1] = party
    end

    if CellRaidFrameHeader0 then
        ---@type FrameContainer
        local raid = {
            Frame = CellRaidFrameHeader0,
            Type = fsFrame.ContainerType.Raid,
            LayoutType = fsFrame.LayoutType.NameList,
            ShowUnit = function(_, unitId)
                local selectedLayout = fsLuaEx:SafeGet(Cell, { "vars", "currentLayout" }) or "default"
                local groupSettings = fsLuaEx:SafeGet(CellDB, { "layouts", selectedLayout, "groupFilter" })
                local anyHidden = false

                if not groupSettings then
                    return true
                end

                -- check if any groups should be hidden
                for _, value in ipairs(groupSettings) do
                    anyHidden = anyHidden or not value

                    if anyHidden then
                        break
                    end
                end

                if not anyHidden then
                    return true
                end

                local unitGroup = nil
                for i = 1, wow.MAX_RAID_MEMBERS do
                    local name, _, subgroup, _ = wow.GetRaidRosterInfo(i)

                    if name == wow.GetUnitName(unitId, true) then
                        unitGroup = subgroup
                        break
                    end
                end

                if not unitGroup then
                    return true
                end

                return groupSettings[unitGroup]
            end,
        }

        containers[#containers + 1] = raid
    end

    return containers
end

function M:Init()
    if not M:Enabled() then
        return
    end

    if CellPartyFrameHeader then
        CellPartyFrameHeader:HookScript("OnEvent", OnHook)
    else
        fsLog:Bug("CellPartyFrameHeader is nil.")

        useEvents = true
    end

    -- no need to hook CellRaidFrameHeader0 as it would just double up on the sort trigger
    -- it can't hurt, but just introduces log noise
end
