local _, ADDON = ...

MJEPersonalSettings = MJEPersonalSettings or {}
MJEGlobalSettings = MJEGlobalSettings or {}
local defaultFilterStates, defaultSortStates

function ADDON.IsUsingDefaultFilters()
    return tCompare(ADDON.settings.filter, defaultFilterStates, 3)
end

function ADDON:ResetFilterSettings()
    ADDON.settings.filter = CopyTable(defaultFilterStates)
    if ADDON.settings.personalFilter then
        MJEPersonalSettings.filter = ADDON.settings.filter
    else
        MJEGlobalSettings.filter = ADDON.settings.filter
    end
end
function ADDON:ResetSortSettings()
    ADDON.settings.sort = CopyTable(defaultSortStates)
    if ADDON.settings.personalFilter then
        MJEPersonalSettings.sort = ADDON.settings.sort
    else
        MJEGlobalSettings.sort = ADDON.settings.sort
    end
end

local function PrepareDefaults()
    local defaultSettings = {

        trackUsageStats = true,
        searchInDescription = true,
        searchInFamilyName = true,
        searchInNotes = true,
        summonPreviousPetAgain = true,

        personalUi = false,
        ui = {
            showAchievementPoints = true,
            compactMountList = true,
            unlockDisplayCamera = true,
            displayStatistics = {
                CustomizationCount = true,
                UsedCount = true,
                TravelTime = true,
                TravelDistance = true,
                LearnedDate = true,
                Rarity = true,
                Family = true,
                Wowhead = true,
            },
            enableCursorKeys = true,
            slotPosition = "top",
            previewButton = true,
            showPersonalCount = true,
            windowSize = { 0, 0 },
            colorizeNameByRarity = true,
            displayBackground = "original",
            showMountspecialButton = true,
            autoRotateModel = false,
            showResizeEdge = true,
            displayAnimation = "stand",
        },

        notes = {},
        hiddenMounts = {},
        personalHiddenMounts = false,

        personalFilter = false,
        filter = {
            collected = true,
            notCollected = true,
            onlyFavorites = false,
            onlyUsable = false,
            onlyTradable = false,
            onlyRecent = false,
            source = {},
            faction = {
                alliance = true,
                horde = true,
                noFaction = true,
            },
            mountType = {
                ground = true,
                flying = true,
                underwater = true,
                transform = true,
                repair = true,
                passenger = true,
                rideAlong = true,
            },
            rarity = {
                [Enum.ItemQuality.Common or Enum.ItemQuality.Standard] = true,
                [Enum.ItemQuality.Uncommon or Enum.ItemQuality.Good] = true,
                [Enum.ItemQuality.Rare] = true,
                [Enum.ItemQuality.Epic] = true,
                [Enum.ItemQuality.Legendary] = true,
            },
            family = {},
            expansion = {},
            hidden = false,
            hiddenIngame = false,
            color = {},
        },

        sort = {
            by = 'name', -- name|type|family|expansion|rarity|tracking
            descending = false,
            favoritesOnTop = true,
            unusableToBottom = false,
            unownedOnBottom = true,
        },

        favorites = {
            assignments = {},
            profiles = {
                {
                    name = "",
                    autoFavor = false,
                    mounts = {},
                }
            },
        },

        pets = {
            seenInfo = false,
            assignments = {},
        }
    }
    for categoryName, _ in pairs(ADDON.DB.Source) do
        defaultSettings.filter.source[categoryName] = true
    end
    defaultSettings.filter.source["World Event"] = {}
    for categoryName, _ in pairs(ADDON.DB.Source["World Event"]) do
        defaultSettings.filter.source["World Event"][categoryName] = true
    end
    for categoryName, categoryConfig in pairs(ADDON.DB.Family) do
        for subCategory, subConfig in pairs(categoryConfig) do
            if type(subConfig) == "table" then
                if not defaultSettings.filter.family[categoryName] then
                    defaultSettings.filter.family[categoryName] = {}
                end
                defaultSettings.filter.family[categoryName][subCategory] = true
            else
                defaultSettings.filter.family[categoryName] = true
                break
            end
        end
    end
    for i = 0, GetClientDisplayExpansionLevel() do
        defaultSettings.filter.expansion[i] = true
    end

    return defaultSettings
end

local function CombineSettings(settings, defaultSettings)
    for key, value in pairs(defaultSettings) do
        if (settings[key] == nil) then
            settings[key] = value;
        elseif (type(value) == "table") and next(value) ~= nil then
            if type(settings[key]) ~= "table" then
                settings[key] = {}
            end
            CombineSettings(settings[key], value);
        end
    end

    if type(next(settings)) ~= "number" then
        -- cleanup old still existing settings
        for key, _ in pairs(settings) do
            if (defaultSettings[key] == nil) then
                settings[key] = nil;
            end
        end
    end
end

-- Later: remove after 2025-10
local function MigrateToFavoriteProfiles(personalSettings, globalSettings)
    if personalSettings.favoritePerChar and personalSettings.favoredMounts then
        local playerGuid = UnitGUID("player")
        if nil == globalSettings["favorites"]["assignments"][playerGuid] then
            local player, realm = UnitFullName("player")
            local profile = {
                name = player.."-"..realm,
                mounts = personalSettings.favoredMounts,
                autoFavor = personalSettings.autoFavor,
            }
            table.insert(globalSettings["favorites"]["profiles"], profile)
            local profileId = #globalSettings["favorites"]["profiles"]
            globalSettings["favorites"]["assignments"][playerGuid] = profileId
        end
    elseif false == personalSettings.favoritePerChar then
        if personalSettings.autoFavor then
            globalSettings["favorites"]["profiles"][1].autoFavor=true
        end
    end
end

-- Settings have to be loaded during PLAYER_LOGIN
ADDON.Events:RegisterCallback("OnInit", function()
    local defaultSettings = PrepareDefaults()
    defaultFilterStates = CopyTable(defaultSettings.filter)
    defaultSortStates = CopyTable(defaultSettings.sort)
    CombineSettings(MJEGlobalSettings, defaultSettings)
    MigrateToFavoriteProfiles(MJEPersonalSettings, MJEGlobalSettings)
    CombineSettings(MJEPersonalSettings, defaultSettings)

    ADDON.settings = {}

    ADDON:ApplySetting('personalUi', MJEPersonalSettings.personalUi)
    ADDON:ApplySetting('personalHiddenMounts', MJEPersonalSettings.personalHiddenMounts)
    ADDON:ApplySetting('personalFilter', MJEPersonalSettings.personalFilter)
    ADDON:ApplySetting('searchInDescription', MJEPersonalSettings.searchInDescription)
    ADDON:ApplySetting('searchInFamilyName', MJEPersonalSettings.searchInFamilyName)
    ADDON:ApplySetting('searchInNotes', MJEPersonalSettings.searchInNotes)
    ADDON:ApplySetting('summonPreviousPetAgain', MJEPersonalSettings.summonPreviousPetAgain)

    ADDON.settings.trackUsageStats = MJEGlobalSettings.trackUsageStats
    ADDON.settings.notes = MJEGlobalSettings.notes
    ADDON.settings.favorites = MJEGlobalSettings.favorites
    ADDON.settings.pets = MJEGlobalSettings.pets
end, "settings init")