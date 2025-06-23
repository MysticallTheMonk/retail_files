local ADDON_NAME, ADDON = ...

local function togglePortrait(cool)
    if ADDON.isClassic then
        if cool then
            CollectionsJournal.portrait:SetTexture("Interface\\Addons\\MountJournalEnhanced\\UI\\icons\\mje.png")
            CollectionsJournal.portrait:SetTexCoord(0, 1, 0, 1)
        else
            SetPortraitToTexture(CollectionsJournal.portrait, "Interface\\ICONS\\Ability_Mount_RidingHorse")
            CollectionsJournal.portrait:SetTexCoord(1, 0, 0, 1)
        end
    else
        if cool then
            CollectionsJournal:GetPortrait():SetTexture("Interface\\Addons\\MountJournalEnhanced\\UI\\icons\\mje.png")
        else
            CollectionsJournal:SetPortraitToAsset("Interface\\Icons\\MountJournalPortrait")
        end
    end
end

ADDON.Events:RegisterCallback("loadUI", function()
    local portrait = ADDON.isClassic and CollectionsJournal.portrait or CollectionsJournal:GetPortrait()

    if ADDON.isClassic  then
        -- SetPortraitToTexture() doesn't work for own textures/pngs :(
        -- so we need to add a mask as well.
        local mask = CollectionsJournal:CreateMaskTexture()
        mask:SetAllPoints(portrait)
        mask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        portrait:AddMaskTexture(mask)
    end

    portrait:EnableMouse(true)
    portrait:HookScript("OnMouseDown", function()
        if CollectionsJournal.selectedTab == 1 then
            togglePortrait(strsub(portrait:GetTexture(), 1, 8) == "Portrait")
        end
    end)
end, "fun stuff")

local today = C_DateAndTime.GetCurrentCalendarTime()
if today.month == 4 and today.monthDay == 1 then
    EventRegistry:RegisterCallback("MountJournal.OnShow", function()
        togglePortrait(true)
    end, ADDON_NAME .. 'fun stuff')
end