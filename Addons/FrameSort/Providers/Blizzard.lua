---@type string, Addon
local _, addon = ...
local wow = addon.WoW.Api
local fsFrame = addon.WoW.Frame
local fsProviders = addon.Providers
local fsScheduler = addon.Scheduling.Scheduler
local events = addon.WoW.Api.Events
local fsMath = addon.Numerics.Math
---@class BlizzardFrameProvider: FrameProvider
local M = {}
local layoutEventFrame = nil
local cvarEventFrame = nil
local sortCallbacks = {}
local containersChangedCallbacks = {}
local cvarsToUpdateContainer = {
    "HorizontalGroups",
    "KeepGroupsTogether",
    -- classic when changing between raid profiles
    "activeCUFProfile",
}
local cvarsPatternsToRunSort = {
    "raidOptionDisplay.*",
    "pvpOptionDisplay.*",
    "raidFrames.*",
    "pvpFrames.*",
    "activeCUFProfile",
}
local combatStatusFrame = nil

fsProviders.Blizzard = M
table.insert(fsProviders.All, M)

local function RequestSort()
    for _, callback in ipairs(sortCallbacks) do
        callback(M)
    end
end

local function RequestUpdateContainers()
    for _, callback in ipairs(containersChangedCallbacks) do
        callback(M)
    end
end

local function OnLayoutsApplied()
    -- user or system changed their layout
    RequestUpdateContainers()
end

local function OnEditModeExited()
    -- user may have changed frame settings
    RequestUpdateContainers()
end

local function OnRaidGroupLoaded()
    -- refresh group frame offsets once a group has been loaded
    RequestUpdateContainers()
end

local function OnRaidContainerSizeChanged()
    RequestUpdateContainers()
end

local function OnCvarUpdate(_, _, name)
    for _, cvar in ipairs(cvarsToUpdateContainer) do
        if name == cvar then
            RequestUpdateContainers()
        end
    end

    for _, pattern in ipairs(cvarsPatternsToRunSort) do
        if string.match(name, pattern) then
            -- run next frame to allow cvars to take effect
            fsScheduler:RunNextFrame(RequestSort)
        end
    end
end

local function GetOffset(container)
    if container and container.title and type(container.title) == "table" and type(container.title.GetHeight) == "function" then
        return {
            X = 0,
            Y = -container.title:GetHeight(),
        }
    end

    return nil
end

local function CombatChanging(_, event)
    local toBlock = {
        -- prevent 'seen' and 'stealth' events from causing frames to reposition
        events.ARENA_OPPONENT_UPDATE,

        -- prevent frames from going haywire at the end of a shuffle round
        events.PVP_MATCH_STATE_CHANGED,
    }

    for _, ev in ipairs(toBlock) do
        if event == events.PLAYER_REGEN_DISABLED then
            wow.CompactArenaFrame:UnregisterEvent(ev)
        elseif event == events.PLAYER_REGEN_ENABLED then
            wow.CompactArenaFrame:RegisterEvent(ev)
        end
    end
end

function M:Name()
    return "Blizzard"
end

function M:Enabled()
    local containers = M:Containers()

    for _, container in ipairs(containers) do
        -- frame addons will usually disable blizzard via unsubscribing group update events
        if container.Frame:IsVisible() or container.Frame:IsEventRegistered("GROUP_ROSTER_UPDATE") then
            return true
        end
    end

    return false
end

function M:Init()
    if not M:Enabled() then
        return
    end

    if wow.IsRetail() then
        wow.EventRegistry:RegisterCallback(events.EditModeExit, OnEditModeExited)

        fsScheduler:RunWhenEnteringWorld(function()
            -- this event always fires when loading
            -- and we don't care about the first one
            -- so to avoid running modules multiple times on first load, delay the event registration
            layoutEventFrame = wow.CreateFrame("Frame")
            layoutEventFrame:HookScript("OnEvent", OnLayoutsApplied)
            layoutEventFrame:RegisterEvent(events.EDIT_MODE_LAYOUTS_UPDATED)
        end)
    end

    cvarEventFrame = wow.CreateFrame("Frame")
    cvarEventFrame:HookScript("OnEvent", OnCvarUpdate)
    cvarEventFrame:RegisterEvent(events.CVAR_UPDATE)

    if CompactRaidGroup_OnLoad then
        wow.hooksecurefunc("CompactRaidGroup_OnLoad", OnRaidGroupLoaded)
    end

    if CompactRaidFrameContainer_OnSizeChanged then
        -- classic uses the container size to determine frames per line
        wow.hooksecurefunc("CompactRaidFrameContainer_OnSizeChanged", OnRaidContainerSizeChanged)
    end

    if wow.CompactArenaFrame then
        combatStatusFrame = wow.CreateFrame("Frame")
        combatStatusFrame:RegisterEvent(events.PLAYER_REGEN_ENABLED)
        combatStatusFrame:RegisterEvent(events.PLAYER_REGEN_DISABLED)
        combatStatusFrame:HookScript("OnEvent", CombatChanging)

        wow.hooksecurefunc(wow.CompactArenaFrame, "UpdateLayout", function()
            RequestSort()
        end)
    end
end

function M:RegisterRequestSortCallback(callback)
    sortCallbacks[#sortCallbacks + 1] = callback
end

function M:RegisterContainersChangedCallback(callback)
    containersChangedCallbacks[#containersChangedCallbacks + 1] = callback
end

function M:Containers()
    ---@type FrameContainer[]
    local containers = {}

    if wow.CompactPartyFrame then
        containers[#containers + 1] = {
            Frame = wow.CompactPartyFrame,
            Type = fsFrame.ContainerType.Party,
            LayoutType = fsFrame.LayoutType.Hard,
            VisibleOnly = true,
            SupportsSpacing = true,
            InCombatSortingRequired = true,
            IsGrouped = function()
                return false
            end,
            IsHorizontalLayout = function()
                if wow.IsRetail() then
                    return wow.EditModeManagerFrame:GetSettingValueBool(
                        wow.Enum.EditModeSystem.UnitFrame,
                        wow.Enum.EditModeUnitFrameSystemIndices.Party,
                        wow.Enum.EditModeUnitFrameSetting.UseHorizontalGroups
                    )
                end

                return wow.CompactRaidFrameManager_GetSetting("HorizontalGroups")
            end,
            FramesOffset = function()
                return GetOffset(wow.CompactPartyFrame)
            end,
        }
    end

    if wow.CompactRaidFrameContainer then
        local raid = {
            Frame = wow.CompactRaidFrameContainer,
            Type = fsFrame.ContainerType.Raid,
            LayoutType = fsFrame.LayoutType.Hard,
            VisibleOnly = true,
            SupportsSpacing = true,
            InCombatSortingRequired = true,
            IsGrouped = function()
                if wow.IsRetail() then
                    local raidGroupDisplayType = wow.EditModeManagerFrame:GetSettingValue(
                        wow.Enum.EditModeSystem.UnitFrame,
                        wow.Enum.EditModeUnitFrameSystemIndices.Raid,
                        wow.Enum.EditModeUnitFrameSetting.RaidGroupDisplayType
                    )
                    return raidGroupDisplayType == wow.Enum.RaidGroupDisplayType.SeparateGroupsVertical or raidGroupDisplayType == wow.Enum.RaidGroupDisplayType.SeparateGroupsHorizontal
                end

                return wow.CompactRaidFrameManager_GetSetting("KeepGroupsTogether")
            end,
            IsHorizontalLayout = function()
                if wow.IsRetail() then
                    local displayType = wow.EditModeManagerFrame:GetSettingValue(
                        wow.Enum.EditModeSystem.UnitFrame,
                        wow.Enum.EditModeUnitFrameSystemIndices.Raid,
                        wow.Enum.EditModeUnitFrameSetting.RaidGroupDisplayType
                    )
                    return displayType == wow.Enum.RaidGroupDisplayType.SeparateGroupsHorizontal or displayType == wow.Enum.RaidGroupDisplayType.CombineGroupsHorizontal
                end

                return wow.CompactRaidFrameManager_GetSetting("HorizontalGroups")
            end,
            FramesOffset = function()
                return GetOffset(wow.CompactRaidFrameContainer)
            end,
            GroupFramesOffset = function()
                local groups = fsFrame:ExtractGroups(wow.CompactRaidFrameContainer)

                if #groups == 0 then
                    return nil
                end

                return GetOffset(groups[1])
            end,
        }

        raid.FramesPerLine = function()
            if wow.CompactRaidFrameContainer.flowMaxPerLine then
                return wow.CompactRaidFrameContainer.flowMaxPerLine
            end

            local horizontal = raid:IsHorizontalLayout()
            local lineSize = nil

            if wow.IsRetail() then
                lineSize = horizontal and wow.CompactRaidFrameContainer:GetWidth() or wow.CompactRaidFrameContainer:GetHeight()
            else
                -- cata has an annoying taint issue that we have to workaround
                -- where calling GetWidth() or GetHeight() on CompactRaidFrameContainer taints raid frames
                -- see https://github.com/Stanzilla/WoWUIBugs/issues/596 and https://github.com/Verubato/framesort/issues/38
                local taintWorkaround = wow.CreateFrame("Frame", nil, wow.UIParent, "SecureHandlerStateTemplate")

                function taintWorkaround:Configure(width, height)
                    lineSize = horizontal and width or height
                end

                wow.SecureHandlerSetFrameRef(taintWorkaround, "Target", wow.CompactRaidFrameContainer)
                wow.SecureHandlerExecute(
                    taintWorkaround,
                    [[
                        local run = control or self
                        local target = self:GetFrameRef("Target")
                        local width = target:GetWidth()
                        local height = target:GetHeight()

                        run:CallMethod("Configure", width, height)
                    ]]
                )
            end

            local frameSize = nil
            local o = DefaultCompactUnitFrameSetupOptions
            local f1 = CompactRaidFrame1

            if o then
                -- classic and sod
                frameSize = horizontal and o.width or o.height
            elseif f1 then
                frameSize = tonumber(horizontal and f1:GetWidth() or f1:GetHeight())
            end

            if lineSize and frameSize then
                -- round to nearest
                local framesPerLine = fsMath:Round(lineSize / frameSize)
                -- be at least 1
                framesPerLine = math.max(framesPerLine, 1)
                return framesPerLine
            end

            -- default to 5 if we for some reason we can't calculate it
            return 5
        end

        containers[#containers + 1] = raid
    end

    if wow.CompactArenaFrame then
        containers[#containers + 1] = {
            Frame = wow.CompactArenaFrame,
            Type = fsFrame.ContainerType.EnemyArena,
            LayoutType = fsFrame.LayoutType.Hard,
            VisibleOnly = false,
            SupportsSpacing = true,
            InCombatSortingRequired = true,
            AnchorPoint = "TOPRIGHT",
            SubscribeToVisibility = true,
            FramesOffset = function()
                return {
                    X = -(wow.CompactArenaFrameMember1 and (wow.CompactArenaFrameMember1.CcRemoverFrame:GetWidth() + 2) or 29),
                    Y = -(wow.CompactArenaFrameTitle and wow.CompactArenaFrameTitle:GetHeight() or 14),
                }
            end,
            PostSort = function()
                -- this is anchored to CompactArenaFrameMember1 by default which can move around
                -- so just hide the title
                wow.CompactArenaFrameTitle:Hide()
            end,
        }
    end

    return containers
end
