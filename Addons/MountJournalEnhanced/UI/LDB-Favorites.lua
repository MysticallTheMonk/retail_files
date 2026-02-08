local ADDON_NAME, ADDON = ...

local function generateFavoritesMenu(_, root)
    root:SetTag(ADDON_NAME.."-LDB")
    root:SetScrollMode(GetScreenHeight() - 100)

    local _, _, favoredMounts = ADDON.Api:GetFavoriteProfile()
    local sortedMounts = CopyTable(favoredMounts)
    table.sort(sortedMounts, function(a, b)
        local nameA = C_MountJournal.GetMountInfoByID(a)
        local nameB = C_MountJournal.GetMountInfoByID(b)

        return (nameA or "") < (nameB or "")
    end)

    for _, mountID in ipairs(sortedMounts) do
        local clickHandler = function(_, data)
            if data.buttonName == "RightButton" then
                SetCollectionsJournalShown(true, COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS)
                ADDON.Api:SetSelected(mountID)
            else
                local _, _, _, active = C_MountJournal.GetMountInfoByID(mountID)
                if  active then
                    C_MountJournal.Dismiss()
                else
                    C_MountJournal.SummonByID(mountID)
                end
            end
        end

        local name, _, icon, active = C_MountJournal.GetMountInfoByID(mountID)
        local element = root:CreateButton("|T" .. icon .. ":0|t "..name, clickHandler)
        element:AddInitializer(function(button)
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            if active then
                button.fontString:SetTextColor(1.0, 0.82, 0)
            end
        end)
    end
end

local function generateProfileMenu(_, root)
    root:SetTag(ADDON_NAME.."-LDB-FavoriteProfiles")

    root:CreateTitle(ADDON.L.FAVORITE_PROFILE)
    ADDON.UI:BuildFavoriteProfileMenu(root)
end

local function count()
    local c = 0
    local mountIDs = C_MountJournal.GetMountIDs();
    for _, mountID in ipairs(mountIDs) do
        local _, _, _, _, _, _, _, _, _, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID);
        if isCollected and hideOnChar ~= true then
            c = c + 1;
        end
    end

    return c
end

local function OpenMenu(anchorSource, generator)
    local menuDescription = MenuUtil.CreateRootMenuDescription(MenuVariants.GetDefaultContextMenuMixin())

    local point, relativeTo, relativePoint, offsetX, offsetY = anchorSource:GetPoint(1)

    Menu.PopulateDescription(generator, relativeTo, menuDescription)

    local anchor = CreateAnchor(point, relativeTo, relativePoint, offsetX, offsetY)
    local menu = Menu.GetManager():OpenMenu(relativeTo, menuDescription, anchor)
    if menu then
        menu:HookScript("OnLeave", function()
            if not menu:IsMouseOver() then
                menu:Close()
            end
        end) -- OnLeave gets reset every time
    end

    return menu
end

ADDON.Events:RegisterCallback("OnLogin", function()
    local ldb = LibStub("LibDataBroker-1.1", true)
    if not ldb or not MenuUtil then
        return
    end

    local menu
    local closeMenu = function()
        if menu and not menu:IsMouseOver(10, -10, -10, 10) then
            menu:Close()
        end
    end

    -- Use a proxy frame to get a proper tooltip position from the broker addon
    local tooltipProxy = CreateFrame("Frame")
    tooltipProxy:Hide()
    tooltipProxy:HookScript("OnShow", function()
        local point, relativeTo, relativePoint, offsetX, offsetY = tooltipProxy:GetPoint(1)
        if ADDON.Api:HasFavorites() then
            menu = OpenMenu(tooltipProxy, generateFavoritesMenu)
        else
            local L = ADDON.L
            GameTooltip:SetOwner(tooltipProxy, "ANCHOR_NONE")
            GameTooltip:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
            GameTooltip:ClearLines()
            GameTooltip_SetTitle(GameTooltip, L.LDB_TIP_NO_FAVORITES_TITLE)
            GameTooltip_AddInstructionLine(GameTooltip, MOUNT_JOURNAL_NO_VALID_FAVORITES, true)
            GameTooltip:AddLine(L.LDB_TIP_NO_FAVORITES_LEFT_CLICK)
            GameTooltip:AddLine(L.LDB_TIP_NO_FAVORITES_RIGHT_CLICK)
            GameTooltip:Show()
        end
    end)
    tooltipProxy:HookScript("OnHide", function()
        if ADDON.Api:HasFavorites() then
            closeMenu()
        else
            GameTooltip:Hide()
        end
    end)
    tooltipProxy.SetOwner = ADDON.UI.SetOwner

    local _, profileName = ADDON.Api:GetFavoriteProfile()
    local ldbName = ADDON_NAME.." Favorites"
    local ldbDataObject = ldb:NewDataObject( ldbName, {
        type = "data source",
        text = profileName,
        label = ldbName, -- Titan Panel uses label as entry name in its plugin list.
        value = count(),
        icon = "Interface\\Addons\\MountJournalEnhanced\\UI\\icons\\mje.png",
        tooltip = tooltipProxy,

        OnClick = function(_, button)
            if button == "RightButton" then
                GameTooltip:Hide()
                menu = OpenMenu(tooltipProxy, generateProfileMenu)
            elseif not InCombatLockdown() then
                ToggleCollectionsJournal(COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS)
            end
        end,
    } )
    C_Timer.After(0, function()
        ldbDataObject.label = ADDON.L.FAVORITE_PROFILE
    end)

    ADDON.Events:RegisterCallback("OnFavoriteProfileChanged", function()
        local _, profileName = ADDON.Api:GetFavoriteProfile()
        ldbDataObject.text = profileName
    end, "ldb-favorites")
    ADDON.Events:RegisterCallback("OnNewMount", function()
        ldbDataObject.value = count()
    end, "ldb-favorites")

end, "ldb-plugin")