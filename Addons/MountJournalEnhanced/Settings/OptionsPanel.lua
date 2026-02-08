local ADDON_NAME, ADDON = ...

local AceGUI = LibStub("AceGUI-3.0")

local mainCategory

function ADDON:OpenOptions()
    mainCategory.expanded = true
    Settings.OpenToCategory(mainCategory.ID)
end

local function BuildCheckBox(parent, text)
    local button = AceGUI:Create("CheckBox")
    button:SetLabel(text)
    button:SetFullWidth(true)
    parent:AddChild(button)

    return button
end
local function BuildDropDown(parent, text, options, isMultiOptions, parentSetting)
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetFullWidth(true)

    local label = AceGUI:Create("Label")
    label:SetFontObject(GameFontHighlight)
    label:SetText(text)
    label:SetWidth(400)
    group:AddChild(label)

    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetMultiselect(isMultiOptions)
    for option, optionLabel in pairs(options) do
        dropdown:AddItem(option, optionLabel)
        dropdown:SetItemDisabled(option, ADDON:IsSettingDisabled(parentSetting, option))
    end
    group:AddChild(dropdown)
    parent:AddChild(group)

    return dropdown
end
local function BuildHeading(parent, text)
    local head = AceGUI:Create("Heading")
    head:SetText(text)
    head:SetFullWidth(true)
    head:SetHeight(35)
    parent:AddChild(head)

    return head
end

local function BuildMainFrame(uiLabels, behaviourLabels)
    local title = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title")
    local frame = AceGUI:Create("BlizOptionsGroup")
    frame:SetName(title)
    frame:SetTitle(title)

    local scroll = AceGUI:Create("ScrollFrame")
    frame:SetLayout("fill")
    frame:AddChild(scroll)

    frame.checks = {}

    BuildHeading(scroll, UIOPTIONS_MENU)

    for _, labelData in ipairs(uiLabels) do
        local setting, label, options, isMultiOptions = labelData[1], labelData[2], labelData[3], labelData[4]
        if ADDON.settings.ui[setting] ~= nil then
            if options then
                frame.checks[setting] = BuildDropDown(scroll, label, options, isMultiOptions, setting)
            else
                frame.checks[setting] = BuildCheckBox(scroll, label)
            end
        end
    end

    BuildHeading(scroll, ADDON.L.SETTING_HEAD_BEHAVIOUR)

    for _, labelData in ipairs(behaviourLabels) do
        local setting, label = labelData[1], labelData[2]
        if (ADDON.settings[setting] ~= nil) then
            frame.checks[setting] = BuildCheckBox(scroll, label)
        end
    end

    return frame
end

local function BildAbout()

    local frame = AceGUI:Create("BlizOptionsGroup")
    frame:SetName(ADDON.L["SETTING_HEAD_ABOUT"], C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title"))
    frame:SetTitle(ADDON.L["SETTING_HEAD_ABOUT"])
    frame:SetLayout("List")
    frame.content:SetPoint("TOPLEFT", 20, -50)
    frame.content:SetPoint("BOTTOMRIGHT", -20, 10)

    local link = function(url, text, icon)
        icon = icon and "|TInterface\\Addons\\MountJournalEnhanced\\UI\\icons\\" .. icon .. ":0|t " or ""

        return "|cff56B0FF|Haddon:LibCopyDialog:" .. url .. "|h" .. icon .. "[" .. text .. "]|h|r"
    end

    local buildLabel = function(text)
        local label = AceGUI:Create("InteractiveLabel")
        label:SetFontObject(GameFontHighlight)
        label:SetText(text)
        label:SetFullWidth(true)
        label.frame:SetHyperlinksEnabled(true)
        label.frame:SetScript("OnHyperlinkClick", InlineHyperlinkFrame_OnClick)

        frame:AddChild(label)
    end

    buildLabel("|cffffd100" .. GAME_VERSION_LABEL .. ":|r " .. C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") .. "\n\n")
    buildLabel("|cffffd100" .. ADDON.L["SETTING_ABOUT_AUTHOR"] .. ":|r " .. C_AddOns.GetAddOnMetadata(ADDON_NAME, "Author") .. "\n\n")
    buildLabel("Have you found any bug or do you have some suggestions? Please let me know in the issue tracker on "
            .. link("https://www.curseforge.com/wow/addons/mount-journal-enhanced/issues", "Curseforge") .. " or "
            .. link("https://github.com/exochron/MountJournalEnhanced/issues", "GitHub") .. ".")
    buildLabel("Is your language still missing some texts? You can help to localize this addon into your language on "
            .. link("https://www.curseforge.com/wow/addons/mount-journal-enhanced/localization", "Curseforge") .. ".")

    BuildHeading(frame, "Acknowledgments")
    buildLabel("First of all I would like to thank my dear friend. He initially started Mount Journal Enhanced. This addon wouldn't exist without him." .. "\n\n")
    buildLabel("Furthermore I'd like to thank all contributors, translators, feedback and idea givers. Your help is really very much appreciated." .. "\n\n")

    buildLabel("Besides, it is important to give a special thank you to some community projects and websites. Without whose preliminary work it would be much harder to develop this addon.\n\n")
    if ADDON.isRetail then
        buildLabel("- " .. link("https://www.dataforazeroth.com", "Data for Azeroth", "dfa.png") .. " and " .. link("https://www.curseforge.com/wow/addons/mountsrarity", "MountsRarity") .." for providing mount rarity percentages.")
    end
    buildLabel("- " .. link("https://www.warcraftmounts.com", "Warcraft Mounts", "warcraftmounts.png") .. " for their comprehensive family gallery.")
    buildLabel("- " .. link("https://www.townlong-yak.com/framexml/live", "Townlong Yak", "townlong_yak.png") .. ", "
            .. link("https://wago.tools", "Wago Tools")
            .. " and the " .. link("https://wowdev.wiki", "WoWDev wiki", "wowdev.png")
            .. " for their awesome developer resources.")
    buildLabel("- The " .. link("https://warcraft.wiki.gg/wiki/Warcraft_Wiki", "WarCraft Wiki") .. " for documenting WoWs API and providing the expansion icons.")
    buildLabel("- Marlamin for continuing with " .. link("https://github.com/Marlamin/wow.tools.local", "wow.tools.local") .. ".")
    buildLabel("- foxlit for " .. link("https://www.townlong-yak.com/addons/taintless", "TaintLess") .. ". This great little library is (sadly) essential for any bugless addon or client.")
    buildLabel("- The Team of " .. link("https://www.wowace.com/projects/ace3", "Ace3") .. " for their developer friendly framework.")
    buildLabel("- " .. link("https://www.wowace.com/projects/herebedragons", "HereBeDragons") .. " for providing a nice api to keep track of the player position.")
    buildLabel("- The " .. link("https://github.com/BigWigsMods/packager", "packager by BigWigsMods") .. " which makes releasing new versions as simple as possible.")
    buildLabel("- " .. link("https://www.jetbrains.com/", "JetBrains") .. " for providing me with a licence of their great IDEs.")

    buildLabel("\n" .. "Last but not least I'd like to thank YOU for using Mount Journal Enhanced. If you like it, you should show it to your friends and guild mates. So they can enjoy it as well. :-)")
    buildLabel("\n\n\n") -- add some space for copybox

    return frame
end

ADDON.Events:RegisterCallback("OnLogin", function()
    local uiLabels, behaviourLabels = ADDON:GetSettingLabels()

    local group = BuildMainFrame(uiLabels, behaviourLabels)
    for _, check in pairs(group.checks) do
        check:SetCallback("OnValueChanged", function()
            group:Fire("okay")
            group:Fire("refresh")
        end)
    end
    group:SetCallback("refresh", function(frame)
        for _, labelData in ipairs(uiLabels) do
            local setting, isMultiOptions = labelData[1], labelData[4]
            local check = frame.checks[setting]
            if check then
                if isMultiOptions then
                    for subSetting, value in pairs(ADDON.settings.ui[setting]) do
                        check:SetItemValue(subSetting, value)
                        check:SetItemDisabled(subSetting, ADDON:IsSettingDisabled(setting, subSetting))
                    end
                else
                    check:SetValue(ADDON.settings.ui[setting])
                    check:SetDisabled(ADDON:IsSettingDisabled(setting))
                end
            end
        end
        for _, labelData in ipairs(behaviourLabels) do
            local setting = labelData[1]
            if frame.checks[setting] then
                frame.checks[setting]:SetValue(ADDON.settings[setting])
                frame.checks[setting]:SetDisabled(ADDON:IsSettingDisabled(setting))
            end
        end
    end)
    group:SetCallback("okay", function(frame)
        for _, labelData in ipairs(uiLabels) do
            local setting, isMultiOptions = labelData[1], labelData[4]
            if frame.checks[setting] then
                if isMultiOptions then
                    local values = {}
                    for _, widget in pairs(frame.checks[setting].pullout.items) do
                        if widget.userdata and widget.userdata.value then
                            values[widget.userdata.value] = widget:GetValue()
                        end
                    end
                    ADDON:ApplySetting(setting, values)
                else
                    ADDON:ApplySetting(setting, frame.checks[setting]:GetValue())
                end
            end
        end
        for _, labelData in ipairs(behaviourLabels) do
            local setting = labelData[1]
            if frame.checks[setting] then
                ADDON:ApplySetting(setting, frame.checks[setting]:GetValue())
            end
        end
    end)
    group:SetCallback("default", ADDON.ResetSettings)

    mainCategory = Settings.RegisterCanvasLayoutCategory(group.frame, C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title"));

    Settings.RegisterAddOnCategory(mainCategory)
    Settings.RegisterCanvasLayoutSubcategory(mainCategory, BildAbout().frame, ADDON.L.SETTING_HEAD_ABOUT)

end, "settings panel")