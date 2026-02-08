local _, ADDON = ...

StaticPopupDialogs["MJE_EDIT_FAVORITE_PROFILE"] = {
    text = ADDON.L.ASK_FAVORITE_PROFILE_NAME,
    button1 = OKAY,
    button2 = CANCEL,
    whileDead = 1,
    hasEditBox = true,
    OnAccept = function (popup, profileIndex)
        local editBox = popup.editBox or popup.EditBox
        local text = editBox:GetText()
        if profileIndex == nil then
            table.insert(ADDON.settings.favorites.profiles, {
                ["name"] = text,
                ["autoFavor"] = false,
                ["mounts"] = {}
            })
            ADDON.Api:SwitchFavoriteProfile(#ADDON.settings.favorites.profiles)
        elseif profileIndex > 1 then
            ADDON.settings.favorites.profiles[profileIndex].name = text
            ADDON.Events:TriggerEvent("OnFavoriteProfileChanged")
        end
    end,
    OnShow = function (popup, profileIndex)
        if profileIndex and ADDON.settings.favorites.profiles[profileIndex] then
            local editBox = popup.editBox or popup.EditBox
            editBox:SetText(ADDON.settings.favorites.profiles[profileIndex].name)
        end
    end,
    timeout = 0,
    hideOnEscape = 1,
    enterClicksFirstButton = 1,
};
StaticPopupDialogs["MJE_CONFIRM_DELETE_FAVORITE_PROFILE"] = {
    text = ADDON.L.CONFIRM_FAVORITE_PROFILE_DELETION,
    button1 = YES,
    button2 = NO,
    OnAccept = function (_, index)
        ADDON.Api:RemoveFavoriteProfile(index)
    end,
    hideOnEscape = 1,
    timeout = 0,
    whileDead = 1,
}

function ADDON.UI:BuildFavoriteProfileMenu(root, withEditOptions)
    local sortedIndex = {}
    local tInsert = table.insert

    root:SetScrollMode(GetScreenHeight() - 100)

    local profiles = ADDON.settings.favorites.profiles
    for index, profileData in pairs(profiles) do
        if profileData then
            tInsert(sortedIndex, index)
        end
    end
    table.sort(sortedIndex, function(a, b)
        return profiles[a].name < profiles[b].name
    end)

    for _, index in ipairs(sortedIndex) do
        local profileData = profiles[index]
        local name = index == 1 and ADDON.L.FAVORITE_ACCOUNT_PROFILE or profileData.name
        local singleProfileRoot = root:CreateRadio(name.." ("..(#profileData.mounts)..")", function()
            return index == ADDON.Api:GetFavoriteProfile()
        end, function()
            ADDON.Api:SwitchFavoriteProfile(index)
            return MenuResponse.Refresh
        end)

        if withEditOptions then
            singleProfileRoot:CreateCheckbox(ADDON.L.FAVOR_AUTO, function()
                return profileData.autoFavor
            end, function()
                profileData.autoFavor = not profileData.autoFavor
                return MenuResponse.Refresh
            end)
            if index > 1 then
                singleProfileRoot:CreateButton(PET_RENAME, function()
                    StaticPopup_Show("MJE_EDIT_FAVORITE_PROFILE", nil, nil, index)
                end)
                singleProfileRoot:CreateButton(REMOVE, function()
                    StaticPopup_Show("MJE_CONFIRM_DELETE_FAVORITE_PROFILE", profileData.name, ADDON.L.FAVORITE_ACCOUNT_PROFILE, index)
                end)
            end
        end
    end
end

local function CreateFavoritesMenu(_, root)
    root:CreateTitle(FAVORITES)
    root:SetScrollMode(GetScreenHeight() - 100)

    root:CreateButton(ADDON.L.FAVOR_DISPLAYED, function()
        local list = {}
        local tInsert = table.insert
        ADDON.Api:GetDataProvider():ForEach(function(data)
            tInsert(list, data.mountID)
        end)

        ADDON.Api:SetBulkIsFavorites(list, true)
    end)
    root:CreateButton(UNCHECK_ALL, function()
        ADDON.Api:SetBulkIsFavorites({})
    end)

    local _, profileName = ADDON.Api:GetFavoriteProfile()
    local profileRoot = root:CreateButton(ADDON.L.FAVORITE_PROFILE..": "..profileName)

    profileRoot:CreateButton(ADD, function()
        StaticPopup_Show("MJE_EDIT_FAVORITE_PROFILE")
    end)
    profileRoot:QueueSpacer()

    ADDON.UI:BuildFavoriteProfileMenu(profileRoot, true)
end

local function BuildStarButton()
    local starButton = CreateFrame("DropdownButton", nil, MountJournal)

    starButton:SetPoint("RIGHT", MountJournal.searchBox, "LEFT", -7, 0)
    starButton:SetSize(16, 16)

    local icon = starButton:CreateTexture(nil, "ARTWORK")
    icon:SetAtlas("auctionhouse-icon-favorite")
    icon:SetAllPoints(starButton)

    starButton:SetHighlightAtlas("auctionhouse-icon-favorite", "ADD")
    local highlight = starButton:GetHighlightTexture()
    highlight:SetAlpha(0.4)
    highlight:SetAllPoints(icon)

    starButton:HookScript("OnMouseDown", function()
        icon:AdjustPointsOffset(1, -1)
    end)
    starButton:HookScript("OnMouseUp", function()
        icon:AdjustPointsOffset(-1, 1)
    end)

    starButton:SetupMenu(CreateFavoritesMenu)

    starButton:Show()
    ADDON.UI.FavoriteButton = starButton

    local searchBox = MountJournal.searchBox
    searchBox:ClearAllPoints()
    searchBox:SetPoint("TOPLEFT", MountJournal.LeftInset, "TOPLEFT", 27, -9)
    searchBox:SetSize(133, 20)
end

ADDON.Events:RegisterCallback("loadUI", BuildStarButton, "favorite star button")