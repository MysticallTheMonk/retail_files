local _, LRP = ...

local windowWidth, windowHeight = 220, 100
local window, confirmButton, cancelButton, nameEditBox, colorPicker
local renameProfileName -- The name of the profile that is being renamed, without color (if any)
local color = CreateColor(1, 1, 1)

function LRP:ShowProfileWindow(parent, oldProfileName)
    if window:IsShown() then
        window:Hide() -- Just to trigger OnHide
    end

    window:Show()
    window:SetParent(parent)
    window:SetPoint("CENTER", parent, "CENTER")
    window:SetFrameLevel(parent:GetFrameLevel() + 10)
    parent:SetAlpha(0.5)

    if oldProfileName then -- Rename profile
        renameProfileName = oldProfileName:match("^|c%x%x%x%x%x%x%x%x(.+)|r$") or oldProfileName
        local oldColorHex = oldProfileName:match("^|c(%x%x%x%x%x%x%x%x)") or "ffffffff"

        confirmButton:SetText("|cff00ff00Rename|r")
        nameEditBox:SetText(renameProfileName)

        confirmButton:SetScript(
            "OnClick",
            function()
                -- Hacky way to check if profile name is valid: if it's not, the edit box has a tooltip indicating why
                if nameEditBox.tooltipText and nameEditBox.tooltipText ~= "" then return end

                local profileName = nameEditBox:GetText()
                local hexColor = color:GenerateHexColor()
                
                LRP:RenameReminderProfile(oldProfileName, WrapTextInColorCode(profileName, hexColor))

                window:Hide()
            end
        )

        local oldColor = CreateColorFromHexString(oldColorHex)
        colorPicker:SetColor(oldColor:GetRGBA())
    else -- Create profile
        renameProfileName = nil

        confirmButton:SetText("|cff00ff00Create|r")
        nameEditBox:SetText("")

        confirmButton:SetScript(
            "OnClick",
            function()
                -- Hacky way to check if profile name is valid: if it's not, the edit box has a tooltip indicating why
                if nameEditBox.tooltipText and nameEditBox.tooltipText ~= "" then return end

                local profileName = nameEditBox:GetText()
                local hexColor = color:GenerateHexColor()
                
                LRP:AddReminderProfile(WrapTextInColorCode(profileName, hexColor))

                window:Hide()
            end
        )

        colorPicker:SetColor(1, 1, 1, 1)
    end

    window:SetScript(
        "OnHide",
        function()
            parent:SetAlpha(1)
        end
    )
end

function LRP:InitializeProfileWindow()
    window = LRP:CreateWindow(nil)
    LRP.profileWindow = window

    window:SetSize(windowWidth, windowHeight)
    window:SetIgnoreParentAlpha(true)
    window:SetFrameStrata("DIALOG")
    window:Hide()

    confirmButton = LRP:CreateButton(window, "|cff00ff00Create|r", function() end)
    confirmButton:SetPoint("BOTTOMRIGHT", window, "BOTTOM", -4, 10)

    cancelButton = LRP:CreateButton(window, "|cffff0000Cancel|r", function() window:Hide() end)
    cancelButton:SetPoint("BOTTOMLEFT", window, "BOTTOM", 4, 10)

    nameEditBox = LRP:CreateEditBox(
        window,
        "Profile name",
        function(text)
            if text == "" then
                nameEditBox:ShowHighlight(1, 0, 0)

                LRP:AddTooltip(nameEditBox, "|cffff0000Profile name cannot be empty.|r")
                LRP:RefreshTooltip()

                return
            end

            local timelineInfo = LRP:GetCurrentTimelineInfo()
            local encounterID = timelineInfo.encounterID
            local difficulty = timelineInfo.difficulty
            local profileNames = LiquidRemindersSaved.reminders[encounterID][difficulty]

            for profileName in pairs(profileNames) do
                local profileNameNoColor = profileName:match("^|c%x%x%x%x%x%x%x%x(.+)|r$")

                -- If we are renaming a profile, it's allowed to be the same name as it used to have, just not the same as another existing profile
                -- This makes sense because the user should have the option to just recolor it, and keep the same name
                if text ~= renameProfileName and (text == profileName or text == profileNameNoColor) then
                    nameEditBox:ShowHighlight(1, 0, 0)

                    LRP:AddTooltip(nameEditBox, "|cffff0000A profile with that name already exists.|r")
                    LRP:RefreshTooltip()

                    return
                end
            end

            nameEditBox:HideHighlight()

            LRP:AddTooltip(nameEditBox) -- Input is valid, don't show a tooltip
            LRP:RefreshTooltip()
        end
    )
    nameEditBox:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -20)
    nameEditBox:SetSize(140, 24)
    nameEditBox:SetMaxLetters(20)

    colorPicker = LRP:CreateColorPicker(
        window,
        "Color",
        function(r, g, b)
            color:SetRGB(r, g, b)
        end
    )
    colorPicker:SetPoint("LEFT", nameEditBox, "RIGHT", 8, 0)
    colorPicker:SetSize(20, 20)
end

-- When the user clicks outside the confirm window, hide it
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
eventFrame:SetScript(
    "OnEvent",
    function()
        if window:IsShown() then
            local frame = GetMouseFoci()[1]
            
            for _ = 1, 5 do
                if not frame then break end
                if frame:IsForbidden() then break end
                if frame == window or frame == ColorPickerFrame then return end
                
                frame = frame.GetParent and frame:GetParent()
            end

            window:Hide()
        end
    end
)