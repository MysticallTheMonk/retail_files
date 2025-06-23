local _, ADDON = ...

local originalParent
local toolbarHandle

ADDON:RegisterUISetting('slotPosition', "top", ADDON.L.SETTING_MOVE_EQUIPMENT_SLOT, function(flag)
    if ADDON.initialized then
        local button = MountJournal.SlotButton

        if flag == "original" then
            if originalParent then
                button:SetParent(originalParent)
            end
            toolbarHandle(false)
            button:SetScale(1.0)
            ADDON.UI:RestoreSize(button)
            ADDON.UI:RestorePoint(button)
            ADDON.UI:RestorePoint(MountJournal.LeftInset, "BOTTOMLEFT")
            ADDON.UI:RestorePoint(MountJournal.RightInset, "BOTTOMLEFT")
            MountJournal.BottomLeftInset:Show()
        else
            -- backup frame settings
            if nil == originalParent then
                originalParent = button:GetParent()
            end

            -- move button
            button:SetParent(MountJournal.MountDisplay)
            button:ClearAllPoints()
            if flag == "top" then
                toolbarHandle(true)
                button:SetScale(0.75)
            else
                toolbarHandle(false)
                button:SetScale(1.0)
                button:SetPoint("BOTTOMLEFT", MountJournal.MountDisplay, 15, 15)
            end

            -- Hide and fix surrounding insets
            MountJournal.BottomLeftInset:Hide()
            MountJournal.LeftInset:SetPoint("BOTTOMLEFT", 4, 26)
            MountJournal.RightInset:SetPoint("BOTTOMLEFT", MountJournal.LeftInset, "BOTTOMRIGHT", 20, 0)
        end
    end
end,
    {
        ["original"] = CHAT_DEFAULT,
        ["top"] = ADDON.L.SETTING_MOVE_EQUIPMENT_SLOT_OPTION_TOP,
        ["display"] = ADDON.L.SETTING_MOVE_EQUIPMENT_SLOT_OPTION_DISPLAY,
    }
)

ADDON.Events:RegisterCallback("loadUI", function()
    ADDON.UI:SaveSize(MountJournal.SlotButton)
    ADDON.UI:SavePoint(MountJournal.SlotButton)
    ADDON.UI:SavePoint(MountJournal.LeftInset, "BOTTOMLEFT")
    ADDON.UI:SavePoint(MountJournal.RightInset, "BOTTOMLEFT")

    toolbarHandle = ADDON.UI:RegisterToolbarGroup("09-equipment", MountJournal.SlotButton)
    ADDON:ApplySetting('slotPosition', ADDON.settings.ui.slotPosition)
end, "equipment slot")