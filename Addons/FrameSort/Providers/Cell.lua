---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsLuaEx = addon.Collections.LuaEx
local M = {}

fsProviders.Cell = M
table.insert(fsProviders.All, M)

function M:Name()
    return "Cell"
end

function M:Enabled()
    return wow.GetAddOnEnableState(nil, "Cell") ~= 0 and Cell ~= nil
end

function M:Init() end

function M:RegisterRequestSortCallback(_) end

function M:RegisterContainersChangedCallback(_) end

function M:Containers()
    ---@type FrameContainer
    local party = CellPartyFrameHeader and {
        Frame = CellPartyFrameHeader,
        Type = fsFrame.ContainerType.Party,
        LayoutType = fsFrame.LayoutType.NameList,
    }

    ---@type FrameContainer
    local raid = CellRaidFrameHeader0
        and {
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

    return {
        party,
        raid,
    }
end
