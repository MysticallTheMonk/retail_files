---@type string, Addon
local _, addon = ...
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsLuaEx = addon.Collections.LuaEx
local M = {}

fsProviders.sArena = M
table.insert(fsProviders.All, M)

function M:Name()
    return "sArena"
end

function M:Enabled()
    -- there are a few of variants of sArena
    -- e.g. "sArena Updated" and "sArena_Updated2_by_sammers"
    -- so instead of checking for enabled state just check if the container exists
    return sArena ~= nil and type(sArena) == "table"
end

function M:Init() end

function M:RegisterRequestSortCallback(_) end

function M:RegisterContainersChangedCallback(_) end

function M:Containers()
    if not M:Enabled() then
        return {}
    end

    ---@type FrameContainer
    local arena = {
        Frame = sArena,
        Type = fsFrame.ContainerType.EnemyArena,
        LayoutType = fsFrame.LayoutType.Hard,
        AnchorPoint = "CENTER",
        Spacing = function()
            local layout = fsLuaEx:SafeGet(sArena, { "db", "profile", "currentLayout" }) or "BlizzArena"
            local vertical = fsLuaEx:SafeGet(sArena, { "db", "profile", "layoutSettings", layout, "spacing" }) or 20

            return {
                Horizontal = 0,
                Vertical = vertical
            }
        end
    }

    return {
        arena,
    }
end
