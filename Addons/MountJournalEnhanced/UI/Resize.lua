local ADDON_NAME, ADDON = ...

function ADDON.UI:RestoreWindowSize()
    ADDON.settings.ui.windowSize = { 0, 0 }
    if not InCombatLockdown() then
        ADDON.UI:RestoreSize(CollectionsJournal)
    end
end

local function SetJournalSize()
    if not InCombatLockdown() then
        if CollectionsJournal:IsShown() and CollectionsJournal.selectedTab == COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS then
            local setting = ADDON.settings.ui.windowSize
            if setting[1] > 0 and setting[2] > 0 then
                CollectionsJournal:SetSize(setting[1], setting[2])
            end
        else
            ADDON.UI:RestoreSize(CollectionsJournal)
        end
    end
end

local function BuildResizeButton()
    local button = CreateFrame("Button", nil, MountJournal)
    button:SetSize(20, 20)
    button:SetPoint("BOTTOMRIGHT")
    button:SetNormalTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up')
    button:SetHighlightTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight')
    button:SetPushedTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down')
    button:SetDontSavePosition(true)

    local ticker
    button:SetScript("OnMouseDown", function()
        --CollectionsJournal:StartSizing("BOTTOMRIGHT") -- doesn't work since 9.1.5
        local lastX, lastY = GetCursorPosition()
        ticker = C_Timer.NewTicker(0.05, function()
            local currentX, currentY = GetCursorPosition()
            local w, h = CollectionsJournal:GetSize()
            local scale = CollectionsJournal:GetEffectiveScale()
            local minW, minH = CollectionsJournal:GetResizeBounds()
            CollectionsJournal:SetSize(
                    max(w - ((lastX - currentX) / scale), minW),
                    max(h + ((lastY - currentY) / scale), minH)
            )
            lastX = currentX
            lastY = currentY
        end)
    end)
    button:SetScript("OnMouseUp", function()
        --CollectionsJournal:StopMovingOrSizing()
        if ticker then
            ticker:Cancel()
        end
    end)

    return button
end

local function init()
    local CJ = CollectionsJournal

    ADDON.UI:SaveSize(CJ)
    CJ:SetResizeBounds(CJ:GetWidth(), CJ:GetHeight())
    CJ:SetClampedToScreen(true)

    CJ:HookScript("OnSizeChanged", function(_, width, height)
        if CJ:IsResizable() and CJ.selectedTab == COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS then
            ADDON.settings.ui.windowSize = { width, height }
        end
    end)
end

local button
ADDON:RegisterUISetting("showResizeEdge", true, ADDON.L["SETTING_SHOW_RESIZE_EDGE"], function(value)
    if ADDON.initialized then
        if value and not button then
            button = BuildResizeButton()
            hooksecurefunc(CollectionsJournal, "SetResizable", function(_, activate)
                button:SetShown(activate)
            end)
        end
        CollectionsJournal:SetResizable(value)
    end
end)

local loaded = false
ADDON.Events:RegisterCallback("loadUI", function()
    init()
    SetJournalSize()
    ADDON:ApplySetting('showResizeEdge', ADDON.settings.ui.showResizeEdge)
    loaded = true
end, "Resize")

EventRegistry:RegisterCallback("MountJournal.OnShow", function()
    if loaded then
        SetJournalSize()
        CollectionsJournal:SetResizable(ADDON.settings.ui.showResizeEdge and CollectionsJournal.selectedTab == COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS)
    end
end, ADDON_NAME .. '_Resize')
EventRegistry:RegisterCallback("MountJournal.OnHide", function()
    SetJournalSize()
    CollectionsJournal:SetResizable(false)
end, ADDON_NAME .. '_Resize')

ADDON.Events:RegisterFrameEventAndCallback("PLAYER_REGEN_DISABLED", function()
    if CollectionsJournal then
        CollectionsJournal:SetResizable(false)
    end
end, ADDON_NAME .. '_Resize')
ADDON.Events:RegisterFrameEventAndCallback("PLAYER_REGEN_ENABLED", function()
    if loaded then
        SetJournalSize()
        CollectionsJournal:SetResizable(ADDON.settings.ui.showResizeEdge and CollectionsJournal.selectedTab == COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS)
    end
end, ADDON_NAME .. '_Resize')