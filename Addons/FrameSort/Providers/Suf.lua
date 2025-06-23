---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local M = {}

fsProviders.Suf = M
table.insert(fsProviders.All, M)

function M:Name()
    return "Shadowed Unit Frames"
end

function M:Enabled()
    return wow.GetAddOnEnableState(nil, "ShadowedUnitFrames") ~= 0
end

function M:Init() end

function M:RegisterRequestSortCallback(_) end

function M:RegisterContainersChangedCallback(_) end

function M:Containers()
    ---@type FrameContainer
    local party = SUFHeaderparty and {
        Frame = SUFHeaderparty,
        Type = fsFrame.ContainerType.Party,
        LayoutType = fsFrame.LayoutType.NameList,
    }

    ---@type FrameContainer
    local arena = SUFHeaderarena and {
        Frame = SUFHeaderarena,
        Type = fsFrame.ContainerType.EnemyArena,
        LayoutType = fsFrame.LayoutType.NameList,
    }

    return {
        party,
        arena,
    }
end
