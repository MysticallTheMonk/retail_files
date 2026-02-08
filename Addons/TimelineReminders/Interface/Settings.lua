local _, LRP = ...

local padding = 8
local spacing = 4 -- Spacing between UI elements
local checkButtons = {}

local function AddCheckButton(title, tooltip, isChecked, OnValueChanged)
    local checkButton = LRP:CreateCheckButton(
        LRP.settingsWindow,
        title,
        OnValueChanged
    )

    if next(checkButtons) then
        checkButton:SetPoint("TOPLEFT", checkButtons[#checkButtons], "BOTTOMLEFT", 0, -spacing)
    else
        checkButton:SetPoint("TOPLEFT", LRP.settingsWindow, "TOPLEFT", padding, -padding)
    end

    checkButton:SetChecked(isChecked)
    checkButton:SetSize(20, 20)
    checkButton.title:SetFontObject(LRFont15)

    LRP:AddTooltip(checkButton, tooltip)
    LRP:AddTooltip(checkButton.title, tooltip)

    table.insert(checkButtons, checkButton)
end

function LRP:InitializeSettings()
    LRP.settingsWindow = LRP:CreateWindow("Settings")
    LRP.settingsWindow:SetParent(LRP.window)
    LRP.settingsWindow:SetPoint("TOPLEFT", LRP.window, "TOPRIGHT", 4, 0)
    LRP.settingsWindow:SetSize(244, 188)
    LRP.settingsWindow:Hide()

    AddCheckButton(
        "Show relevant reminders only",
        "Only show reminders that are relevant to the character you are currently playing.|n|n|cff29ff62Disabling this option does not make you see other players' reminders during the fight. It only makes them appear on the timeline.|r",
        LiquidRemindersSaved.settings.timeline.showRelevantRemindersOnly,
        function(checked)
            LiquidRemindersSaved.settings.timeline.showRelevantRemindersOnly = checked

            LRP:BuildReminderLines()
        end
    )

    AddCheckButton(
        "Public |cff80ffffMRT|r note reminders",
        "Whether public MRT note reminders should be displayed. These cannot be modified.",
        LiquidRemindersSaved.settings.timeline.publicNoteReminders,
        function(checked)
            LiquidRemindersSaved.settings.timeline.publicNoteReminders = checked

            LRP:BuildReminderLines()
        end
    )

    AddCheckButton(
        "Personal |cff80ffffMRT|r note reminders",
        "Whether personal MRT note reminders should be displayed. These cannot be modified.",
        LiquidRemindersSaved.settings.timeline.personalNoteReminders,
        function(checked)
            LiquidRemindersSaved.settings.timeline.personalNoteReminders = checked

            LRP:BuildReminderLines()
        end
    )

    if LRP.isRetail then -- Dungeons are only supported in retail
        AddCheckButton(
            "Ignore |cff80ffffMRT|r in dungeons",
            "If checked, reminders written in MRT notes (both public and personal) will not show up during dungeon encounters.",
            LiquidRemindersSaved.settings.timeline.ignoreNoteInDungeon,
            function(checked)
                LiquidRemindersSaved.settings.timeline.ignoreNoteInDungeon = checked
    
                LRP:BuildReminderLines()
            end
        )
    end

    AddCheckButton(
        "Show |cffff052bdeath|r line",
        "Show a |cffff052bred|r line for where you last died on this encounter",
        LiquidRemindersSaved.settings.timeline.showDeathLine,
        function(checked)
            LiquidRemindersSaved.settings.timeline.showDeathLine = checked

            LRP:BuildDeathLine()
        end
    )

    -- Sound channel
    local channelToIndex = {
        Master = 1,
        Music = 2,
        Effects = 3,
        Ambience = 4,
        Dialog = 5
    }

    local soundChannelInfoTable = {}

    for index, channel in ipairs(tInvert(channelToIndex)) do
        soundChannelInfoTable[index] = {
            text = channel,
            value = channel
        }
    end

    local soundChannelDropdown = LRP:CreateDropdown(
        LRP.settingsWindow,
        "Sound channel",
        soundChannelInfoTable,
        function(channel)
            LiquidRemindersSaved.settings.soundChannel = channel
        end,
        {channelToIndex[LiquidRemindersSaved.settings.soundChannel or "Master"] or 1}
    )

    soundChannelDropdown:SetWidth(100)
    soundChannelDropdown:SetPoint("TOPLEFT", checkButtons[#checkButtons], "BOTTOMLEFT", 0, -24)

    LRP:AddTooltip(soundChannelDropdown, "The channel that sounds and countdowns are played through. You can adjust the channel's volume in game options.")

    -- TTS volume
    local ttsVolumeSlider = LRP:CreateSlider(
        LRP.settingsWindow,
        "TTS volume",
        0,
        100,
        function(volume)
            LiquidRemindersSaved.settings.ttsVolume = volume
        end,
        LiquidRemindersSaved.settings.ttsVolume
    )

    ttsVolumeSlider:SetWidth(120)
    ttsVolumeSlider:SetPoint("LEFT", soundChannelDropdown, "RIGHT", 2 * spacing, 0)

    LRP:AddTooltip(ttsVolumeSlider, "The volume for TTS. This does not apply to countdowns.")
end