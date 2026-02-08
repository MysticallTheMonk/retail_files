local _, LRP = ...

function LRP:CreateProfileDropdown(parent, OnValueChanged)
    local sortedProfileNames = {}
    local selectedProfile
    local width, height = 150, 24

    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")

    dropdown:SetSize(width, height)

    -- Tooltip purposes
    dropdown.OnEnter = function() end
    dropdown.OnLeave = function() end

    dropdown:SetScript("OnEnter", function(_self) _self.OnEnter() end)
    dropdown:SetScript("OnLeave", function(_self) _self.OnLeave() end)

    local function IsSelected(profileName)
        return profileName == selectedProfile
    end

    local function SetSelected(profileName)
        selectedProfile = profileName

        OnValueChanged(profileName)
    end

    local function MakeEntry(parentButton, profileName)
        local button = parentButton:CreateRadio(profileName, IsSelected, SetSelected, profileName)

        button:AddInitializer(
            function(_button)
                -- Text
                local fontString = _button.fontString

                fontString:SetFontObject(LRFont13)

                -- Delete button
                local deleteButton = _button:AttachFrame("Button")

                deleteButton:SetSize(15, 15)
                deleteButton:SetPoint("RIGHT", _button, "RIGHT")
                deleteButton:SetNormalAtlas("common-icon-redx")
                deleteButton:SetHighlightAtlas("common-icon-redx", "ADD")

                LRP:AddTooltip(deleteButton, "Delete")

                deleteButton:SetScript(
                    "OnClick",
                    function()
                        local timelineInfo = LRP:GetCurrentTimelineInfo()
                        local encounterID = timelineInfo.encounterID
                        local difficulty = timelineInfo.difficulty
                        local currentProfile = timelineInfo.profile
                        local reminders = timelineInfo.reminders
                        local reminderCount = 0

                        for _ in pairs(reminders) do
                            reminderCount = reminderCount + 1
                        end

                        local function DeleteProfile()
                            LiquidRemindersSaved.reminders[encounterID][difficulty][profileName] = nil

                            -- If we deleted the last available profile, create an empty profile
                            if not next(LiquidRemindersSaved.reminders[encounterID][difficulty]) then
                                LiquidRemindersSaved.reminders[encounterID][difficulty]["Default profile"] = {}
                            end

                            -- If we deleted the profile that we're currently viewing, select a random other profile
                            if profileName == currentProfile then
                                dropdown:SetValue(next(LiquidRemindersSaved.reminders[encounterID][difficulty]))
                            else
                                dropdown:GenerateMenu()
                            end
                        end

                        if reminderCount == 0 then -- If this profile has no reminders, delete it without confirmation
                            DeleteProfile()
                        else
                            LRP.reminderConfig:Hide()
                            LRP.importExportWindow:Hide()
                            
                            LRP:ShowConfirmWindow(
                                LRP.window,
                                string.format("Are you sure you want to delete %s?|n|nThis profile contains %d |4reminder:reminders;.", profileName, reminderCount),
                                DeleteProfile
                            )
                        end
                    end
                )

                -- Settings button
                local settingsButton = _button:AttachFrame("Button")

                settingsButton:SetSize(17, 17)
                settingsButton:SetPoint("RIGHT", deleteButton, "LEFT")
                settingsButton:SetNormalAtlas("mechagon-projects")
                settingsButton:SetHighlightAtlas("mechagon-projects", "ADD")

                LRP:AddTooltip(settingsButton, "Settings")

                settingsButton:SetScript(
                    "OnClick",
                    function()
                        LRP:ShowProfileWindow(LRP.window, profileName)

                        dropdown:CloseMenu()
                    end
                )
                
                -- Calculate size
                local padding = 16
                local buttonWidth = padding + fontString:GetUnboundedStringWidth() + deleteButton:GetWidth() + settingsButton:GetWidth()

                return buttonWidth, 20
            end
        )
    end

    function dropdown:SetValue(profileName)
        SetSelected(profileName)

        dropdown:GenerateMenu()
    end

    function dropdown:Rebuild()
        dropdown:SetupMenu(
            function(_, rootNode)
                local timelineInfo = LRP:GetCurrentTimelineInfo()
                local encounterID = timelineInfo.encounterID
                local difficulty = timelineInfo.difficulty
                
                selectedProfile = timelineInfo.profile
                sortedProfileNames = {}

                for profileName in pairs(LiquidRemindersSaved.reminders[encounterID][difficulty]) do
                    table.insert(sortedProfileNames, profileName)
                end

                table.sort(
                    sortedProfileNames,
                    function(name1, name2)
                        name1 = name1:match("^|c%x%x%x%x%x%x%x%x(.+)|r$") or name1
                        name2 = name2:match("^|c%x%x%x%x%x%x%x%x(.+)|r$") or name2

                        name1 = name1:lower()
                        name2 = name2:lower()

                        return name1 < name2
                    end
                )

                for _, profileName in ipairs(sortedProfileNames) do
                    MakeEntry(rootNode, profileName)
                end

                -- Add profile button
                local addProfileButton = rootNode:CreateButton(
                    "Add profile",
                    function()
                        LRP:ShowProfileWindow(LRP.window)
                    end
                )

                addProfileButton:AddInitializer(
                    function(_button)
                        local addProfileIcon = _button:AttachTexture()

                        addProfileIcon:SetSize(12, 12)
                        addProfileIcon:SetDrawLayer("BACKGROUND")
                        addProfileIcon:SetPoint("LEFT", _button, "LEFT")
                        addProfileIcon:SetAtlas("communities-icon-addgroupplus")

                        local fontString = _button.fontString

                        fontString:SetFontObject(LRFont13)
                        fontString:SetPoint("LEFT", addProfileIcon, "RIGHT", 4, 0)
                    end
                )
                
                rootNode:SetScrollMode(20 * 24)
            end
        )
    end

    -- Skinning
    local borderColor = LRP.gs.visual.borderColor

    LRP:AddBorder(dropdown, 1, 0)
    dropdown:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    dropdown.Background:Hide()
    dropdown.Arrow:Hide()

    -- Background
    dropdown.LRBackground = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdown.LRBackground:SetAllPoints(dropdown)
    dropdown.LRBackground:SetColorTexture(0, 0, 0, 0.5)

    -- Arrow
    dropdown.LRArrowFrame = CreateFrame("Frame", nil, dropdown)
    dropdown.LRArrowFrame:SetSize(height, height)
    dropdown.LRArrowFrame:SetPoint("RIGHT")

    dropdown:SetNormalTexture(134532)

    local arrow = dropdown:GetNormalTexture()

    arrow:SetAllPoints(dropdown.LRArrowFrame)

    LRP:AddBorder(dropdown.LRArrowFrame)
    dropdown.LRArrowFrame:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    dropdown:ClearHighlightTexture()
    dropdown:ClearDisabledTexture()

    dropdown:SetNormalTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\ArrowDown.tga")
    dropdown:GetNormalTexture():SetAllPoints(dropdown.LRArrowFrame)

    dropdown:SetPushedTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\ArrowDownPushed.tga")
    dropdown:GetPushedTexture():SetAllPoints(dropdown.LRArrowFrame)

    LRP:AddHoverHighlight(dropdown, dropdown.LRArrowFrame)

    -- Text
    dropdown.Text:AdjustPointsOffset(0, -1)
    dropdown.Text:SetFontObject(LRFont13)

    dropdown.Text:ClearAllPoints()
    dropdown.Text:SetPoint("LEFT", dropdown, "LEFT", 6, 0)
    dropdown.Text:SetPoint("RIGHT", dropdown, "RIGHT", -height - 6, 0)
    dropdown.Text:SetJustifyH("RIGHT")

    dropdown:Rebuild()

    return dropdown
end
