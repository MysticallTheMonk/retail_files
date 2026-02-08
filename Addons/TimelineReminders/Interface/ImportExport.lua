local _, LRP = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

-- Single export window
local singleExportWindow
local singleExportString, singleExportStringMRT
local singleExportEditBox, singleExportEditBoxMRT

-- Import/export window
local importExportWindow, buttonFrame, importFrame, exportFrame
local exportString, exportStringMRT
local importEditBox, exportEditBox
local warningFrame, warningTimer

-- Import settings
local importCheckButtons = {}

local eventToShorthand = {
    SPELL_CAST_START = "SCS",
    SPELL_CAST_SUCCESS = "SCC",
    SPELL_AURA_APPLIED = "SAA",
    SPELL_AURA_REMOVED = "SAR",
    UNIT_DIED = "UD",
    UNIT_SPELLCAST_START = "USS",
    UNIT_SPELLCAST_SUCCEEDED = "USC",
    CHAT_MSG_MONSTER_YELL = "CMMY"
}

-- MRT export functions
local function ShowWarning(text)
    warningFrame.text:SetText(string.format("|cFFFF0000%s|r", text))
    warningFrame:Show()

    if warningTimer then
        warningTimer:Cancel()
    end

    warningTimer = C_Timer.NewTimer(3, function() warningFrame:Hide() end)
end

local function ExportTrigger(trigger)
    local minutes = math.floor(trigger.time / 60)
    local seconds = trigger.time % 60
    local timeString = string.format("time:%02d:%04.1f", minutes, seconds)

    if trigger.relativeTo then
        local eventShorthand = eventToShorthand[trigger.relativeTo.event]
        local value = trigger.relativeTo.value or ""
        local count = trigger.relativeTo.count or 1

        return string.format("{%s,%s:%s:%s}", timeString, eventShorthand, tostring(value), count)
    else
        return string.format("{%s}", timeString)
    end
end

local function ExportLoad(load)
    local loadType = load.type

    if loadType == "ALL" then
        return "{everyone}"
    elseif loadType == "NAME" then
        return load.name
    elseif loadType == "POSITION" then
        return string.format("type:%s", load.position)
    elseif loadType == "CLASS_SPEC" then
        if load.class == load.spec then -- Class reminder
            return string.format("class:%s", load.class)
        else -- Spec reminder
            return string.format("spec:%s:%s", load.class, load.spec)
        end
    elseif loadType == "GROUP" then
        return string.format("group:%d", load.group)
    elseif loadType == "ROLE" then
        return string.format("role:%s", load.role)
    end
end

local function ExportDisplay(display)
    if display.type == "SPELL" then
        return string.format("{spell:%d}", display.spellID or 0)
    else
        return string.format("{text}%s{/text}", display.text or "")
    end
end

local function ExportGlow(glow)
    if not glow.enabled then return "" end
    if not next(glow.names) then return "" end

    local glowNames = "@"

    for _, glowName in ipairs(glow.names) do
        glowNames = string.format(glowNames == "@" and "%s%s" or "%s,%s", glowNames, glowName)
    end

    return glowNames
end

function LRP:ExportReminderToMRT(reminderData)
    local triggerText = ExportTrigger(reminderData.trigger)
    local loadText = ExportLoad(reminderData.load)
    local displayText = ExportDisplay(reminderData.display)
    local glowText = ExportGlow(reminderData.glow)

    return triggerText, string.format("%s %s%s", loadText, displayText, glowText)
end

function LRP:ExportRemindersToString(reminders)
    local encounterID = LRP:GetCurrentTimelineInfo().encounterID

    local exportTable = {
        v = LiquidRemindersSaved.internalVersion,
        id = encounterID,
        d = LiquidRemindersSaved.settings.timeline.selectedDifficulty,
        r = reminders
    }

    local serialized = LibSerialize:SerializeEx({errorOnUnserializableType = false}, exportTable)
    local compressed = LibDeflate:CompressDeflate(serialized, {level = 1})
    local encoded = LibDeflate:EncodeForPrint(compressed)

    return string.format("!TR:%s", encoded)
end

-- Apply default settings (where needed) to a reminder that is being imported, depending on import settings
local function PrepareReminderForImport(reminderData, existingReminder)
    local importOptions = LiquidRemindersSaved.settings.importOptions

    -- If this reminder already exists, use its current settings
    -- If not, use default reminder settings
    local defaultReminder = existingReminder or LiquidRemindersSaved.settings.defaultReminder

    if not importOptions.duration then
        reminderData.trigger.duration = defaultReminder.trigger.duration
        reminderData.trigger.linger = defaultReminder.trigger.linger
    end

    if not importOptions.color then
        reminderData.display.color = defaultReminder.display.color
    end

    if not importOptions.tts then
        reminderData.tts = defaultReminder.tts
    end

    if not importOptions.sound then
        reminderData.sound = defaultReminder.sound
    end

    if not importOptions.countdown then
        reminderData.countdown = defaultReminder.countdown
    end

    if not importOptions.glow then
        reminderData.glow.type = defaultReminder.glow.type
        reminderData.glow.color = defaultReminder.glow.color
    end
end

local function ImportRemindersFromMRT()
    local text = importEditBox:GetText()
    local reminders = LRP:ParseReminderNote(text)

    if not next(reminders) then
        ShowWarning("No valid reminders found")

        return
    end

    local timelineInfo = LRP:GetCurrentTimelineInfo()
    local currentEncounterID = timelineInfo.encounterID
    local difficulty = timelineInfo.difficulty

    local relevantReminderCount = 0
    local irrelevantReminderCount = 0

    for encounterID, encounterReminders in pairs(reminders) do
        if encounterID == "ALL" or encounterID == currentEncounterID then
            relevantReminderCount = relevantReminderCount + #encounterReminders
        else
            irrelevantReminderCount = irrelevantReminderCount + #encounterReminders
        end
    end

    if relevantReminderCount == 0 then
        ShowWarning("No relevant reminders found")

        return
    end

    local confirmText

    if irrelevantReminderCount == 0 then
        confirmText = string.format("Are you sure you want to import %d |4reminder:reminders;?", relevantReminderCount)
    else
        confirmText = string.format("Are you sure you want to import %d |4reminder:reminders;?|n|n%d |4reminder was:reminders were; ignored because they are intended for a different encounter.", relevantReminderCount, irrelevantReminderCount)
    end

    LRP:ShowConfirmWindow(
        LRP.importExportWindow,
        confirmText,
        function()
            for encounterID, encounterReminders in pairs(reminders) do
                if encounterID == "ALL" or encounterID == currentEncounterID then
                    for _, reminderData in pairs(encounterReminders) do
                        local id = LRP:GenerateUniqueID()

                        LRP:ApplyDefaultSettingsToReminder(reminderData)

                        LRP:CreateReminder(id, reminderData, currentEncounterID, difficulty)
                    end
                end
            end

            LRP:BuildReminderLines()

            importEditBox:SetText("")
            LRP.importExportWindow:Hide()
        end
    )
end

local function ImportRemindersFromString()
    local text = importEditBox:GetText()

    local toDecode = text:match("!TR:(.+)")
    if not toDecode or toDecode == "" then
        ShowWarning("Import is empty")

        return
    end

    local decoded = LibDeflate:DecodeForPrint(toDecode)
    if not decoded then
        ShowWarning("Failed to decode reminder data")

        return
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        ShowWarning("Failed to decompress reminder data")
        
        return
    end

    local success, data = LibSerialize:Deserialize(decompressed)
    if not success then
        ShowWarning("Failed to deserialize reminder data")
        
        return
    end

    if not data.v or not tonumber(data.v) then
        ShowWarning("No version found")

        return
    end

    if not data.id or not tonumber(data.id) then
        ShowWarning("No encounter ID found")

        return
    end

    if not data.d or not tonumber(data.d) then
        ShowWarning("No difficulty found")

        return
    end

    if data.v > LiquidRemindersSaved.internalVersion then
        ShowWarning("Cannot import reminders from a newer addon version")

        return
    end

    local reminderCount = 0
    local timelineInfo = LRP:GetCurrentTimelineInfo()
    local targetReminderTable = timelineInfo.reminders
    local currentEncounterID = timelineInfo.encounterID
    local difficulty = timelineInfo.difficulty

    for _ in pairs(data.r) do
        reminderCount = reminderCount + 1
    end

    local confirmText = string.format("Are you sure you want to import %d |4reminder:reminders;?", reminderCount)

    if data.id ~= currentEncounterID then
        confirmText = string.format("%s|n|n|cFFFF0000Warning: the reminder(s) you are importing are intended for a different encounter.|r", confirmText)
    end

    if data.d ~= difficulty then
        confirmText = string.format("%s|n|n|cFFFF0000Warning: the reminder(s) you are importing are intended for a different difficulty.|r", confirmText)
    end

    LRP:ShowConfirmWindow(
        LRP.importExportWindow,
        confirmText,
        function()
            for id, reminderData in pairs(data.r) do
                if LRP:VerifyReminderIntegrity(reminderData) then
                    local existingReminder = targetReminderTable[id]

                    PrepareReminderForImport(reminderData, existingReminder)

                    LRP:CreateReminder(id, reminderData, currentEncounterID, difficulty)
                end
            end

            LRP:BuildReminderLines()

            importEditBox:SetText("")
            LRP.importExportWindow:Hide()
        end
    )
end

local function ImportReminders()
    local text = importEditBox:GetText()

    if not text or text == "" then
        ShowWarning("Import is empty")

        return
    end

    if text:match("^!TR:") then
        ImportRemindersFromString()
    else
        ImportRemindersFromMRT()
    end
end

-- Single export window control functions
function LRP:CloseSingleExport()
    singleExportWindow:Hide()
end

function LRP:OpenSingleExport(reminderID, reminderData)
    if singleExportWindow:IsShown() then return end

    singleExportWindow:Show()

    LRP:DisplaySingleExport(reminderID, reminderData)
end

function LRP:ToggleSingleExport(reminderID, reminderData)
    if singleExportWindow:IsShown() then
        LRP:CloseSingleExport()
    else
        LRP:OpenSingleExport(reminderID, reminderData)
    end
end

-- This function displays reminder data from config in the single export window
-- This is called every time reminder data in config changes, but we only want to export if the window is open
-- If we do it every time without the window being open, that's a lot of extra (likely useless) work
-- This is different to LRP:ExportReminderToString or LRP:ExportReminderToMRT, which execute regardless of the window being open
-- The reason is that LRP:ExportReminderToString/MRT are only called when reminder data in SavedVariables changes
function LRP:DisplaySingleExport(reminderID, reminderData)
    if not singleExportWindow then return end
    if not singleExportWindow:IsShown() then return end

    -- MRT
    local triggerText, rest = LRP:ExportReminderToMRT(reminderData)

    singleExportStringMRT = string.format("%s - %s", triggerText, rest)

    singleExportEditBoxMRT:SetText(singleExportStringMRT)
    singleExportEditBoxMRT:ClearHighlightText()
    singleExportEditBoxMRT:SetCursorPosition(0)

    -- String
    singleExportString = LRP:ExportRemindersToString({[reminderID] = reminderData})

    singleExportEditBox:SetText(singleExportString)
    singleExportEditBox:ClearHighlightText()
    singleExportEditBox:SetCursorPosition(0)
end

function LRP:ExportTimelineToMRT()
    if not exportStringMRT then
        local timelineInfo = LRP:GetCurrentTimelineInfo()

        local timelineData = timelineInfo.timelineData
        local reminders = timelineInfo.reminders
        local instanceType = timelineInfo.instanceType
        local encounterID = timelineInfo.encounterID

        local triggerToRest = {}

        for _, reminderData in pairs(reminders) do
            local triggerText = reminderData.export.mrt.trigger
            local rest = reminderData.export.mrt.rest

            if triggerText and rest then
                if not triggerToRest[triggerText] then
                    triggerToRest[triggerText] = {
                        reminders = {},
                        time = LRP:GetReminderTimelineTime(timelineData, reminderData) or 99999999 -- Unknown event reminders are sorted last
                    }
                end

                table.insert(triggerToRest[triggerText].reminders, rest)
            end
        end

        local sortedReminderTable = {}

        for trigger, data in pairs(triggerToRest) do
            table.insert(
                sortedReminderTable,
                {
                    trigger = trigger,
                    reminders = data.reminders,
                    time = data.time
                }
            )
        end

        table.sort(
            sortedReminderTable,
            function(a, b)
                if a.time ~= b.time then
                    return a.time < b.time
                else
                    return a.trigger < b.trigger
                end
            end
        )

        exportStringMRT = ""

        for _, data in ipairs(sortedReminderTable) do
            exportStringMRT = string.format("%s%s - ", exportStringMRT, data.trigger)

            for _, reminder in ipairs(data.reminders) do
                exportStringMRT = string.format("%s%s  ", exportStringMRT, reminder)
            end

            exportStringMRT = string.format("%s|n", exportStringMRT)
        end

        -- For dungeon encounters, wrap in an encounter tag
        if instanceType == 2 then
            exportStringMRT = string.format("{e:%d}|n%s{/e}", encounterID, exportStringMRT)
        end
    end

    exportEditBox:SetText(exportStringMRT)
end

function LRP:ExportTimelineToString()
    if not exportString then
        local reminders = LRP:GetCurrentTimelineInfo().reminders
        
        exportString = LRP:ExportRemindersToString(reminders)
    end

    exportEditBox:SetText(exportString)
end

-- Used when a reminder is created/changed, or we start viewing a new timeline
-- When export data is stale, it is regenerated when ExportTimelineToMRT or ExportTimelineToString are called
function LRP:SetExportStale()
    exportString = nil
    exportStringMRT = nil
end

function LRP:InitializeSingleExport()
    singleExportWindow = LRP:CreateWindow()

    singleExportWindow:SetParent(LRP.reminderConfig)
    singleExportWindow:SetPoint("TOPLEFT", LRP.reminderConfig, "BOTTOMLEFT", 0, -4)
    singleExportWindow:SetPoint("TOPRIGHT", LRP.reminderConfig, "BOTTOMRIGHT", 0, -4)
    singleExportWindow:SetHeight(96)
    singleExportWindow:Hide()

    -- This window is an "extension" of the reminder config, so color it entirely dark blue
    singleExportWindow.upperTexture:Hide()
    singleExportWindow.lowerTexture:SetAllPoints()

    -- MRT export
    singleExportEditBoxMRT = LRP:CreateEditBox(singleExportWindow, "MRT", function() end)

    singleExportEditBoxMRT:SetPoint("TOPLEFT", singleExportWindow, "TOPLEFT", 8, -20)
    singleExportEditBoxMRT:SetPoint("TOPRIGHT", singleExportWindow, "TOPRIGHT", -8, -20)
    singleExportEditBoxMRT:SetHeight(24)

    singleExportEditBoxMRT:SetScript(
        "OnCursorChanged",
        function()
            if singleExportEditBoxMRT:HasFocus() then
                singleExportEditBoxMRT:HighlightText()
            end
        end
    )

    singleExportEditBoxMRT:SetScript(
        "OnTextChanged",
        function(_, userInput)
            if not userInput then return end

            singleExportEditBoxMRT:SetText(singleExportStringMRT or "")
            singleExportEditBoxMRT:HighlightText()
            singleExportEditBoxMRT:SetFocus()
        end
    )

    -- String export
    singleExportEditBox = LRP:CreateEditBox(singleExportWindow, "String", function() end)

    singleExportEditBox:SetPoint("TOPLEFT", singleExportEditBoxMRT, "BOTTOMLEFT", 0, -20)
    singleExportEditBox:SetPoint("TOPRIGHT", singleExportEditBoxMRT, "BOTTOMRIGHT", 0, -20)
    singleExportEditBox:SetHeight(24)

    singleExportEditBox:SetScript(
        "OnCursorChanged",
        function()
            if singleExportEditBox:HasFocus() then
                singleExportEditBox:HighlightText()
            end
        end
    )

    singleExportEditBoxMRT:SetScript(
        "OnTextChanged",
        function(_, userInput)
            if not userInput then return end

            singleExportEditBox:SetText(singleExportString or "")
            singleExportEditBox:HighlightText()
            singleExportEditBox:SetFocus()
        end
    )
end

local function AddImportOptionCheckButton(title, key, tooltip)
    local checkButton = LRP:CreateCheckButton(importFrame, title, function(checked) LiquidRemindersSaved.settings.importOptions[key] = checked end)

    checkButton:SetChecked(LiquidRemindersSaved.settings.importOptions[key])

    LRP:AddTooltip(checkButton, tooltip)
    LRP:AddTooltip(checkButton.title, tooltip)

    table.insert(importCheckButtons, checkButton)
end

local function EnableImportOptionCheckButtons()
    for _, checkButton in ipairs(importCheckButtons) do
        checkButton:Enable()
    end
end

local function DisableImportOptionCheckButtons()
    for _, checkButton in ipairs(importCheckButtons) do
        checkButton:Disable()

        checkButton.secondaryTooltipText = "|cffff0000This option is only available for string imports. MRT imports always apply your default settings.|r"
        checkButton.title.secondaryTooltipText = "|cffff0000This option is only available for string imports. MRT imports always apply your default settings.|r"
    end
end

local function InitializeImportFrame()
    importFrame = CreateFrame("Frame", nil, importExportWindow)

    importFrame:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT", 4, -4)
    importFrame:SetPoint("BOTTOMRIGHT", importExportWindow, "BOTTOMRIGHT", -4, 4)

    -- Edit box
    importEditBox = LRP:CreateEditBox(importFrame, "", function() end)

    importEditBox:SetMultiLine(true)
    importEditBox:SetTextInsets(8, 8, 8, 8)
    importEditBox:SetClipsChildren(true)
    importEditBox:SetPoint("TOPLEFT", importFrame, "TOPLEFT")
    importEditBox:SetPoint("BOTTOMRIGHT", importFrame, "BOTTOMRIGHT", 0, 104)

    importEditBox:SetScript(
        "OnTextChanged",
        function(_, userInput)
            if not userInput then return end

            local text = importEditBox:GetText()

            if text == "" or text:match("^!TR:.+") then
                EnableImportOptionCheckButtons()
            else
                DisableImportOptionCheckButtons()
            end

            importEditBox:SetText(text or "")
        end
    )

    -- Import button
    local importButton = LRP:CreateButton(
        importFrame,
        "Import",
        function()
            ImportReminders()
        end
    )

    importButton:SetPoint("TOP", importEditBox, "BOTTOM", 0, -4)

    -- Warning frame
    warningFrame = CreateFrame("Frame", nil, importEditBox)

    warningFrame:SetPoint("BOTTOMLEFT", importEditBox, "BOTTOMLEFT")
    warningFrame:SetPoint("BOTTOMRIGHT", importEditBox, "BOTTOMRIGHT")
    warningFrame:SetHeight(24)
    warningFrame:Hide()

    warningFrame.tex = warningFrame:CreateTexture(nil, "BACKGROUND")
    warningFrame.tex:SetAllPoints()
    warningFrame.tex:SetColorTexture(0, 0, 0, 0.8)

    warningFrame.text = warningFrame:CreateFontString(nil, "OVERLAY")
    warningFrame.text:SetFontObject(LRFont13)
    warningFrame.text:SetPoint("CENTER")

    local borderColor = LRP.gs.visual.borderColor

    LRP:AddBorder(warningFrame)
    warningFrame:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Import options
    AddImportOptionCheckButton("Import duration", "duration", "Whether reminder duration should be imported. If unchecked, applies your default duration settings.")
    AddImportOptionCheckButton("Import color", "color", "Whether text color should be imported. If unchecked, applies your default text color settings.")
    AddImportOptionCheckButton("Import TTS", "tts", "Whether text-to-speech settings should be imported. If unchecked, applies your default TTS settings.")
    AddImportOptionCheckButton("Import sound", "sound", "Whether sound settings should be imported. If unchecked, applies your default sound settings.")
    AddImportOptionCheckButton("Import countdown", "countdown", "Whether countdown settings should be imported. If unchecked, applies your default countdown settings.")
    AddImportOptionCheckButton("Import glow", "glow", "Whether glow settings should be imported. If unchecked, applies your default glow settings.")

    local rowSpacing = 24

    for i, checkButton in ipairs(importCheckButtons) do
        local row = math.floor((i - 1) / 2)
        local column = (i - 1) % 2

        if column == 0 then
            checkButton:SetPoint("TOPLEFT", importEditBox, "BOTTOMLEFT", 0, -36 - row * rowSpacing)
        else
            checkButton:SetPoint("TOPLEFT", importEditBox, "BOTTOM", 0, -36 - row * rowSpacing)
        end
    end
end

local function InitializeExportFrame()
    exportFrame = CreateFrame("Frame", nil, importExportWindow)

    exportFrame:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT", 4, -4)
    exportFrame:SetPoint("BOTTOMRIGHT", importExportWindow, "BOTTOMRIGHT", -4, 4)

    -- Edit box
    exportEditBox = LRP:CreateEditBox(exportFrame, "", function() end)

    exportEditBox:SetMultiLine(true)
    exportEditBox:SetTextInsets(8, 8, 8, 8)
    exportEditBox:SetClipsChildren(true)
    exportEditBox:SetPoint("TOPLEFT", exportFrame, "TOPLEFT")
    exportEditBox:SetPoint("BOTTOMRIGHT", exportFrame, "BOTTOMRIGHT", 0, 30)

    exportEditBox:SetScript(
        "OnTextChanged",
        function(_, userInput)
            if not userInput then return end

            local text = exportEditBox:GetText()

            exportEditBox:SetText(text or "")
        end
    )

    -- Export MRT button
    local exportMRTButton = LRP:CreateButton(
        exportFrame,
        "MRT",
        function()
            LRP:ExportTimelineToMRT()
        end
    )

    exportMRTButton:SetPoint("TOPRIGHT", exportEditBox, "BOTTOM", -2, -4)

    -- Export string button
    local exportStringButton = LRP:CreateButton(
        exportFrame,
        "String",
        function()
            LRP:ExportTimelineToString()
        end
    )

    exportStringButton:SetPoint("TOPLEFT", exportEditBox, "BOTTOM", 2, -4)
end

function LRP:InitializeImportExport()
    -- Window
    importExportWindow = LRP:CreateWindow("ImportExport", true, true, true)

    importExportWindow:SetPoint("CENTER")
    importExportWindow:SetSize(400, 400)
    importExportWindow:SetParent(LRP.window)
    importExportWindow:SetFrameStrata("DIALOG")
    importExportWindow:SetFrameLevel(100)
    importExportWindow:SetResizeBounds(300, 300)
    importExportWindow:Hide()

    LRP.importExportWindow = importExportWindow

    -- Information icon
    local infoButton = CreateFrame("Button", nil, importExportWindow.moverFrame)

    infoButton:SetSize(20, 20)
    infoButton:SetPoint("RIGHT", importExportWindow.buttons[1], "LEFT", -2, 0)
    infoButton:SetHighlightTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\Help-i-highlight.tga", "ADD")
    infoButton:SetMouseMotionEnabled(true)

    infoButton.tex = infoButton:CreateTexture()
    infoButton.tex:SetAllPoints(infoButton)
    infoButton.tex:SetTexture("Interface\\AddOns\\TimelineReminders\\Media\\Textures\\Help-i.tga")

    LRP:AddTooltip(
        infoButton,
[[Use this interface to import someone else's reminders into your timeline, or export your reminders for others to use.
        
Reminders can be imported/exported using either an MRT note format, or an encoded string format. They each have their advantages/disadvantages.

|cff2aaef5MRT|r
The main advantage of exporting your reminders to an MRT format, is that you can paste them in MRT and have them instantly ready for use by your group. The downside is that not all reminder settings are supported. Things like text color, and custom duration per reminder are lost. The user's default settings are used instead.

|cff2aaef5String|r
Reminders exported to string format contain all reminder settings. On import, you are able to choose which settings are kept. When importing reminders you already have, they are updated (not duplicated).]]
    )

    -- Button frame
    buttonFrame = CreateFrame("Frame", nil, importExportWindow)

    buttonFrame:SetPoint("TOPLEFT", importExportWindow.moverFrame, "BOTTOMLEFT")
    buttonFrame:SetPoint("TOPRIGHT", importExportWindow.moverFrame, "BOTTOMRIGHT")

    buttonFrame:SetHeight(32)

    -- Import button
    local importButton = LRP:CreateButton(
        importExportWindow,
        "Import",
        function()
            importFrame:Show()
            exportFrame:Hide()
        end
    )

    importButton:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", 4, -4)
    importButton:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOM", -2, 0)

    importButton:SetNormalFontObject(LRFont16)
    importButton:SetHighlightFontObject(LRFont16)
    importButton:SetDisabledFontObject(LRFont16)

    -- Export button
    local exportButton = LRP:CreateButton(
        importExportWindow,
        "Export",
        function()
            importFrame:Hide()
            exportFrame:Show()
        end
    )

    exportButton:SetPoint("TOPRIGHT", buttonFrame, "TOPRIGHT", -4, -4)
    exportButton:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOM", 2, 0)

    exportButton:SetNormalFontObject(LRFont16)
    exportButton:SetHighlightFontObject(LRFont16)
    exportButton:SetDisabledFontObject(LRFont16)

    InitializeImportFrame()
    InitializeExportFrame()

    exportFrame:Hide()
end
