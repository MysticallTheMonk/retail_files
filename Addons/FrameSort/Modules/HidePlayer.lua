---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsCompare = addon.Collections.Comparer
local fsConfig = addon.Configuration
local fsProviders = addon.Providers
local fsFrame = addon.WoW.Frame
local fsEnumerable = addon.Collections.Enumerable
---@class HidePlayerModule: IInitialise
local M = {}
addon.Modules.HidePlayer = M

local function ShowHide(show)
    local blizzard = fsProviders.Blizzard
    local party = fsFrame:GetFrames(blizzard, fsFrame.ContainerType.Party, false)
    local raid = fsFrame:GetFrames(blizzard, fsFrame.ContainerType.Raid, false)
    local all = fsEnumerable:From(party):Concat(raid):ToTable()

    -- we need to update all frames as units are not fixed to a frame
    -- so the player unit may have moved from frame1 to frame3 for example
    for _, frame in ipairs(all) do
        local unit = assert(fsFrame:GetFrameUnit(frame))

        if show and wow.UnitExists(unit) and not frame:IsVisible() then
            -- the frame may have moved to a different unit or the user wants the player raid frame to be shown again
            wow.RegisterUnitWatch(frame)
            frame:Show()
        elseif not show and wow.UnitIsUnit(unit, "player") then
            -- user has opted to hide the player unit frame
            wow.UnregisterUnitWatch(frame)
            frame:Hide()
        end
    end
end

function M:Run()
    assert(not wow.InCombatLockdown())

    local blizzard = fsProviders.Blizzard
    local enabled, mode, _, _ = fsCompare:FriendlySortMode()

    if not enabled or not blizzard:Enabled() then
        return
    end

    local show = mode ~= fsConfig.PlayerSortMode.Hidden
    ShowHide(show)
end

function M:Init() end
