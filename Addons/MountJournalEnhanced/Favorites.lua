local _, ADDON = ...

local function collectFavoredByApi()
    local c = 0
    local mountIds = C_MountJournal.GetMountIDs()
    local favoredMounts = {}
    for _, mountId in ipairs(mountIds) do
        local _, _, _, _, _, _, isFavorite = C_MountJournal.GetMountInfoByID(mountId)
        if isFavorite then
            c = c + 1
            favoredMounts[c] = mountId
        end
    end

    return favoredMounts
end

local backgroundTimer
local function cancelBackgroundTask()
    if backgroundTimer then
        backgroundTimer:Cancel()
    end
    ADDON.Events:UnregisterFrameEventAndCallback("MOUNT_JOURNAL_SEARCH_UPDATED", 'cleanup-favorite-background')
end
local function UpdateFavoritesInBackground()
    cancelBackgroundTask()

    local _, _ , favorites = ADDON.Api:GetFavoriteProfile()
    favorites = tFilter(favorites, function(mountId)
        local _, _, _, _, _, _, _, _, _, shouldHideOnChar = C_MountJournal.GetMountInfoByID(mountId)
        return not shouldHideOnChar
    end, true)

    local flippedFavorites = {}
    for _, v in pairs(favorites) do -- CopyValuesAsKeys() somehow created faulty list
        flippedFavorites[v] = true
    end
    local operationCount = #favorites
    favorites = nil

    local favoredByApi = collectFavoredByApi()

    for _, mountId in ipairs(favoredByApi) do
        if flippedFavorites[mountId] then
            flippedFavorites[mountId] = nil
            operationCount = operationCount - 1
        else
            flippedFavorites[mountId] = false
            operationCount = operationCount + 1
        end
    end

    if operationCount > 0 then
        local lastTickMount, tickTryMount = 0, 0
        local tickHandler = function()
            local mountId, shouldBeFavored = next(flippedFavorites)
            if mountId then
                if lastTickMount == mountId and tickTryMount >= 3 then
                    flippedFavorites[mountId] = nil
                else
                    if lastTickMount == mountId then
                        tickTryMount = tickTryMount + 1
                    else
                        lastTickMount = mountId
                        tickTryMount = 1
                    end

                    local index = ADDON.Api:MountIdToOriginalIndex(mountId) -- costly call
                    if index then
                        local isFavorite = C_MountJournal.GetIsFavorite(index)
                        if isFavorite == shouldBeFavored then
                            flippedFavorites[mountId] = nil
                        else
                            C_MountJournal.SetIsFavorite(index, shouldBeFavored)
                        end
                    end
                end
            end

            if TableIsEmpty(flippedFavorites) then
                cancelBackgroundTask()
            end
        end

        ADDON.Events:RegisterFrameEventAndCallback("MOUNT_JOURNAL_SEARCH_UPDATED", function()
            local mountId, shouldBeFavored = next(flippedFavorites)
            if mountId then
                local _, _, _, _, _, _, isFavorite = C_MountJournal.GetMountInfoByID(mountId)
                if isFavorite == shouldBeFavored then
                    flippedFavorites[mountId] = nil
                end
            end

            if TableIsEmpty(flippedFavorites) then
                cancelBackgroundTask()
            end
        end, 'cleanup-favorite-background')

        backgroundTimer = C_Timer.NewTicker(0.4, tickHandler)
    end
end

ADDON.Events:RegisterCallback("OnNewMount", function(_, mountId)
    local currentProfile = ADDON.Api:GetFavoriteProfile()

    local tInsert = table.insert
    for index, profileData in pairs(ADDON.settings.favorites.profiles) do
        if profileData and profileData.autoFavor then
            if index == currentProfile then
                ADDON.Api:SetIsFavoriteByID(mountId, true)
            elseif not tContains(profileData.mounts, mountId) then
                tInsert(profileData.mounts, mountId)
            end
        end
    end
end, "autoFavor")

ADDON.Events:RegisterCallback("OnLogin", function()
    local profileIndex, _ , favorites = ADDON.Api:GetFavoriteProfile()
    -- initial scan for account profile
    if 1 == profileIndex and not ADDON.settings.favorites.profiles[1].initialScan then
        ADDON.settings.favorites.profiles[1].initialScan = true
        if 0 == #favorites then
            ADDON.Api:SetBulkIsFavorites(collectFavoredByApi())
        end
    else
        UpdateFavoritesInBackground()
    end
end, "favorite hooks")

ADDON.Events:RegisterCallback("OnFavoritesChanged", function()
    ADDON.Api:GetDataProvider():Sort()

    UpdateFavoritesInBackground()
end, "sort dataprovider")