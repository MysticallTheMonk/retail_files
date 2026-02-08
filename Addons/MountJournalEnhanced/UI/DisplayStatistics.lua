local ADDON_NAME, ADDON = ...

local tooltip
local LibMountsRarity

do
    local options = {
        CustomizationCount = ADDON.L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"],
        UsedCount = ADDON.L["STATS_TIP_USAGE_COUNT_HEAD"],
        TravelTime = ADDON.L["STATS_TIP_TRAVEL_TIME_HEAD"],
        TravelDistance = ADDON.L["STATS_TIP_TRAVEL_DISTANCE_HEAD"],
        LearnedDate = ADDON.L["STATS_TIP_LEARNED_DATE_HEAD"],
        Rarity = ADDON.L["STATS_TIP_RARITY_HEAD"],
        Family = ADDON.L["Family"],
        Wowhead = ADDON.L["LINK_WOWHEAD"],
    }

    if ADDON.isClassic then
        options.CustomizationCount = nil
        options.Rarity = nil
    end
    local defaults = CopyTable(options)
    for key in pairs(defaults) do
        defaults[key] = true
    end
    ADDON:RegisterUISetting('displayStatistics',
            defaults,
            ADDON.L.SETTING_SHOW_DATA,
            function()
                if ADDON.initialized then
                    MountJournal_UpdateMountDisplay(true)
                end
            end,
            options
    )
    ADDON:RegisterSettingDisabledCheck('displayStatistics', function(option)
        if option == 'UsedCount' or option == 'TravelTime' or option == 'TravelDistance' or option == 'LearnedDate' then
            return not ADDON.settings.trackUsageStats
        end

        return false
    end)
end

local function buildStat(container, iconTexture, tooltipHead, tooltipText)
    local item = CreateFrame("frame", nil, container)

    local icon = item:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(iconTexture)
    if type(iconTexture) == "string" then
        icon:SetAtlas(iconTexture)
    end
    icon:SetSize(12, 12)
    icon:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
    item.Icon = icon

    local text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", icon, "TOPRIGHT", 2, 0)
    item.Text = text

    item:SetHeight(12)

    item.TooltipText = tooltipText
    item:HookScript("OnEnter", function(self)
        tooltip:SetOwner(self, "ANCHOR_TOP")
        tooltip:SetText(tooltipHead, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
        if item.TooltipText then
            tooltip:AddLine(item.TooltipText)
        end
        tooltip:Show()
    end)
    item:HookScript("OnLeave", function()
        tooltip:Hide()
    end)

    return item
end

local function setupContainer()

    local L = ADDON.L
    local infoButton = MountJournal.MountDisplay.InfoButton

    local container = CreateFrame("Frame", nil, infoButton)
    container:SetPoint("TOPLEFT", infoButton.Icon, "BOTTOMLEFT", 0, -5)
    container:SetPoint("RIGHT", MountJournal.MountDisplay, "RIGHT", -26, 0)
    container:SetHeight(12)

    tooltip = CreateFrame("GameTooltip", "MJEStatisticsHelpToolTip", container, "SharedNoHeaderTooltipTemplate")

    ADDON.UI:SavePoint(infoButton.Source)
    container:HookScript("OnShow", function()
        infoButton.Source:ClearAllPoints()
        infoButton.Source:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, 0)
    end)
    container:HookScript("OnHide", function()
        ADDON.UI:RestorePoint(infoButton.Source)
    end)

    container.CustomizationCount = buildStat(container,
            0,
            L["STATS_TIP_CUSTOMIZATION_COUNT_HEAD"]
    )
    container.CustomizationCount.Icon:SetAtlas("colorblind-colorwheel")

    container.UsedCount = buildStat(container,
            397908, -- interface/levelup/leveluptex
            L["STATS_TIP_USAGE_COUNT_HEAD"]
    )
    container.UsedCount.Icon:SetTexCoord(0.720703125, 0.78125, 0.03515625, 0.1015625)
    container.TravelTime = buildStat(container,
            136106, -- spell_nature_timestop
            L["STATS_TIP_TRAVEL_TIME_HEAD"],
            L["STATS_TIP_TRAVEL_TIME_TEXT"]
    )
    container.TravelDistance = buildStat(container,
            132120, -- ability_druid_dash
            L["STATS_TIP_TRAVEL_DISTANCE_HEAD"]
    )
    container.LearnedDate = buildStat(container,
            0,
            L["STATS_TIP_LEARNED_DATE_HEAD"]
    )
    container.LearnedDate.Icon:SetAtlas("auctionhouse-icon-checkmark")

    container.Rarity = buildStat(container,
            134071, -- interface/icons/inv_misc_gem_01
            L["STATS_TIP_RARITY_HEAD"],
            L["STATS_TIP_RARITY_DESCRIPTION"]
    )
    container.Family1 = buildStat(container,
            132834, -- interface/icons/inv_egg_03
            L["Family"]
    )
    container.Family2 = buildStat(container,
            132834, -- interface/icons/inv_egg_03
            L["Family"]
    )
    container.Wowhead = buildStat(container,
            "Interface\\Addons\\MountJournalEnhanced\\UI\\icons\\wowhead.png",
            L["LINK_WOWHEAD"],
            L["CLICK_TO_SHOW_LINK"]
    )
    container.Wowhead:HookScript("OnMouseUp", function()
        local mountId = ADDON.Api:GetSelected()
        local _, spellId = C_MountJournal.GetMountInfoByID(mountId)
        local lang
        local locale = GetLocale()
        if locale == "zhTW" or locale == "zhCN" then
            lang = "cn"
        else
            lang = strsub(locale, 1, 2)
        end
        if  WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
            lang = "cata/"..lang
        elseif  WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC then
            lang = "mop-classic/"..lang
        end

        LibStub("LibCopyDialog"):Open("https://www.wowhead.com/"..lang.."/spell="..spellId)
    end)

    container.Items = {
        container.CustomizationCount,
        container.UsedCount,
        container.TravelTime,
        container.TravelDistance,
        container.LearnedDate,
        container.Rarity,
        container.Family1,
        container.Family2,
        container.Wowhead,
    }

    container:Hide()

    return container
end

local function formatDistance(length)
    if ADDON.isMetric then
        length = length / 1.0936
        if length < 1000 then
            return floor(length) .. ' m';
        end
        return floor(length / 1000) .. ' km';
    else
        if length < 1760 then
            return floor(length) .. ' yd';
        end
        return floor(length / 1760) .. ' mi';
    end
end

local function parseCustomization(mountData)
    local count = 0
    local total = 0

    if mountData["quest"] then
        total = total + #mountData["quest"]
        for _, questId in ipairs(mountData["quest"]) do
            if C_QuestLog.IsQuestFlaggedCompleted(questId)
                or (C_QuestLog.IsQuestFlaggedCompletedOnAccount and C_QuestLog.IsQuestFlaggedCompletedOnAccount(questId))
            then
                count = count + 1
            end
        end
    end
    if mountData["achievement"] then
        total = total + #mountData["achievement"]
        for _, achievementId in ipairs(mountData["achievement"]) do
            if select(4, GetAchievementInfo(achievementId)) then
                count = count + 1
            end
        end
    end

    return count .. "/" .. total
end

local function buildFamilyStrings(mountId)
    local result = {}

    for mainFamily, values in pairs(ADDON.DB.Family) do
        if values[mountId] then
            result[#result + 1] = ADDON.L[mainFamily] or mainFamily
        end
        local firstKey = next(values)
        if type(firstKey) == "string" then
            for subFamily, subValues in pairs(values) do
                if subValues[mountId] then
                    result[#result + 1] = (ADDON.L[mainFamily] or mainFamily) .. " / " .. (ADDON.L[subFamily] or subFamily)
                end
            end
        end
        if #result == 2 then
            break
        end
    end

    return result[1] or nil, result[2] or nil
end

local function updateContainer(mountId, container)
    local settings = ADDON.settings.ui.displayStatistics
    local trackingEnabled = ADDON.settings.trackUsageStats

    container.CustomizationCount:SetShown(settings.CustomizationCount and ADDON.DB.Customization[mountId] ~= nil)
    if container.CustomizationCount:IsShown() then
        container.CustomizationCount.Text:SetText(parseCustomization(ADDON.DB.Customization[mountId]))
    end

    local useCount, travelTime, travelDistance, learnedTime
    if trackingEnabled then
        useCount, _, travelTime, travelDistance, learnedTime = ADDON:GetMountStatistics(mountId)
    end

    container.UsedCount:SetShown(trackingEnabled and settings.UsedCount and useCount > 0)
    if container.UsedCount:IsShown() then
        container.UsedCount.Text:SetText(useCount .. ' x')
    end

    container.TravelTime:SetShown(trackingEnabled and settings.TravelTime and travelTime > 0)
    if container.TravelTime:IsShown() then
        if travelTime >= SECONDS_PER_DAY then
            container.TravelTime.TooltipText = ADDON.L["STATS_TIP_TRAVEL_TIME_DAYS"]
            container.TravelTime.Text:SetText(string.format("%.1fd", travelTime / SECONDS_PER_DAY))
        else
            container.TravelTime.TooltipText = ADDON.L["STATS_TIP_TRAVEL_TIME_TEXT"]
            container.TravelTime.Text:SetText(SecondsToClock(travelTime, true))
        end
    end

    container.TravelDistance:SetShown(trackingEnabled and settings.TravelDistance and travelDistance > 0)
    if container.TravelDistance:IsShown() then
        container.TravelDistance.Text:SetText(formatDistance(travelDistance))
    end

    container.LearnedDate:SetShown(trackingEnabled and settings.LearnedDate and learnedTime ~= nil)
    if container.LearnedDate:IsShown() then
        local data = date('*t', learnedTime)
        container.LearnedDate.Text:SetText(FormatShortDate(data.day, data.month, data.year))
    end

    container.Rarity:Hide()
    if ADDON.isRetail and settings.Rarity then
        LibMountsRarity = LibMountsRarity or LibStub("MountsRarity-2.0")
        local rarity = LibMountsRarity:GetRarityByID(mountId)
        if rarity ~= nil then
            container.Rarity:Show()
            container.Rarity.Text:SetText(string.format("%.2f %%", rarity))
        end
    end

    container.Family1:Hide()
    container.Family2:Hide()
    if settings.Family then
        local mountFamily1, mountFamily2 = buildFamilyStrings(mountId)
        container.Family1:SetShown(mountFamily1 ~= nil)
        if mountFamily1 then
            container.Family1.Text:SetText(mountFamily1)
        end
        container.Family2:SetShown(mountFamily2 ~= nil)
        if mountFamily2 then
            container.Family2.Text:SetText(mountFamily2)
        end
    end

    container.Wowhead:SetShown(trackingEnabled and settings.Wowhead)

    local maxWidth = MountJournal.MountDisplay:GetWidth() - 52
    local rowWidth = 0
    local rowLead
    local rowPrevious
    local rowCount = 0
    for _, stat in ipairs(container.Items) do
        if stat:IsShown() then
            stat:SetWidth(stat.Text:GetUnboundedStringWidth() + 14)
            stat:ClearAllPoints()
            rowWidth = rowWidth + 7 + stat:GetWidth()
            if maxWidth < rowWidth or rowLead == nil then
                rowWidth = stat:GetWidth()
                rowCount = rowCount + 1
                rowLead = stat
            else
                stat:SetPoint("LEFT", rowPrevious, "RIGHT", 7, 0)
            end
            rowLead:SetPoint("TOPLEFT", container, "TOP", -(rowWidth / 2), (rowCount - 1) * -12)
            rowPrevious = stat
        end
    end
    container:SetHeight(12 * rowCount)
    container:SetShown(rowCount > 0)
end

ADDON.Events:RegisterCallback("loadUI", function()
    local container

    local callback = function()
        if not container then
            container = setupContainer()
        end

        local selectedMount = ADDON.Api:GetSelected()
        if selectedMount then
            if 0 == MountJournal.MountDisplay:GetWidth() then
                C_Timer.After(0, function()
                    updateContainer(selectedMount, container)
                end)
            else
                updateContainer(selectedMount, container)
            end
        else
            container:Hide();
        end
    end
    ADDON.Events:RegisterCallback("OnUpdateMountDisplay", callback, ADDON_NAME .. 'DisplayStatistics')
    CollectionsJournal:HookScript("OnSizeChanged", function()
        if CollectionsJournal:IsResizable() and CollectionsJournal.selectedTab == COLLECTIONS_JOURNAL_TAB_INDEX_MOUNTS then
            callback()
        end
    end)
end, "display statistics")