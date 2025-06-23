local _, ADDON = ...

local function CreateSortRadio(root, text, sortValue)
    local sortSettings = ADDON.settings.sort

    return root:CreateRadio(text, function()
        return sortSettings.by == sortValue
    end, function()
        sortSettings["by"] = sortValue
        ADDON.Api:GetDataProvider():Sort()

        return MenuResponse.Refresh
    end)
end

local function CreateSortCheckbox(root, text, sortKey)
    local sortSettings = ADDON.settings.sort

    return root:CreateCheckbox(text, function()
        return sortSettings[sortKey]
    end, function()
        sortSettings[sortKey] = not sortSettings[sortKey]
        ADDON.Api:GetDataProvider():Sort()

        return MenuResponse.Refresh
    end)
end

function ADDON.UI.FDD:AddSortMenu(root)
    local L = ADDON.L

    CreateSortRadio(root, NAME, 'name')
    CreateSortRadio(root, TYPE, 'type')
    CreateSortRadio(root, L.SORT_BY_FAMILY, 'family')
    CreateSortRadio(root, EXPANSION_FILTER_TEXT, 'expansion')
    if ADDON.isRetail then
        CreateSortRadio(root, RARITY, 'rarity')
    end

    CreateSortRadio(root, L.SORT_BY_USAGE_COUNT, 'usage_count'):SetEnabled(function() return ADDON.settings.trackUsageStats end)
    CreateSortRadio(root, L.SORT_BY_LAST_USAGE, 'last_usage'):SetEnabled(function() return ADDON.settings.trackUsageStats end)
    CreateSortRadio(root, L.SORT_BY_LEARNED_DATE, 'learned_date'):SetEnabled(function() return ADDON.settings.trackUsageStats end)
    CreateSortRadio(root, L.SORT_BY_TRAVEL_DURATION, 'travel_duration'):SetEnabled(function() return ADDON.settings.trackUsageStats end)
    CreateSortRadio(root, L.SORT_BY_TRAVEL_DISTANCE, 'travel_distance'):SetEnabled(function() return ADDON.settings.trackUsageStats end)

    root:CreateSpacer()
    CreateSortCheckbox(root, L.SORT_REVERSE, 'descending')
    CreateSortCheckbox(root, L.SORT_FAVORITES_FIRST, 'favoritesOnTop')
    CreateSortCheckbox(root, L.SORT_UNUSABLE_BOTTOM, 'unusableToBottom')
    CreateSortCheckbox(root, L.SORT_UNOWNED_BOTTOM, 'unownedOnBottom')
    root:CreateSpacer()

    ADDON.UI:CenterDropdownButton(root:CreateButton(NEWBIE_TOOLTIP_STOPWATCH_RESETBUTTON, function()
        ADDON:ResetSortSettings()
        ADDON.Api:GetDataProvider():Sort()

        return MenuResponse.CloseAll
    end))
end