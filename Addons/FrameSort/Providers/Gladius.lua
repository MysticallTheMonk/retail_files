---@type string, Addon
local _, addon = ...
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsCompare = addon.Modules.Sorting.Comparer
local fsLuaEx = addon.Language.LuaEx
local fsEnumerable = addon.Collections.Enumerable
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local events = addon.WoW.Events
local M = {}
local useEvents = false
local sortCallbacks = {}

fsProviders.Gladius = M
table.insert(fsProviders.All, M)

local function RequestSort(reason)
    for _, callback in ipairs(sortCallbacks) do
        callback(M, reason)
    end
end

local function OnUpdateUnit()
    RequestSort("UpdateUnit hook")
end

function M:Name()
    return "Gladius"
end

function M:Enabled()
    return wowEx.IsAddOnEnabled("Gladius")
end

function M:RegisterRequestSortCallback(callback)
    if not callback then
        fsLog:Bug("Gladius:RegisterRequestSortCallback() - callback must not be nil.")
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
    end
end

function M:Containers()
    local containers = {}

    if not M:Enabled() then
        return containers
    end

    if not Gladius then
        return
    end

    local function getFrames()
        -- in test mode, get the number of frames shown
        local isTest = fsLuaEx:SafeGet(Gladius, { "test" })
        local testCount = fsLuaEx:SafeGet(Gladius, { "testCount" })
        local count = isTest and testCount or wowEx.ArenaOpponentsCount()

        return fsEnumerable
            :From({
                ---@diagnostic disable: undefined-global
                GladiusButtonFramearena1,
                GladiusButtonFramearena2,
                GladiusButtonFramearena3,
                GladiusButtonFramearena4,
                GladiusButtonFramearena5,
            })
            :Take(count)
            :ToTable()
    end

    local charKey = wow.UnitName("player") .. " - " .. wow.GetRealmName()
    local profileKey = fsLuaEx:SafeGet(Gladius2DB, { "profileKeys", charKey })
    local profile = fsLuaEx:SafeGet(Gladius2DB, { "profiles", profileKey })

    ---@type FrameContainer
    local arena = {
        Frame = wow.UIParent,
        Type = fsFrame.ContainerType.EnemyArena,
        LayoutType = fsFrame.LayoutType.Hard,
        AnchorPoint = "BOTTOMLEFT",
        VisibleOnly = false,
        Frames = getFrames,
        FramesOffset = function()
            local arena1 = fsLuaEx:SafeGet(Gladius, { "buttons", "arena1" })

            -- refer to Gladius.lua:581
            local scale = arena1 and arena1:GetEffectiveScale() or 1
            local x = (fsLuaEx:SafeGet(Gladius, { "db", "x", "arena1" }) or 0) / scale
            local y = (fsLuaEx:SafeGet(Gladius, { "db", "y", "arena1" }) or 0) / scale

            y = y - (arena1 and arena1:GetHeight())

            return { X = x, Y = y }
        end,
        Spacing = function()
            return {
                Horizontal = 0,
                Vertical = fsLuaEx:SafeGet(profile, { "bottomMargin" }) or 20,
            }
        end,
        PostSort = function()
            if not GladiusButtonBackground then
                return
            end

            local frames = getFrames()

            if #frames == 0 then
                return
            end

            table.sort(frames, function(x, y)
                return fsCompare:CompareTopLeftFuzzy(x, y)
            end)

            local topFrame = frames[1]
            local left, _ = topFrame:GetHitRectInsets()

            -- refer to Gladius.lua:632
            local padding = fsLuaEx:SafeGet(Gladius, { "db", "backgroundPadding" }) or 0
            GladiusButtonBackground:SetPoint("TOPLEFT", topFrame, -padding + left, padding)
        end,
    }

    containers[#containers + 1] = arena

    return containers
end

function M:Init()
    if not M:Enabled() then
        return
    end

    if not Gladius then
        return
    end

    if Gladius.UpdateUnit then
        wow.hooksecurefunc(Gladius, "UpdateUnit", OnUpdateUnit)
    else
        fsLog:Bug("Gladius:UpdateUnit is nil.")

        useEvents = true
    end
end
