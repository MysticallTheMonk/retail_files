local ADDON_NAME, ADDON = ...

local HANDLE_NAME = ADDON_NAME..'-follow-target'

local function stopWatchingTarget()
    ADDON.Events:UnregisterCallback("OnMountUpTarget", HANDLE_NAME)
    ADDON.Events:UnregisterCallback("CastMountTarget", HANDLE_NAME)
end

local function toggleWatcher()
    if ADDON.settings.ui.syncTarget then
        ADDON.Events:RegisterCallback("OnMountUpTarget", function(_, mountId)
            ADDON.Api:SetSelected(mountId)
        end, HANDLE_NAME)
        ADDON.Events:RegisterCallback("CastMountTarget", function(_, mountId)
            ADDON.Api:SetSelected(mountId)
        end, HANDLE_NAME)

        local currentMount = ADDON:ScanAuras("target")
        if currentMount then
            ADDON.Api:SetSelected(currentMount)
        end
    else
        stopWatchingTarget()
    end
end

local function UpdateTexture(button)
    button.texture:SetDesaturated(not ADDON.settings.ui.syncTarget)
end

local function BuildToggle()
    local L = ADDON.L

    local button = CreateFrame("Button", nil, MountJournal)

    -- from DynamicFlightFlyoutButtonTemplate
    button:SetSize(30, 30)
    button.NormalTexture = button:CreateTexture()
    button.NormalTexture:SetAtlas("UI-HUD-ActionBar-IconFrame")
    button.NormalTexture:SetSize(31, 31)
    button:SetNormalTexture(button.NormalTexture)
    button.PushedTexture = button:CreateTexture()
    button.PushedTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Down")
    button.PushedTexture:SetSize(31, 31)
    button:SetPushedTexture(button.PushedTexture)
    button.HighlightTexture = button:CreateTexture()
    button.HighlightTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")
    button.HighlightTexture:SetSize(31, 31)
    button:SetHighlightTexture(button.HighlightTexture)

    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetAllPoints()
    button.texture:SetTexture(132177) -- ability_hunter_mastermarksman
    UpdateTexture(button)

    if ElvUI then
        local E = unpack(ElvUI)
        local ElvSkin = E:GetModule('Skins')

        -- from Collectables.lua HandleDynamicFlightButton
        button:SetPushedTexture(0)
        button:GetHighlightTexture():SetColorTexture(1, 1, 1, .25)
        button:SetNormalTexture(0)

        ElvSkin:HandleIcon(button.texture)
    end

    button:HookScript("OnClick", function()
        ADDON.settings.ui.syncTarget = not ADDON.settings.ui.syncTarget
        UpdateTexture(button)
        toggleWatcher()
    end)
    button:HookScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip_SetTitle(GameTooltip, L.SYNC_TARGET_TIP_TITLE)
        GameTooltip_AddNormalLine(GameTooltip, L.SYNC_TARGET_TIP_TEXT, true)
        GameTooltip_AddInstructionLine(GameTooltip, L.SYNC_TARGET_TIP_FLAVOR, true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetAttribute("MJE_ToolbarIndex", "SyncTarget")

    return button
end

ADDON.Events:RegisterCallback("loadUI", function()
    ADDON.UI:RegisterToolbarGroup("08-follow-target", BuildToggle())
end, HANDLE_NAME)

EventRegistry:RegisterCallback("MountJournal.OnShow", toggleWatcher, HANDLE_NAME)
EventRegistry:RegisterCallback("MountJournal.OnHide", stopWatchingTarget, HANDLE_NAME)