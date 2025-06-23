local _, ADDON = ...

local function collectFavoredByApi()
    local mountIds = C_MountJournal.GetMountIDs()
    local favoredMounts = {}
    for _, mountId in ipairs(mountIds) do
        local _, _, _, _, _, _, isFavorite = C_MountJournal.GetMountInfoByID(mountId)
        if isFavorite then
            favoredMounts[#favoredMounts+1] = mountId
        end
    end

    return favoredMounts
end

local backgroundTimer
local function UpdateFavoritesInBackground()
    if backgroundTimer then
        backgroundTimer:Cancel()
    end

    local _, _ , favorites = ADDON.Api:GetFavoriteProfile()
    local flippedFavorites = CopyValuesAsKeys(favorites)
    local operationCount = #favorites

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
        backgroundTimer = C_Timer.NewTicker(0.4, function()
            for mountId, v in pairs(flippedFavorites) do
                if v or v == false then
                    local index =  ADDON.Api:MountIdToOriginalIndex(mountId)
                    if index then
                        C_MountJournal.SetIsFavorite(index, v ~= false)
                    end

                    flippedFavorites[mountId] = nil
                    break
                end
            end
        end, operationCount)
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