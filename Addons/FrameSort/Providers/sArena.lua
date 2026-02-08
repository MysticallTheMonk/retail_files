---@type string, Addon
local _, addon = ...
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsLuaEx = addon.Language.LuaEx
local fsLog = addon.Logging.Log
local events = addon.WoW.Events
local M = {}
local sortCallbacks = {}

fsProviders.sArena = M
table.insert(fsProviders.All, M)

local function RequestSort(reason)
    for _, callback in ipairs(sortCallbacks) do
        callback(M, reason)
    end
end

function M:Name()
    return "sArena"
end

function M:Enabled()
    -- there are a few of variants of sArena
    -- e.g. "sArena Updated" and "sArena_Updated2_by_sammers"
    -- so instead of checking for enabled state just check if the container exists
    return type(sArena) == "table"
end

function M:RegisterRequestSortCallback(callback)
    if not callback then
        fsLog:Bug("sArena:RegisterRequestSortCallback() - callback must not be nil.")
        return
    end

    sortCallbacks[#sortCallbacks + 1] = callback
end

function M:RegisterContainersChangedCallback() end

function M:ProcessEvent(event)
    if not M:Enabled() then
        return
    end

    if event == events.ARENA_OPPONENT_UPDATE then
        RequestSort(event)
    elseif event == events.ARENA_PREP_OPPONENT_SPECIALIZATIONS then
        RequestSort(event)
    end
end

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
                Vertical = vertical,
            }
        end,
    }

    return {
        arena,
    }
end

function M:Init() end
