local _, ADDON = ...

ADDON.Api = {}

function ADDON.Api:MountIdToOriginalIndex(mountId)
    ADDON:ResetIngameFilter()

    local count = C_MountJournal.GetNumDisplayedMounts()
    for i = 1, count do
        local displayedMountId = C_MountJournal.GetDisplayedMountID(i)
        if displayedMountId == mountId then
            return i
        end
    end

    return nil
end

function ADDON.Api:GetMountInfoByID(mountId)
    local creatureName, spellId, icon, active, isUsable, sourceType, isFavorite, isFaction, faction, hideOnChar, isCollected, mountID, isSteadyFlight, a, b, c, d, e, f, g, h = C_MountJournal.GetMountInfoByID(mountId)
    isUsable = isUsable and C_Spell.IsSpellUsable(spellId)
    isSteadyFlight = isSteadyFlight and ADDON.isRetail

    return creatureName, spellId, icon, active, isUsable, sourceType, isFavorite, isFaction, faction, hideOnChar, isCollected, mountID, isSteadyFlight, a, b, c, d, e, f, g, h
end

function ADDON.Api:GetMountLink(spellId)
    local link = C_MountJournal.GetMountLink(spellId)
    if not link or strlen(link) > 400 then
        -- fallback for broken links (https://github.com/Stanzilla/WoWUIBugs/issues/699)
        return C_Spell.GetSpellLink(spellId)
    end

    return link
end
function ADDON.Api:PickupByID(mountId, ...)
    local index = ADDON.Api:MountIdToOriginalIndex(mountId)
    if index then
        return C_MountJournal.Pickup(index, ...)
    end
end

--region favorites
function ADDON.Api:HasFavorites()
    local _, _, favorites = ADDON.Api:GetFavoriteProfile()
    return #favorites > 0
end
function ADDON.Api:GetFavoriteProfile()
    local playerGuid = UnitGUID("player")
    local profileIndex = ADDON.settings.favorites.assignments[playerGuid] or 1
    if not ADDON.settings.favorites.profiles[profileIndex] then
        profileIndex = 1
    end

    local name = ADDON.settings.favorites.profiles[profileIndex].name
    if profileIndex == 1 then
        name = ADDON.L.FAVORITE_ACCOUNT_PROFILE
    end

    return profileIndex, name, ADDON.settings.favorites.profiles[profileIndex].mounts
end
function ADDON.Api:GetIsFavoriteByID(mountId)
    local _, _, favorites = ADDON.Api:GetFavoriteProfile()
    return tContains(favorites, mountId)
end
function ADDON.Api:SetIsFavoriteByID(mountId, value)
    local _, _, favorites = ADDON.Api:GetFavoriteProfile()

    local hasChange = false
    if true == value and not tContains(favorites, mountId) then
        table.insert(favorites, mountId)
        hasChange = true

    elseif false == value then
        local i = tIndexOf(favorites, mountId)
        if i then
            tUnorderedRemove(favorites, i)
            hasChange = true
        end
    end

    if hasChange then
        ADDON.Events:TriggerEvent("OnFavoritesChanged")
    end
end
function ADDON.Api:SetBulkIsFavorites(filteredProvider, inclusive)
    local _, _, profileMounts = ADDON.Api:GetFavoriteProfile()

    local mountIdsToAdd = CopyValuesAsKeys(filteredProvider)
    local hasChange = false

    local index = 1
    while index <= #profileMounts do
        local mountId = profileMounts[index]

        if mountIdsToAdd[mountId] then
            mountIdsToAdd[mountId] = nil
            index = index + 1
        elseif inclusive then
            -- skip remove
            index = index + 1
        else
            tUnorderedRemove(profileMounts, index)
            hasChange = true
        end
    end

    local tInsert = table.insert
    for mountId, shouldAdd in pairs(mountIdsToAdd) do
        if shouldAdd then
            local isCollected = select(11, C_MountJournal.GetMountInfoByID(mountId))
            if isCollected then
                tInsert(profileMounts, mountId)
                hasChange = true
            end
        end
    end

    if hasChange then
        ADDON.Events:TriggerEvent("OnFavoritesChanged")
    end
end
function ADDON.Api:SwitchFavoriteProfile(newIndex)
    local oldIndex = ADDON.Api:GetFavoriteProfile()
    if oldIndex ~= newIndex then
        ADDON.settings.favorites.assignments[UnitGUID("player")] = newIndex
        ADDON.Events:TriggerEvent("OnFavoritesChanged")
        ADDON.Events:TriggerEvent("OnFavoriteProfileChanged")
    end
end
function ADDON.Api:RemoveFavoriteProfile(index)
    if index > 1 then
        local profileIndex = ADDON.Api:GetFavoriteProfile()
        if profileIndex == index then
            ADDON.Api:SwitchFavoriteProfile(1)
        end

        ADDON.settings.favorites.profiles[index] = nil
        -- cleanup all assignments
        for guid, profileIndex in pairs(ADDON.settings.favorites.assignments) do
            if profileIndex == index then
                ADDON.settings.favorites.assignments[guid] = 1
            end
        end
    end
end
--endregion

local selectedCreature
function ADDON.Api:SetSelected(selectedMountID, selectedVariation)
    if MountJournal.selectedMountID ~= selectedMountID then
        selectedCreature = selectedVariation or nil
        MountJournal_SelectByMountID(selectedMountID)
    elseif selectedCreature ~= selectedVariation then
        selectedCreature = selectedVariation or nil
        MountJournal_UpdateMountDisplay(true)
    end
end
function ADDON.Api:GetSelected()
    return MountJournal.selectedMountID, selectedCreature
end

function ADDON.Api:IsDynamicFlight()
    if C_MountJournal.IsDragonridingUnlocked() then
        local description = C_Spell.GetSpellDescription(C_MountJournal.GetDynamicFlightModeSpellID())
        local pos = string.find(description, ACCESSIBILITY_ADV_FLY_LABEL,1 , true)
        if pos then
            return pos < 15
        end
    end

    return false
end


local dataProvider
function ADDON.Api:GetDataProvider()
    if not dataProvider then
        dataProvider = CreateDataProvider()
        dataProvider:SetSortComparator(function(a, b)
            return ADDON:SortHandler(a, b)
        end)
    end

    return dataProvider
end

ADDON.Events:RegisterCallback("OnJournalLoaded", function()
    -- setup hooks
    hooksecurefunc("MountJournal_SelectByMountID", function(mountId)
        ADDON.Api:SetSelected(mountId)
    end)
end, "api hooks")