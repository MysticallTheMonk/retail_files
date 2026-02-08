local _, ADDON = ...

local INDEX_USE_COUNT, INDEX_LAST_USE_TIME, INDEX_TRAVEL_TIME, INDEX_TRAVEL_DISTANCE, INDEX_LEARNED_TIME = 1, 2, 3, 4, 5

MJETrackingData = MJETrackingData or {}

local HBD = LibStub("HereBeDragons-2.0")
local startZone, startPositionX, startPositionY, travelTicker

local function isEnabled()
    return ADDON.settings.trackUsageStats and not IsOnTournamentRealm()
end

local function initData(mountId)
    if not MJETrackingData[mountId] then
        MJETrackingData[mountId] = {
            [INDEX_USE_COUNT] = 0,
            [INDEX_LAST_USE_TIME] = nil,
            [INDEX_TRAVEL_TIME] = 0,
            [INDEX_TRAVEL_DISTANCE] = 0,
            [INDEX_LEARNED_TIME] = nil,
        }
    end

    return MJETrackingData[mountId]
end

function ADDON:GetMountStatistics(mountId)
    local blob = MJETrackingData[mountId] or {}
    return (blob[INDEX_USE_COUNT] or 0), (blob[INDEX_LAST_USE_TIME] or nil), (blob[INDEX_TRAVEL_TIME] or 0), (blob[INDEX_TRAVEL_DISTANCE] or 0), (blob[INDEX_LEARNED_TIME] or nil)
end

function ADDON:SetLearnedDate(mountId, year, month, day)
    if mountId and isEnabled() then
        local blob = initData(mountId)
        if blob[INDEX_LEARNED_TIME] == nil and year >= 2000 and year < 2050 and month >= 1 and month <= 12 and day >= 1 and day <= 31 then
            blob[INDEX_LEARNED_TIME] = time({ year = year, month = month, day = day, hour = 12, min = 0, sec = 0 })
            return true
        end
    end
end

local function updateDistance(mountId)
    if MJETrackingData[mountId] then
        local blob = MJETrackingData[mountId]
        local currentPosX, currentPosY, currentZone = HBD:GetPlayerZonePosition()
        local distance = HBD:GetZoneDistance(startZone, startPositionX, startPositionY, currentZone, currentPosX, currentPosY)
        if distance then
            blob[INDEX_TRAVEL_DISTANCE] = blob[INDEX_TRAVEL_DISTANCE] + distance
        end
        startZone, startPositionX, startPositionY = currentZone, currentPosX, currentPosY
    end
end

ADDON.Events:RegisterCallback("OnMountUp", function(_, mount, isOnLogin)
    if isEnabled() then
        local blob = initData(mount)
        blob[INDEX_LAST_USE_TIME] = GetServerTime()
        if not isOnLogin then
            blob[INDEX_USE_COUNT] = blob[INDEX_USE_COUNT] + 1
        end
        startPositionX, startPositionY, startZone = HBD:GetPlayerZonePosition()
        travelTicker = C_Timer.NewTicker(5, function()
            updateDistance(mount)
        end)
    end
end, "tracking")
ADDON.Events:RegisterCallback("OnMountDown", function(_, mount)
    if isEnabled() then
        local blob = initData(mount)
        blob[INDEX_TRAVEL_TIME] = blob[INDEX_TRAVEL_TIME] + (GetServerTime() - blob[INDEX_LAST_USE_TIME])

        travelTicker:Cancel()
        updateDistance(mount)
        startZone, startPositionX, startPositionY = nil, nil, nil
    end
end, "tracking")

ADDON.Events:RegisterCallback("OnNewMount", function(_, mountId)
    if mountId and isEnabled() then
        local blob = initData(mountId)
        if nil == blob[INDEX_LEARNED_TIME] then
            blob[INDEX_LEARNED_TIME] = GetServerTime()
        end
    end
end, "tracking")

ADDON:RegisterBehaviourSetting('trackUsageStats', true, ADDON.L.SETTING_TRACK_USAGE, function(flag)
    MJEGlobalSettings.trackUsageStats = flag
end)

local function parseLearnedDateForMount(mountId, achievementIds)
    if mountId and (not MJETrackingData[mountId] or not MJETrackingData[mountId][INDEX_LEARNED_TIME]) then
        local collected = select(11, C_MountJournal.GetMountInfoByID(mountId))
        if collected then
            for _, achievementId in ipairs(achievementIds) do
                local _, _, _, completed, month, day, year = GetAchievementInfo(achievementId)
                if completed then
                    local blob = initData(mountId)
                    blob[INDEX_LEARNED_TIME] = time({
                        ["year"] = 2000 + year,
                        ["month"] = month,
                        ["day"] = day,
                    })
                    break
                end
            end
        end
    end
end
local function parseLearnedDates()
    if isEnabled() then
        for spellId, achievementIds in pairs(ADDON.DB.Source.Achievement) do
            if achievementIds ~= true then
                local mountId = C_MountJournal.GetMountFromSpell(spellId)
                if type(achievementIds) == "number" then
                    achievementIds = { achievementIds }
                end
                parseLearnedDateForMount(mountId, achievementIds)
            end
        end

        for mountId, achievementId in pairs(ADDON.DB.FeatsOfStrength) do
            if type(achievementId) == "number" then
                achievementId = { achievementId }
            end
            parseLearnedDateForMount(mountId, achievementId)
        end
    end
end
ADDON.Events:RegisterCallback("preloadUI", parseLearnedDates, "tracking")