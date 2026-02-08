---@type string, Addon
local _, addon = ...
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsLuaEx = addon.Language.LuaEx
local fsEnumerable = addon.Collections.Enumerable
local fsLog = addon.Logging.Log
local wow = addon.WoW.Api
local wowEx = addon.WoW.WowEx
local events = addon.WoW.Events
local M = {}
local useEvents = false
local sortCallbacks = {}

fsProviders.Gladdy = M
table.insert(fsProviders.All, M)

local function RequestSort(reason)
    for _, callback in ipairs(sortCallbacks) do
        callback(M, reason)
    end
end

local function OnUpdateFrame()
    RequestSort("UpdateFrame hook")
end

function M:Name()
    return "Gladdy"
end

function M:Enabled()
    return wowEx.IsAddOnEnabled("Gladdy")
end

function M:RegisterRequestSortCallback(callback)
    if not callback then
        fsLog:Bug("Gladdy:RegisterRequestSortCallback() - callback must not be nil.")
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

    local function getFrames()
        local inInstance, instanceType = wowEx.IsInInstance()
        local isArena = inInstance and instanceType == "arena"
        local frames = {
            ---@diagnostic disable: undefined-global
            GladdyButtonFrame1,
            GladdyButtonFrame2,
            GladdyButtonFrame3,
            GladdyButtonFrame4,
            GladdyButtonFrame5,
        }

        local count = isArena and wowEx.ArenaOpponentsCount() or #frames
        return fsEnumerable:From(frames):Take(count):ToTable()
    end

    local charKey = wow.UnitName("player") .. " - " .. wow.GetRealmName()
    local profileKey = fsLuaEx:SafeGet(GladdyXZ, { "profileKeys", charKey })
    local profile = fsLuaEx:SafeGet(GladdyXZ, { "profiles", profileKey })

    if GladdyFrame then
        ---@type FrameContainer
        local arena = {
            Frame = GladdyFrame,
            Type = fsFrame.ContainerType.EnemyArena,
            LayoutType = fsFrame.LayoutType.Hard,
            Frames = getFrames,
            Spacing = function()
                local margin = fsLuaEx:SafeGet(profile, { "bottomMargin" }) or 95
                local highlightBorderSize = fsLuaEx:SafeGet(profile, { "highlightInset" }) and 0 or fsLuaEx:SafeGet(profile, { "highlightBorderSize" }) * 2
                local powerBarHeight = fsLuaEx:SafeGet(profile, { "powerBarEnabled" }) and (fsLuaEx:SafeGet(profile, { "powerBarHeight" }) + 1) or 0

                return {
                    Horizontal = 0,
                    Vertical = margin + highlightBorderSize + powerBarHeight,
                }
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

    local gladdy = LibStub and LibStub:GetLibrary("Gladdy", true)

    if gladdy and gladdy.UpdateFrame then
        wow.hooksecurefunc(gladdy, "UpdateFrame", OnUpdateFrame)
    else
        fsLog:Bug("Gladdy:UpdateFrame is nil.")

        useEvents = true
    end
end
