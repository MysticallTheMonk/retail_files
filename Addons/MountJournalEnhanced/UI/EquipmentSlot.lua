local _, ADDON = ...

ADDON.Events:RegisterCallback("loadUI", function()
    local button = MountJournal.SlotButton
    if button then
        button:SetParent(MountJournal)
        button:ClearAllPoints()
        button:SetScale(0.75)

        -- Hide and fix surrounding insets
        MountJournal.BottomLeftInset:Hide()
        MountJournal.LeftInset:SetPoint("BOTTOMLEFT", 4, 26)
        MountJournal.RightInset:SetPoint("BOTTOMLEFT", MountJournal.LeftInset, "BOTTOMRIGHT", 20, 0)

        button:SetAttribute("MJE_ToolbarIndex", "Equiment")
        ADDON.UI:RegisterToolbarGroup("09-equipment", button)
    end
end, "equipment slot")