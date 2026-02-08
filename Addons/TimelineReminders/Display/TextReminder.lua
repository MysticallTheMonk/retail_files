local _, LRP = ...

function LRP:CreateTextReminder(callback)
    local expirationTime, text, colorString

	local textReminder = CreateFrame("FRAME", nil, UIParent)
    local fs = textReminder:CreateFontString(nil, "OVERLAY")

    textReminder:SetFrameStrata(LRP.anchors.TEXT:GetFrameStrata())
    textReminder:SetFrameLevel(LRP.anchors.TEXT:GetFrameLevel())

    function textReminder:UpdateSize()
        local fontSize = LiquidRemindersSaved.settings.reminderTypes.TEXT.size
        textReminder:SetSize(32, fontSize)
        fs:SetFont(LiquidRemindersSaved.settings.reminderTypes.TEXT.font, fontSize, "OUTLINE")
    end

    function textReminder:UpdateAlignment()
        local alignment = LiquidRemindersSaved.settings.reminderTypes.TEXT.alignment

        fs:ClearAllPoints()
        fs:SetPoint(alignment, textReminder, alignment)
    end

    function textReminder:Initialize(id, reminderData, simulationOffset)
        local duration = math.min(reminderData.trigger.duration, reminderData.trigger.time - simulationOffset)
        
        expirationTime = GetTime() + duration
        colorString = ConvertRGBtoColorString(reminderData.display.color)

        -- If we are showing a spell reminder as text, construct the text from its spellID
        if reminderData.display.type == "TEXT" then
            text = LRP:FormatForDisplay(reminderData.display.text)
        else
            local spellInfo = LRP.GetSpellInfo(reminderData.display.spellID)

            text = string.format("%s %s", LRP:IconString(spellInfo.iconID), spellInfo.name)
        end

        textReminder:Show()

        textReminder:SetScript(
            "OnUpdate",
            function()
                local remainingTime = expirationTime - GetTime()

                if remainingTime > 0 then
                    fs:SetText(string.format("%s%s (%.1f)|r", colorString, text, remainingTime))
                else
                    textReminder:SetScript("OnUpdate", nil)

                    callback(nil, id, false)
                end
            end
        )

        textReminder:UpdateSize()
        textReminder:UpdateAlignment()

        if WeakAuras and WeakAuras.ScanEvents then
            WeakAuras.ScanEvents("TIMELINE_REMINDERS_SHOW", "TEXT", id, reminderData)
        end
    end

    function textReminder:GetExpirationTime()
        return expirationTime
    end

    return textReminder
end