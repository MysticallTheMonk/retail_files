local _, ADDON = ...

local function updateSourceText(replace, sourceText)
    sourceText = sourceText:gsub("[|]n$","") -- trim trailing new line
    sourceText = sourceText:gsub("[|]n$","") -- sometimes with added blank line

    local text, count = sourceText:gsub(":%s?|r%s?[^|]+|n", ":|r "..replace.."|n", 1)
    if count == 0 then
        text = sourceText:gsub(":%s?|r%s?[^|]+$", ":|r "..replace, 1)
    end
    MountJournal.MountDisplay.InfoButton.Source:SetText(text)
end

local function replaceTextWithLinks()
    local mountId = ADDON.Api:GetSelected()
    local _, spellId, _, _, _, sourceType = C_MountJournal.GetMountInfoByID(mountId)

    local achievementIds = ADDON.DB.Source.Achievement[spellId] or ADDON.DB.FeatsOfStrength[mountId]
    if achievementIds and achievementIds ~= true then
        if type(achievementIds)=="number" then
            achievementIds = {achievementIds}
        end
        local _, _, sourceText = C_MountJournal.GetMountInfoExtraByID(mountId)

        for _, achievementId in ipairs(achievementIds) do
            local link = GetAchievementLink(achievementId)
            if link then
                if sourceType == 6 then
                    updateSourceText(link, sourceText)
                    break
                else
                    local _, name = GetAchievementInfo(achievementId)
                    if name then
                        if ADDON.isClassic and "" == sourceText then
                            sourceText = "|cffffd200"..BATTLE_PET_SOURCE_6..":|r "..link
                        else
                            name = name:gsub("([()-])", "%%%1")
                            sourceText = sourceText:gsub(name, link, 1)
                        end

                        MountJournal.MountDisplay.InfoButton.Source:SetText(sourceText)
                        break
                    end
                end
            end
        end
    elseif ADDON.isRetail and ADDON.DB.Source.Drop[spellId] and ADDON.DB.Source.Drop[spellId] ~= true then
        -- no map pins in classic yet
        local _, _, sourceText = C_MountJournal.GetMountInfoExtraByID(mountId)
        local mapId = ADDON.DB.Source.Drop[spellId][1]
        local x = ADDON.DB.Source.Drop[spellId][2]
        local y = ADDON.DB.Source.Drop[spellId][3]
        if mapId and x ~= nil and y ~= nil then
            local link = " |cffffff00|Hworldmap:"..mapId..":"..x..":"..y.."|h[|A:Waypoint-MapPin-ChatIcon:13:13:0:0|a]|h|r"

            local text, count = sourceText:gsub("|n", link.."|n", 1)
            if count == 0 then
                text = text..link
            end
            MountJournal.MountDisplay.InfoButton.Source:SetText(text)
        end

    elseif ADDON.DB.Source.Instance[spellId] and ADDON.DB.Source.Instance[spellId] ~= true then
        -- no encounter links in classic yet
        local _, _, sourceText = C_MountJournal.GetMountInfoExtraByID(mountId)
        local encounterId = ADDON.DB.Source.Instance[spellId][1]
        local difficultyId = ADDON.DB.Source.Instance[spellId][2]
        local name = EJ_GetEncounterInfo(encounterId)
        if name then
            local link = C_EncounterJournal.GetEncounterJournalLink(1, encounterId, name, difficultyId)
            updateSourceText(link, sourceText)
        end
    elseif ADDON.DB.Source.Shop[spellId] or sourceType == 10 then
        -- https://warcraft.wiki.gg/wiki/Hyperlinks#storecategory can only open to certain categories. mounts are not among them yet. (see: SetItemRef)
        local text = "|cffffd000|Hstorecategory:services|h["..BATTLE_PET_SOURCE_10.."]|h|r"
        MountJournal.MountDisplay.InfoButton.Source:SetText(text)
    end
end

ADDON.Events:RegisterCallback("OnUpdateMountDisplay", replaceTextWithLinks, 'ReplaceText')
