local _, ADDON = ...

local function CreateFleetingCache()
    local cache = {}
    local setTimer = false

    return {
        Has = function(_, cacheKey)
            return cache[cacheKey] ~= nil
        end,
        Get = function(self, cacheKey, initializerFunc)
            if initializerFunc and not self:Has(cacheKey) then
                self:Set(cacheKey, initializerFunc())
            end

            if cache[cacheKey] then
                return unpack(cache[cacheKey])
            end
        end,
        Set = function(_, cacheKey, ...)
            cache[cacheKey] = {...}
            if not setTimer then
                C_Timer.After(0.1, function()
                    cache = {}
                    setTimer = false
                end)
                setTimer = true
            end
        end,
    }
end

local function TransliterateName(name)

    -- has latin-1 supplement
    if string.find(name, "\195", 1, true) then
        local replaceMap = {
            ["À"] = "A",
            ["Á"] = "A",
            ["Â"] = "A",
            ["Ã"] = "A",
            ["Ä"] = "A",
            ["Å"] = "A",
            ["Æ"] = "AE",
            ["Ç"] = "C",
            ["È"] = "E",
            ["É"] = "E",
            ["Ê"] = "E",
            ["Ë"] = "E",
            ["Ì"] = "I",
            ["Í"] = "I",
            ["Î"] = "I",
            ["Ï"] = "I",
            ["Ð"] = "D",
            ["Ñ"] = "N",
            ["Ò"] = "O",
            ["Ó"] = "O",
            ["Ô"] = "O",
            ["Õ"] = "O",
            ["Ö"] = "O",
            ["Ø"] = "O",
            ["Ù"] = "U",
            ["Ú"] = "U",
            ["Û"] = "U",
            ["Ü"] = "U",
            ["Ý"] = "Y",
            ["ß"] = "ss",
            ["à"] = "a",
            ["á"] = "a",
            ["â"] = "a",
            ["ã"] = "a",
            ["ä"] = "a",
            ["å"] = "a",
            ["æ"] = "ae",
            ["ç"] = "c",
            ["è"] = "e",
            ["é"] = "e",
            ["ê"] = "e",
            ["ë"] = "e",
            ["ì"] = "i",
            ["í"] = "i",
            ["î"] = "i",
            ["ï"] = "i",
            ["ñ"] = "n",
            ["ò"] = "o",
            ["ó"] = "o",
            ["ô"] = "o",
            ["õ"] = "o",
            ["ö"] = "o",
            ["ø"] = "o",
            ["ù"] = "u",
            ["ú"] = "u",
            ["û"] = "u",
            ["ü"] = "u",
            ["ý"] = "y",
            ["ÿ"] = "y",
        }
        name = string.gsub(name, "\195.", replaceMap)
    end

    return name
end

local nameCache
local function CacheAndTransliterateName(name, cacheKey)
    nameCache = nameCache or CreateFleetingCache()
    return nameCache:Get(cacheKey, function()
        return TransliterateName(name)
    end)
end

local TrackingIndex = {
    usage_count = 1,
    last_usage = 2,
    travel_duration = 3,
    travel_distance = 4,
    learned_date = 5,
}

local mountCache
local function CacheMount(mountId)
    mountCache = mountCache or CreateFleetingCache()
    return mountCache:Get(mountId, function()
        local name, _, _, _, isUsable, _, _, _, _, _, isCollected = ADDON.Api:GetMountInfoByID(mountId)
        local needsFanfare = isCollected and C_MountJournal.NeedsFanfare(mountId)
        local isFavorite = isCollected and ADDON.Api:GetIsFavoriteByID(mountId)

        return name, isUsable, isFavorite, isCollected, needsFanfare
    end)
end
local function FallbackByName(mountIdA, mountIdB)
    local nameA = CacheMount(mountIdA)
    local nameB = CacheMount(mountIdB)
    return CacheAndTransliterateName(nameA, mountIdA) < CacheAndTransliterateName(nameB, mountIdB)
end

local function CheckDescending(result)
    if ADDON.settings.sort.descending then
        result = not result
    end

    return result
end

--region sort by type
local typeCache
local RemappedTypes
local function RemapTypeIds()
    local result = {}
    for category, values in pairs(ADDON.DB.Type) do
        for _, typeId in pairs(values.typeIDs or {}) do
            result[typeId] = category
        end
    end

    return result
end
local function GetMountTypeId(mountId)
    typeCache = typeCache or CreateFleetingCache()
    return typeCache:Get(mountId, function()
        return select(5, C_MountJournal.GetMountInfoExtraByID(mountId))
    end)
end
local function SortByType(mountIdA, mountIdB)
    RemappedTypes = RemappedTypes or RemapTypeIds()
    local mountTypeA = RemappedTypes[GetMountTypeId(mountIdA)] or nil
    local mountTypeB = RemappedTypes[GetMountTypeId(mountIdB)] or nil

    local result = false
    if mountTypeA == mountTypeB then
        return FallbackByName(mountIdA, mountIdB)
    elseif mountTypeA == "flying" then
        result = true
    elseif mountTypeA == "ground" then
        result = (mountTypeB == "underwater")
    elseif mountTypeA == "underwater" then
        result = false
    end

    return CheckDescending(result)
end
--endregion

local function SortByTracking(mountIdA, mountIdB)
    local sortBy = ADDON.settings.sort.by
    local result = false
    local valueA = select(TrackingIndex[sortBy], ADDON:GetMountStatistics(mountIdA)) or 0
    local valueB = select(TrackingIndex[sortBy], ADDON:GetMountStatistics(mountIdB)) or 0
    if valueA == valueB then
        return FallbackByName(mountIdA, mountIdB)
    elseif sortBy == 'learned_date' or sortBy == 'last_usage' then
        result = valueA > valueB
    else
        result = valueA < valueB
    end

    return CheckDescending(result)
end

local LibMountsRarity
local function SortByRarity(mountIdA, mountIdB)
    LibMountsRarity = LibMountsRarity or LibStub("MountsRarity-2.0")
    local rarityA = LibMountsRarity:GetRarityByID(mountIdA)
    local rarityB = LibMountsRarity:GetRarityByID(mountIdB)
    if nil ~= rarityA and nil ~= rarityB and rarityA ~= rarityB then
        return CheckDescending(rarityA > rarityB)
    elseif nil ~= rarityA and nil == rarityB then
        return true
    elseif nil == rarityA and nil ~= rarityB then
        return false
    end

    return FallbackByName(mountIdA, mountIdB)
end

local sortedFamilies
local familyCache
local function LoadAndSortFamilies()
    local L = ADDON.L
    local result = {}

    for topFamily, topValues in pairs(ADDON.DB.Family) do
        local topName = L[topFamily]
        topName = topName and TransliterateName(topName) or topFamily

        if type(select(2, next(topValues))) == "table" then
            for subFamily, _ in pairs(topValues) do
                local subName = L[subFamily]
                subName = subName and TransliterateName(subName) or subFamily

                result[topFamily.."--"..subFamily] = topName.."--"..subName
            end
        else
            result[topFamily] = topName
        end
    end

    local sortedResult= {}
    for index, familyPath in ipairs(GetKeysArraySortedByValue(result)) do
        sortedResult[familyPath] = index
    end
    return sortedResult
end
local function GetFamilyByMount(mountId)
    familyCache = familyCache or CreateFleetingCache()
    return familyCache:Get(mountId, function()
        local filterSettings = ADDON.settings.filter.family
        for topFamily, topValues in pairs(ADDON.DB.Family) do
            if topValues[mountId] and filterSettings[topFamily] then
                return topFamily
            end

            if type(select(2, next(topValues))) == "table" then
                for subFamily, subValues in pairs(topValues) do
                    if subValues[mountId] and filterSettings[topFamily][subFamily] then
                        return topFamily.."--"..subFamily
                    end
                end
            end
        end
    end)
end
local function SortByFamily(mountIdA, mountIdB)
    sortedFamilies = sortedFamilies or LoadAndSortFamilies()

    local familyA = GetFamilyByMount(mountIdA) or ""
    local familyB = GetFamilyByMount(mountIdB) or ""
    local familyIndexA = sortedFamilies[familyA]
    local familyIndexB = sortedFamilies[familyB]

    if nil ~= familyIndexA and nil ~= familyIndexB and familyIndexA ~= familyIndexB then
        return CheckDescending(familyIndexA < familyIndexB)
    elseif nil ~= familyIndexA and nil == familyIndexB then
        return true
    elseif nil == familyIndexA and nil ~= familyIndexB then
        return false
    end

    return FallbackByName(mountIdA, mountIdB)
end

local expansionCache
local function GetExpansionOfMount(mountId)
    expansionCache = expansionCache or CreateFleetingCache()
    return expansionCache:Get(mountId, function()
        local matchedExpansion = 0
        for expansion, config in pairs(ADDON.DB.Expansion) do
            if config[mountId] then
                return expansion
            end
            if mountId >= config.minID and mountId <= config.maxID then
                matchedExpansion = expansion
            end
        end

        return matchedExpansion
    end)
end
local function SortByExpansion(mountIdA, mountIdB)
    local expansionA = GetExpansionOfMount(mountIdA)
    local expansionB = GetExpansionOfMount(mountIdB)

    if expansionA == expansionB then
        return FallbackByName(mountIdA, mountIdB)
    end

    return CheckDescending(expansionA < expansionB)
end

function ADDON:SortHandler(mountA, mountB)
    local mountIdA, mountIdB = mountA.mountID, mountB.mountID
    if mountIdA == mountIdB then
        return false
    end

    local _, isUsableA, isFavoriteA, isCollectedA, needsFanfareA = CacheMount(mountIdA)
    local _, isUsableB, isFavoriteB, isCollectedB, needsFanfareB = CacheMount(mountIdB)

    if needsFanfareA ~= needsFanfareB then
        return needsFanfareA and not needsFanfareB
    end

    if ADDON.settings.sort.favoritesOnTop and isFavoriteA ~= isFavoriteB then
        return isFavoriteA and not isFavoriteB
    end
    if ADDON.settings.sort.unusableToBottom and isUsableA ~= isUsableB then
        return isUsableA and not isUsableB
    end
    if ADDON.settings.sort.unownedOnBottom and isCollectedA ~= isCollectedB then
        return isCollectedA and not isCollectedB
    end

    local sortBy = ADDON.settings.sort.by
    if sortBy == 'type' then
        return SortByType(mountIdA, mountIdB)
    elseif sortBy == 'expansion' then
        return SortByExpansion(mountIdA, mountIdB)
    elseif sortBy == 'rarity' then
        return SortByRarity(mountIdA, mountIdB)
    elseif sortBy == 'family' then
        return SortByFamily(mountIdA, mountIdB)
    elseif TrackingIndex[sortBy] then
        return SortByTracking(mountIdA, mountIdB)
    else
        return CheckDescending(FallbackByName(mountIdA, mountIdB))
    end
end