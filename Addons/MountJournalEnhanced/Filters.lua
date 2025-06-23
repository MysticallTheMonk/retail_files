local _, ADDON = ...

local FamilyDB = ADDON.DB.Family
local SourceDB = ADDON.DB.Source
local ExpansionDB = ADDON.DB.Expansion
local TypeDB = ADDON.DB.Type
local TradableDB = ADDON.DB.Tradable
local IgnoredDB = ADDON.DB.Ignored
local RecentDB = ADDON.DB.Recent
local ColorsDB = ADDON.DB.Colors
local LibMountsRarity

local cachedColor, cachedColorResults = {}, {}

local function FilterByName(searchString, name)
    name = name:lower()
    local pos = strfind(name, searchString, 1, true)
    return pos ~= nil
end
local function FilterByDescription(searchString, mountId)
    if ADDON.settings.searchInDescription then
        local _, description, sourceText = C_MountJournal.GetMountInfoExtraByID(mountId)
        description = description:lower()
        local pos = strfind(description, searchString, 1, true)
        local result = pos ~= nil

        if result == false then
            sourceText = sourceText:lower()
            pos = strfind(sourceText, searchString, 1, true)
            result = pos ~= nil
        end

        return result
    end

    return false
end
local function FilterByFamilyName(searchString, mountId)
    if ADDON.settings.searchInFamilyName then
        local L = ADDON.L
        for topFamily, topItems in pairs(FamilyDB) do
            if topItems[mountId] and strfind((L[topFamily] or topFamily):lower(), searchString, 1, true) ~= nil then
                return true
            end

            if type(select(2, next(topItems))) == "table" then
                for subFamily, subValues in pairs(topItems) do
                    if subValues[mountId] and
                            (
                                strfind((L[subFamily] or subFamily):lower(), searchString, 1, true) ~= nil
                                or strfind((L[topFamily] or topFamily):lower(), searchString, 1, true) ~= nil
                            ) then
                        return true
                    end
                end
            end
        end
    end

    return false
end
local function FilterByNote(searchString, mountId)
    if ADDON.settings.searchInNotes then
        local note = ADDON.settings.notes[mountId]
        if note then
            if strfind(note:lower(), searchString, 1, true) ~= nil then
                return true
            end
        end
    end

    return false
end

local function FilterUserHiddenMounts(spellId)
    return ADDON.settings.filter.hidden or not ADDON.settings.hiddenMounts[spellId]
end
local function FilterIngameHiddenMounts(shouldHideOnChar, mountId)
    if not shouldHideOnChar then
        return true
    end

    if ADDON.settings.filter.hiddenIngame and not IgnoredDB.ids[mountId] then
        local _, _, _, _, mountType = C_MountJournal.GetMountInfoExtraByID(mountId)
        if not IgnoredDB.types[mountType] then
            return true
        end
    end

    return false
end

local function FilterFavoriteMounts(mountId)
    return not ADDON.settings.filter.onlyFavorites or not ADDON.settings.filter.collected or ADDON.Api:GetIsFavoriteByID(mountId)
end

local function FilterUsableMounts(isUsable)
    return not ADDON.settings.filter.onlyUsable or isUsable
end

local function FilterTradableMounts(mountId)
    return not ADDON.settings.filter.onlyTradable or TradableDB[mountId]
end

local function FilterRecentMounts(mountId)
    return not ADDON.settings.filter.onlyRecent
            or (RecentDB.minID <= mountId and not tContains(RecentDB.blacklist, mountId))
            or tContains(RecentDB.whitelist, mountId)
end

local function FilterCollectedMounts(collected)
    return (ADDON.settings.filter.collected and collected) or (ADDON.settings.filter.notCollected and not collected)
end

local function FilterByColor(mountID)

    local filter = ADDON.settings.filter.color
    if #filter == 0 then
        return true
    end

    if cachedColor[1] == filter[1] and cachedColor[2] == filter[2] and cachedColor[3] == filter[3] then
        local cachedResult = cachedColorResults[mountID]
        if cachedResult ~= nil then
            return cachedResult
        end
    else
        cachedColor[1], cachedColor[2], cachedColor[3] = filter[1], filter[2], filter[3]
        cachedColorResults = {}
    end

    local squaredDistance = 10000 -- =100*100 needs probably more fine tuning
    local mountColors = ColorsDB[mountID]
    if mountColors then
        for _, mountColor in pairs(mountColors) do
            local dr = mountColor[1] - filter[1]
            local dg = mountColor[2] - filter[2]
            local db = mountColor[3] - filter[3]

            if (dr * dr) + (dg * dg) + (db * db) <= squaredDistance then
                cachedColorResults[mountID] = true
                return true
            end
        end
    end

    cachedColorResults[mountID] = false
    return false
end

local function CheckAllSettings(settings)
    local allDisabled = true
    local allEnabled = true
    for _, value in pairs(settings) do
        if type(value) == "table" then
            local subResult = CheckAllSettings(value)
            if subResult ~= false then
                allDisabled = false
            end
            if subResult ~= true then
                allEnabled = false
            end
        elseif (value) then
            allDisabled = false
        else
            allEnabled = false
        end

        if allEnabled == false and false == allDisabled then
            break
        end
    end

    if allEnabled then
        return true
    elseif allDisabled then
        return false
    end

    return nil
end

local function CheckMountInList(settings, sourceData, spellId)
    local isInList = false

    for setting, value in pairs(settings) do
        if type(value) == "table" then
            local subResult = CheckMountInList(value, sourceData[setting], spellId)
            if subResult then
                return true
            elseif subResult == false then
                isInList = true
            end
        elseif sourceData[setting] and sourceData[setting][spellId] then
            if (value) then
                return true
            else
                isInList = true
            end
        end
    end

    if isInList then
        return false
    end

    return nil
end

local function prepareSettings(settings, sourceData)

    local result = {}
    for key, sourceList in pairs(sourceData) do
        if settings[key] ~= nil then

            if type(settings[key]) == "table" then
                for subId, subValue in pairs(prepareSettings(settings[key], sourceData[key])) do
                    if not result[subId] then
                        -- if it was somewhere true than keep it true.
                        result[subId] = subValue
                    end
                end
            else
                for id, _ in pairs(sourceList) do
                    if not result[id] then
                        result[id] = settings[key]
                    end
                end
            end
        end
    end

    return result
end

local function FilterByFaction(isFaction, faction)
    return (ADDON.settings.filter.faction.noFaction and not isFaction)
            or (ADDON.settings.filter.faction.alliance and faction == 1)
            or (ADDON.settings.filter.faction.horde and faction == 0)
end

local function FilterBySource(mountId, spellId, sourceType, preparedSettings)
    if preparedSettings[spellId] ~= nil then
        return preparedSettings[spellId]
    end

    local fallback = true
    for source, value in pairs(ADDON.settings.filter.source) do
        if SourceDB[source] and ((
                SourceDB[source]["sourceType"] and tContains(SourceDB[source]["sourceType"], sourceType)
        ) or (
                SourceDB[source]["filterFunc"] and SourceDB[source]["filterFunc"](mountId)
        )) then
            if value then
                SourceDB[source][spellId] = true
                return true
            else
                fallback = false
            end
        end
    end

    return fallback
end

local function FilterByFamily(mountId, preparedSettings)
    if preparedSettings[mountId] ~= nil then
        return preparedSettings[mountId]
    end

    return true
end

local function FilterByExpansion(mountId, preparedSettings)
    if preparedSettings[mountId] ~= nil then
        return preparedSettings[mountId]
    end

    for expansion, value in pairs(ADDON.settings.filter.expansion) do
        if ExpansionDB[expansion] and
                ExpansionDB[expansion]["minID"] <= mountId and
                mountId <= ExpansionDB[expansion]["maxID"] then
            return value
        end
    end

    return false
end

local function FilterByType(mountID, preparedSettings)
    if preparedSettings[mountID] then
        return true
    end

    local _, _, _, isSelfMount, mountType = C_MountJournal.GetMountInfoExtraByID(mountID)

    if ADDON.settings.filter.mountType.transform and isSelfMount then
        return true
    end

    local result
    for category, value in pairs(ADDON.settings.filter.mountType) do
        if TypeDB[category] and
                TypeDB[category].typeIDs and
                tContains(TypeDB[category].typeIDs, mountType) then
            result = result or value
        end
    end

    if result == nil then
        result = true
        if preparedSettings[mountID] ~= nil then
            result = preparedSettings[mountID]
        end
    end

    return result
end

local function FilterByRarity(mountID, allSettings)
    LibMountsRarity = LibMountsRarity or LibStub("MountsRarity-2.0")
    local rarity = LibMountsRarity:GetRarityByID(mountID)

    if rarity == nil then
        return allSettings == false
    end

    return (rarity < 2.0 and ADDON.settings.filter.rarity[Enum.ItemQuality.Legendary])
            or (rarity >= 2.0 and rarity < 10.0 and ADDON.settings.filter.rarity[Enum.ItemQuality.Epic])
            or (rarity >= 10.0 and rarity < 20.0 and ADDON.settings.filter.rarity[Enum.ItemQuality.Rare])
            or (rarity >= 20.0 and rarity < 50.0 and ADDON.settings.filter.rarity[Enum.ItemQuality.Uncommon])
            or (rarity >= 50.0 and ADDON.settings.filter.rarity[Enum.ItemQuality.Common])
end

function ADDON:FilterMounts()
    local result = {}
    local ids = C_MountJournal.GetMountIDs()

    local searchText = MountJournal and MountJournal.searchBox:GetText() or ""
    if searchText ~= "" then
        searchText = searchText:lower()

        for _, mountId in ipairs(ids) do
            local creatureName, _, _, _, _, _, _, _, _, shouldHideOnChar = ADDON.Api:GetMountInfoByID(mountId)
            if FilterIngameHiddenMounts(shouldHideOnChar, mountId) and
                    (
                            FilterByName(searchText, creatureName)
                                or FilterByDescription(searchText, mountId)
                                or FilterByFamilyName(searchText, mountId)
                                or FilterByNote(searchText, mountId)
                    )
            then
                result[#result + 1] = mountId
            end
        end
    else
        local allSettingsSource, preparedSource = CheckAllSettings(ADDON.settings.filter.source)
        if not allSettingsSource then
            preparedSource = prepareSettings(ADDON.settings.filter.source, SourceDB)
        end

        local allSettingsType, preparedTypes = CheckAllSettings(ADDON.settings.filter.mountType)
        if not allSettingsType then
            preparedTypes = prepareSettings(ADDON.settings.filter.mountType, TypeDB)
        end

        local allSettingsFamily, preparedFamily = CheckAllSettings(ADDON.settings.filter.family)
        if not allSettingsFamily then
            preparedFamily = prepareSettings(ADDON.settings.filter.family, FamilyDB)
        end

        local allSettingsExpansion, preparedExpansion = CheckAllSettings(ADDON.settings.filter.expansion)
        if not allSettingsExpansion then
            preparedExpansion = prepareSettings(ADDON.settings.filter.expansion, ExpansionDB)
        end

        local allSettingsRarity = CheckAllSettings(ADDON.settings.filter.rarity)

        for _, mountId in ipairs(ids) do
            local _, spellId, _, _, isUsable, sourceType, _, isFaction, faction, shouldHideOnChar, isCollected = ADDON.Api:GetMountInfoByID(mountId)
            if FilterUserHiddenMounts(spellId)
                    and FilterIngameHiddenMounts(shouldHideOnChar, mountId)
                    and FilterFavoriteMounts(mountId)
                    and FilterUsableMounts(isUsable)
                    and FilterTradableMounts(mountId)
                    and FilterRecentMounts(mountId)
                    and FilterCollectedMounts(isCollected)
                    and FilterByFaction(isFaction, faction)
                    and (allSettingsSource or FilterBySource(mountId, spellId, sourceType, preparedSource))
                    and (allSettingsType or FilterByType(mountId, preparedTypes))
                    and (allSettingsFamily or FilterByFamily(mountId, preparedFamily))
                    and (allSettingsExpansion or FilterByExpansion(mountId, preparedExpansion))
                    and (allSettingsRarity or FilterByRarity(mountId, allSettingsRarity))
                    and FilterByColor(mountId)
            then
                result[#result + 1] = mountId
            end
        end
    end

    -- update data provider
    local dataProvider = ADDON.Api:GetDataProvider()
    if #result == 0 then
        dataProvider:Flush()
    else
        local flippedResult = CopyValuesAsKeys(result)
        local skipAdd = {}
        local toRemove = {}
        dataProvider:ForEach(function(data)
            local resultPosition = flippedResult[data.mountID]
            if resultPosition then
                -- already in provider
                skipAdd[data.mountID] = true
            else
                toRemove[#toRemove + 1] = data
            end
        end)
        if #toRemove > 0 then
            dataProvider:Remove(unpack(toRemove))
        end
        local toAdd = tFilter(result, function(mountId)
            return not skipAdd[mountId]
        end, true)
        if #toAdd > 0 then
            for i, mountId in ipairs(toAdd) do
                toAdd[i] = { index = mountId, mountID = mountId }
            end
            dataProvider:InsertTable(toAdd)
        end
    end

    return result
end