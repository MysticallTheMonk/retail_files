local _, ADDON = ...

ADDON.Events:RegisterCallback("OnLogin", function()
    local MACRO_NAME = "MJE: Random Mount"
    local MACRO_BODY = "/cancelform [nocombat,noknown:15473]\n" -- don't cancel Shadowform
                     .."/run C_MountJournal.SummonByID(0)"
    local MACRO_ICON = "achievement_guildperk_mountup"

    if not InCombatLockdown() then
        local existingName, existingIcon, existingBody = GetMacroInfo(MACRO_NAME)
        if not existingName and GetNumMacros() < 120 then
            CreateMacro(MACRO_NAME, MACRO_ICON, MACRO_BODY)
        elseif existingName and (nil == string.find(existingBody, MACRO_BODY) or existingIcon ~= MACRO_ICON) then
            EditMacro(existingName, nil, MACRO_ICON, MACRO_BODY)
        end
    end
end, "random-macro")

ADDON.Events:RegisterCallback("loadUI", function()
    if not MountJournal.SummonRandomFavoriteButton and not MountJournal.SummonRandomFavoriteSpellFrame then
        local button = CreateFrame("Button", nil, MountJournal, "MJE_SummonRandomFavoriteButton")
        button:RegisterForDrag("LeftButton")
        button:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            --GameTooltip:SetMountBySpellID(150544); -- spell does not yet exist in Cataclysm
            GameTooltip_SetTitle(GameTooltip, MOUNT_JOURNAL_SUMMON_RANDOM_FAVORITE_MOUNT)
            GameTooltip:Show()
        end)
        button:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        button:SetAttribute("MJE_ToolbarIndex", "RandomFavorite")
        ADDON.UI:RegisterToolbarGroup("00-random-mount", button)
    end
end, "summon random mount button")