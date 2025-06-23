---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsLuaEx = addon.Collections.LuaEx
local M = {}

fsProviders.Grid2 = M
table.insert(fsProviders.All, M)

function M:Name()
    return "Grid2"
end

function M:Enabled()
    return wow.GetAddOnEnableState(nil, "Grid2") ~= 0
end

function M:Init() end

function M:RegisterRequestSortCallback(_) end

function M:RegisterContainersChangedCallback(_) end

function M:Containers()
    ---@type FrameContainer
    local party = Grid2LayoutHeader1
        and {
            Frame = Grid2LayoutHeader1,
            Type = fsFrame.ContainerType.Party,
            LayoutType = fsFrame.LayoutType.NameList,
            ShowUnit = function(_, unitId)
                if not wow.IsInInstance() then
                    return true
                end

                local selectedLayout = fsLuaEx:SafeGet(Grid2, { "db", "profile", "raidSizeType" })
                local onlyShowUnitsInRaid = 3

                if selectedLayout ~= onlyShowUnitsInRaid then
                    return true
                end

                local instanceId = wow.C_Map.GetBestMapForUnit("player")
                local unitInstanceId = wow.C_Map.GetBestMapForUnit(unitId)

                return instanceId == unitInstanceId
            end,
        }

    return {
        party,
    }
end
