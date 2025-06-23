---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsEnumerable = addon.Collections.Enumerable
local fsCompare = addon.Collections.Comparer
local fsLuaEx = addon.Collections.LuaEx
local M = {}

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

function M:Name()
    return "GladiusEx"
end

function M:Enabled()
    return wow.GetAddOnEnableState(nil, "GladiusEx") ~= 0
end

function M:Init() end

function M:RegisterRequestSortCallback(_) end

function M:RegisterContainersChangedCallback(_) end

function M:Containers()
    ---@type FrameContainer[]
    local containers = {}

    if GladiusExPartyFrame and GladiusExButtonAnchorparty then
        containers[#containers + 1] = {
            Frame = GladiusExPartyFrame,
            Type = fsFrame.ContainerType.Party,
            LayoutType = fsFrame.LayoutType.Soft,
            Spacing = function() return CalculateSpace(GladiusExPartyFrame) end,
        }
    end

    if GladiusExArenaFrame and GladiusExButtonAnchorarena then
        containers[#containers + 1] = {
            Frame = GladiusExArenaFrame,
            Type = fsFrame.ContainerType.EnemyArena,
            LayoutType = fsFrame.LayoutType.Soft,
            Spacing = function() return CalculateSpace(GladiusExArenaFrame) end,
        }
    end

    return containers
end
