local _, ADDON = ...

local button, doStrip

ADDON.UI:RegisterUIOverhaulCallback(function(frame)
    if frame ==  MountJournal then
        doStrip = true
    end
end)

local function BuildButton()
    local tooltip = CreateFrame("GameTooltip", "MJEMountSpecialButtonToolTip", MountJournal, "SharedTooltipTemplate")

    local frame = CreateFrame("Button", nil, MountJournal, "InsecureActionButtonTemplate,UIPanelButtonNoTooltipTemplate")
    frame:SetText("!")

    frame:HookScript("OnEnter", function()
        tooltip:SetOwner(frame, "ANCHOR_RIGHT")
        tooltip:SetText("/mountspecial", HIGHLIGHT_FONT_COLOR:GetRGB());
        GameTooltip_AddNormalLine(tooltip, ADDON.L.SPECIAL_TIP)
        tooltip:Show()
    end)
    frame:HookScript("OnLeave", function()
        tooltip:Hide()
    end)
    frame.tooltipText = "/mountspecial"

    frame:GetFontString():SetJustifyV("MIDDLE")
    frame:SetWidth(frame:GetFontString():GetStringWidth() + 30)
    frame:SetPoint("LEFT", MountJournalMountButton, "RIGHT", 3, 0)
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("typerelease", "macro")
    frame:SetAttribute("macrotext", "/mountspecial");
    frame:SetAttribute("pressAndHoldAction", "1");

    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function(self, event)
        if event =="PLAYER_REGEN_DISABLED" then
            self:Disable()
        elseif event =="PLAYER_REGEN_ENABLED" and ADDON:IsPlayerMounted() then
            self:Enable()
        end
    end)
    if not ADDON:IsPlayerMounted() then
        frame:Disable()
    end

    if doStrip and ElvUI then
        local E = unpack(ElvUI)
        local S = E:GetModule('Skins')
        S:HandleButton(frame)
    end

    return frame
end

ADDON:RegisterUISetting('showMountspecialButton', true, ADDON.L.SETTING_MOUNTSPECIAL_BUTTON, function(flag)
    if flag and not button and ADDON.initialized then
        button = BuildButton()
    end
    if button then
        button:SetShown(flag)
    end
end)

ADDON.Events:RegisterCallback("loadUI", function()
    ADDON:ApplySetting('showMountspecialButton', ADDON.settings.ui.showMountspecialButton)
end, "mountspecial button")

ADDON.Events:RegisterCallback("OnMountDown", function(...)
    if button then
        button:Disable()
    end
end, 'mountspecial button')

ADDON.Events:RegisterCallback("OnMountUp", function(...)
    if button and not InCombatLockdown() then
        button:Enable()
    end
end, 'mountspecial button')