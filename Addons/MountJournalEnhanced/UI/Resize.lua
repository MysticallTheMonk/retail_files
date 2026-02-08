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
    local button = CreateFrame("Button", nil, MountJournal, "PanelResizeButtonTemplate")
    button:SetScript("OnEnter", nil) -- revert cursor icon
    button:SetPoint("BOTTOMRIGHT", -3, 3)
    button:SetDontSavePosition(true)

    button:SetScript("OnMouseDown", function()
        CollectionsJournal:StartSizing("BOTTOMRIGHT")
    end)
    button:SetScript("OnMouseUp", function()
        CollectionsJournal:StopMovingOrSizing()
    end)

    return button
end

local function init()
    local CJ = CollectionsJournal

    ADDON.UI:SaveSize(CJ)
    CJ:SetResizeBounds(CJ:GetWidth(), CJ:GetHeight())
    if not InCombatLockdown() then
        CJ:SetClampedToScreen(true)
    end

    -- Right Point is originally tied to WardrobeCollectionFrame.ItemsCollectionFrame.PagingFrame.
    -- That breaks/prevents resizing of the WardrobeCollection and therefore the whole CollectionsJournal.
    -- see TransmogFrameMixin:OnLoad()
    -- (since 9.1.5)
    -- TODO: remove after 12.0 launch
    if WardrobeTransmogFrame then
        WardrobeTransmogFrame.ToggleSecondaryAppearanceCheckbox.Label:SetPoint("RIGHT", WardrobeTransmogFrame.ToggleSecondaryAppearanceCheckbox, "RIGHT", 140, 0)
    end

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
        if not CollectionsJournal:IsClampedToScreen() then
            CollectionsJournal:SetClampedToScreen(true)
        end
        CollectionsJournal:SetResizable(ADDON.settings.ui.showResizeEdge and CollectionsJournal.selectedTab == COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS)
    end
end, ADDON_NAME .. '_Resize')