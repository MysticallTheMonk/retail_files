local _, ADDON = ...

local eventProfile = {
    filter = {
        source = {
            ["World Event"] = {
                ["Remix: Legion"] = true
            }
        }
    },
    sort = {},
    search = "",
}

local function save(id)
    local profile = ADDON.settings.filterProfile[id]
    profile.sort = CopyTable(ADDON.settings.sort)
    profile.filter = CopyTable(ADDON.settings.filter)
    profile.search = MountJournal.searchBox:GetText()
end

local function mergeRecursive(source, target)
    for k, v in pairs(source) do
        if target[k] ~= nil then
            if type(target[k]) == "table" and type(v) == "table" then
                mergeRecursive(v, target[k])
            else
                target[k] = v
            end
        end
    end
end

local function load(id)
    ADDON:ResetSortSettings()
    ADDON:ResetFilterSettings()

    local profile = type(id) == "number" and ADDON.settings.filterProfile[id] or eventProfile
    mergeRecursive(profile.sort, ADDON.settings.sort)
    mergeRecursive(profile.filter, ADDON.settings.filter)

    MountJournal.searchBox:SetText(profile.search)
end

function ADDON.UI.FDD:AddProfiles(root)

    local icons = {
        456034, -- raidtarget_square
        456036, -- raidtarget_triangle
        456038, -- raidtarget_diamond
        456040, -- raidtarget_x
        456042, -- raidtarget_star
    }
    --if ADDON.isRetail and time() < 1768896000 then -- 2026-01-20 08:00
    --    icons["remix"] = 1380366 -- ability_demonhunter_eyeofleotheras
    --end

    local profileButtons = {}
    local element = root:CreateTitle(ADDON.L.FILTER_PROFILE, WHITE_FONT_COLOR)
    element:AddInitializer(function(button, elementDescription, menu)

        MenuVariants.CreateHighlight(button)
        local fontHeight = button.fontString:GetHeight()

        profileButtons = {}
        for id, icon in pairs(icons) do
            -- checkbutton?
            local profileButton = button:AttachTemplate("WowMenuAutoHideButtonTemplate")
            profileButton.Texture:SetTexture(icon)
            profileButton:SetSize(fontHeight-2, fontHeight-2)
            profileButton:SetFrameStrata(button:GetFrameStrata())

            profileButton:RegisterForClicks("AnyUp")

            profileButton:SetScript("OnClick", function(_, mouseButton)
                if type(id) == "number" and mouseButton == "RightButton" then
                    save(id)
                    -- flash/animate?
                else
                    load(id)
                    ADDON:FilterMounts()
                    ADDON.Api:GetDataProvider():Sort()
                    menu:SendResponse(elementDescription, MenuResponse.Close)
                end
            end)
            profileButton:SetScript("OnEnter", function(self)
                button.highlight:ClearAllPoints()
                button.highlight:SetSize(fontHeight+2, fontHeight)
                button.highlight:SetPoint("CENTER", self, "CENTER", 0, 0)
                button.highlight:Show()

                GameTooltip:SetOwner(button, "ANCHOR_NONE")
                GameTooltip:SetPoint("LEFT", button, "RIGHT")
                GameTooltip:ClearLines()
                GameTooltip_SetTitle(GameTooltip, ADDON.L.FILTER_PROFILE_TOOLTIP_TITLE)
                GameTooltip:AddLine(ADDON.L.FILTER_PROFILE_TOOLTIP_TEXT)
                GameTooltip:Show()
            end)
            profileButton:SetScript("OnLeave", function()
                button.highlight:Hide()
            end)

            profileButton:ClearAllPoints()
            profileButtons[#profileButtons+1] = profileButton
        end

        local yOffset = -7
        if #profileButtons > 5 then
            yOffset = -3
        end

        profileButtons[#profileButtons]:SetPoint("RIGHT")
        for i = #profileButtons-1, 1, -1 do
            profileButtons[i]:SetPoint("RIGHT", (#profileButtons -i)*(yOffset-fontHeight-2), 0)
        end
    end)
    element:AddResetter(function(self)
        self.highlight:SetSize(0, 0)
        self.highlight:SetBlendMode("DISABLE")
        self.highlight:ClearAllPoints()
        self.highlight = nil
        for _, profileButton in pairs(profileButtons) do
            profileButton.Texture:SetTexture()
            profileButton:SetSize(0,0)
            profileButton:ClearAllPoints()
            profileButton:RegisterForClicks("LeftButtonUp")
            profileButton:SetScript("OnClick", nil)
            profileButton:SetScript("OnEnter", nil)
            profileButton:SetScript("OnLeave", nil)
        end
    end)

end

local function prepareEventProfile()
    for categoryName, _ in pairs(ADDON.DB.Source) do
        if nil == eventProfile.filter.source[categoryName] then
            eventProfile.filter.source[categoryName] = false
        end
    end
    if false == eventProfile.filter.source["World Event"] then
        eventProfile.filter.source["World Event"] = {}
    end
    for categoryName, _ in pairs(ADDON.DB.Source["World Event"]) do
        if not eventProfile.filter.source["World Event"][categoryName] then
            eventProfile.filter.source["World Event"][categoryName] = false
        end
    end
end

--ADDON.Events:RegisterCallback("loadUI", function(self)
--    prepareEventProfile()
--end, "detect remix")