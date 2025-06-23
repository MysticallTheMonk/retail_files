local _, ADDON = ...

local doStrip = false -- for ElvUI

ADDON:RegisterUISetting('displayBackground', "original", ADDON.L.SETTING_DISPLAY_BACKGROUND, function(value)
    if ADDON.initialized then
        if "original" == value and doStrip then
            MountJournal.MountDisplay:StripTextures()
        elseif "original" == value then
            MountJournal.MountDisplay.YesMountsTex:SetTexture("Interface\\PetBattles\\MountJournal-BG")
        elseif "green" == value then
            MountJournal.MountDisplay.YesMountsTex:SetColorTexture(0, 1, 0)
        elseif "blue" == value then
            MountJournal.MountDisplay.YesMountsTex:SetColorTexture(0, 0, 1)
        end
    end
end, {
    ["original"] = CHAT_DEFAULT,
    ["green"] = ICON_TAG_RAID_TARGET_TRIANGLE3:gsub("^.", string.upper),
    ["blue"] = ICON_TAG_RAID_TARGET_SQUARE3:gsub("^.", string.upper),
})

ADDON.Events:RegisterCallback("loadUI", function()
    ADDON:ApplySetting('displayBackground', ADDON.settings.ui.displayBackground)
end)

ADDON.UI:RegisterUIOverhaulCallback(function(frame)
    if frame == MountJournal.MountDisplay then
        doStrip = true
    end
end)