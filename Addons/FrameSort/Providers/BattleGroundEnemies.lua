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

fsProviders.BattleGroundEnemies = M
table.insert(fsProviders.All, M)

local function RequestSort(reason)
    for _, callback in ipairs(sortCallbacks) do
        callback(M, reason)
    end
end

local function OnUpdateArenaPlayers()
    local target = BattleGroundEnemies and BattleGroundEnemies.Enemies

    if not target or not target.IsVisible or not target:IsVisible() then
        return
    end

    RequestSort("UpdateArenaPlayers hook")
end

local function OnGroupRosterUpdate()
    local target = BattleGroundEnemies and BattleGroundEnemies.Allies

    if not target or not target.IsVisible or not target:IsVisible() then
        return
    end

    RequestSort("GROUP_ROSTER_UPDATE hook")
end

function M:Name()
    return "BattleGroundEnemies"
end

function M:Enabled()
    return wowEx.IsAddOnEnabled("BattleGroundEnemies")
end

function M:RegisterRequestSortCallback(callback)
    if not callback then
        fsLog:Bug("BattleGroundEnemies:RegisterRequestSortCallback() - callback must not be nil.")
        return
    end

    sortCallbacks[#sortCallbacks + 1] = callback
end

function M:RegisterContainersChangedCallback() end

function M:Containers()
    local containers = {}

    if not M:Enabled() then
        return containers
    end

    if not BattleGroundEnemies then
        return containers
    end

    local arenaFrame = BattleGroundEnemies.Enemies
    local allyFrame = BattleGroundEnemies.Allies
    local charKey = wow.UnitName("player") .. " - " .. wow.GetRealmName()
    local profileKey = fsLuaEx:SafeGet(BattleGroundEnemiesDB, { "profileKeys", charKey })
    local profile = fsLuaEx:SafeGet(BattleGroundEnemiesDB, { "profiles", profileKey })

    if allyFrame then
        local configs = fsLuaEx:SafeGet(profile, { "Allies", "playerCountConfigs" })
        local arenaConfig = configs and configs[1]
        local verticalSpacing = arenaConfig and arenaConfig.BarVerticalSpacing

        containers[#containers + 1] = {
            Frame = allyFrame,
            Type = fsFrame.ContainerType.Party,
            LayoutType = fsFrame.LayoutType.Hard,
            AnchorPoint = "TOPLEFT",
            Spacing = function()
                return {
                    Horizontal = 0,
                    Vertical = verticalSpacing or 40,
                }
            end,
            EnableInBattlegrounds = false,
        }
    end

    if arenaFrame then
        local configs = fsLuaEx:SafeGet(profile, { "Enemies", "playerCountConfigs" })
        local arenaConfig = configs and configs[1]
        local verticalSpacing = arenaConfig and arenaConfig.BarVerticalSpacing

        containers[#containers + 1] = {
            Frame = arenaFrame,
            Type = fsFrame.ContainerType.EnemyArena,
            LayoutType = fsFrame.LayoutType.Hard,
            AnchorPoint = "TOPLEFT",
            Spacing = function()
                return {
                    Horizontal = 0,
                    Vertical = verticalSpacing or 40,
                }
            end,
            EnableInBattlegrounds = false,
        }
    end

    return containers
end

function M:ProcessEvent(event, ...)
    if not useEvents then
        return
    end

    if event == events.GROUP_ROSTER_UPDATE then
        RequestSort(event)
    elseif event == events.ARENA_OPPONENT_UPDATE then
        RequestSort(event)
    elseif event == events.ARENA_PREP_OPPONENT_SPECIALIZATIONS then
        RequestSort(event)
    end
end

function M:Init()
    if not M:Enabled() then
        return
    end

    if BattleGroundEnemies and BattleGroundEnemies.UpdateArenaPlayers then
        wow.hooksecurefunc(BattleGroundEnemies, "UpdateArenaPlayers", OnUpdateArenaPlayers)
    else
        fsLog:Bug("BattleGroundEnemies:UpdateArenaPlayers is nil.")

        useEvents = true
    end

    if BattleGroundEnemies and BattleGroundEnemies.GROUP_ROSTER_UPDATE then
        wow.hooksecurefunc(BattleGroundEnemies, "GROUP_ROSTER_UPDATE", OnGroupRosterUpdate)
    else
        fsLog:Bug("BattleGroundEnemies:GROUP_ROSTER_UPDATE is nil.")

        useEvents = true
    end
end
