local _, LRP = ...

local version = 21

function LRP:Modernize()
    local internalVersion = LiquidRemindersSaved.internalVersion or 0

    -- If this is the first time the addon is used, don't run modernize
    if not internalVersion then internalVersion = version end

    -- Only mythic used to be supported, and all the reminders were in a single table
    -- Now that two difficulties per game version are supported (heroic/mythic for retail, normal/heroic for classic), split them up
    if internalVersion < 4 then
        for encounterID, encounterReminders in pairs(LiquidRemindersSaved.reminders) do
            if not (encounterReminders[1] or encounterReminders[2]) then
                local copyReminders = CopyTable(encounterReminders)

                LiquidRemindersSaved.reminders[encounterID] = {
                    [1] = {}, -- Heroic
                    [2] = copyReminders
                }
            end
        end
    end

    if internalVersion < 5 then
        local classNames = {
            DEATHKNIGHT = true,
            DEMONHUNTER = true,
            DRUID = true,
            EVOKER = true,
            HUNTER = true,
            MAGE = true,
            MONK = true,
            PALADIN = true,
            PRIEST = true,
            ROGUE = true,
            SHAMAN = true,
            WARLOCK = true,
            WARRIOR = true
        }

        if not LiquidRemindersSaved.spellBookData[10] then -- TWW
            LiquidRemindersSaved.spellBookData[10] = {}
        end

        for class in pairs(classNames) do
            if LiquidRemindersSaved.spellBookData[class] then
                LiquidRemindersSaved.spellBookData[10][class] = CopyTable(LiquidRemindersSaved.spellBookData[class])

                LiquidRemindersSaved.spellBookData[class] = nil
            end
        end
    end

    -- Some users were reporting Lua errors due to encounter reminder tables not having difficulty subtables
    -- This should have been taken care of in version 4, but somehow maybe have failed
    if internalVersion < 6 then
        for _, encounterReminders in pairs(LiquidRemindersSaved.reminders) do
            if not encounterReminders[1] then
                encounterReminders[1] = {}
            end

            if not encounterReminders[2] then
                encounterReminders[2] = {}
            end
        end
    end

    -- spellID field in timeline changed to value
    if internalVersion < 7 then
        for _, difficultyReminders in pairs(LiquidRemindersSaved.reminders) do
            for _, encounterReminders in pairs(difficultyReminders) do
                for _, reminderData in pairs(encounterReminders) do
                    if reminderData.trigger.relativeTo and reminderData.trigger.relativeTo.spellID then
                        reminderData.trigger.relativeTo.value = reminderData.trigger.relativeTo.spellID

                        reminderData.trigger.relativeTo.spellID = nil
                    end
                end
            end
        end
    end

    -- Sounds got introduced to reminders
    if internalVersion < 8 then
        for _, difficultyReminders in pairs(LiquidRemindersSaved.reminders) do
            for _, encounterReminders in pairs(difficultyReminders) do
                for _, reminderData in pairs(encounterReminders) do
                    if not reminderData.sound then
                        reminderData.sound = {
                            enabled = false,
                            time = 0,
                            file = "Interface\\Addons\\TimelineReminders\\Media\\Sounds\\TR_Beep.mp3"
                        }
                    end
                end
            end
        end
    end

    if internalVersion < 9 then
        if LiquidRemindersSaved.settings.defaultReminder and not LiquidRemindersSaved.settings.defaultReminder.sound then
            LiquidRemindersSaved.settings.defaultReminder.sound = {
                enabled = false,
                time = 0,
                file = "Interface\\Addons\\TimelineReminders\\Media\\Sounds\\TR_Beep.mp3"
            }
        end
    end

    -- Countdown got introduced to reminders
    if internalVersion < 10 then
        for _, difficultyReminders in pairs(LiquidRemindersSaved.reminders) do
            for _, encounterReminders in pairs(difficultyReminders) do
                for _, reminderData in pairs(encounterReminders) do
                    if not reminderData.countdown then
                        reminderData.countdown = {
                            enabled = false,
                            start = 3,
                            voice = "Sara"
                        }
                    end
                end
            end
        end

        if LiquidRemindersSaved.settings.defaultReminder and not LiquidRemindersSaved.settings.defaultReminder.countdown then
            LiquidRemindersSaved.settings.defaultReminder.countdown = {
                enabled = false,
                start = 3,
                voice = "Sara"
            }
        end
    end

    -- Public/personal MRT note toggle now shows/hides them in-fight as well (rather than just on the timeline)
    if internalVersion < 11 then
        if LiquidRemindersSaved.settings.timeline.showNoteReminders ~= nil then
            LiquidRemindersSaved.settings.timeline.personalNoteReminders = true
            LiquidRemindersSaved.settings.timeline.publicNoteReminders = true

            LiquidRemindersSaved.settings.timeline.showNoteReminders = nil
        end
    end

    if internalVersion < 12 then
        if LiquidRemindersSaved.settings.timeline.ignoreNoteInDungeon == nil then
            LiquidRemindersSaved.settings.timeline.ignoreNoteInDungeon = false
        end
    end

    if internalVersion < 13 then
        if not LiquidRemindersSaved.settings.soundChannel then
            LiquidRemindersSaved.settings.soundChannel = "Master"
        end

        if not LiquidRemindersSaved.settings.ttsVolume then
            LiquidRemindersSaved.settings.ttsVolume = 100
        end
    end

    if internalVersion < 14 then
        for _, encounterReminders in pairs(LiquidRemindersSaved.reminders) do
            for _, difficultyReminders in pairs(encounterReminders) do
                for _, reminderData in pairs(difficultyReminders) do
                    if LRP:VerifyReminderIntegrity(reminderData) then
                        if not reminderData.export then
                            reminderData.export = {}

                            local triggerText, rest = LRP:ExportReminderToMRT(reminderData)

                            reminderData.export.mrt = {
                                trigger = triggerText,
                                rest = rest
                            }
                        end
                    end
                end
            end
        end
    end

    if internalVersion < 15 then
        if not LiquidRemindersSaved.settings.importOptions then
            LiquidRemindersSaved.settings.importOptions = {
                duration = true,
                color = true,
                tts = true,
                sound = true,
                countdown = true,
                glow = true
            }
        end
    end

    -- Import/export is a fairly large/risky feature that requires thorough testing
    -- Make a backup of all the user's reminders just in case something is messed up
    if internalVersion < 16 then
        LiquidRemindersSaved.remindersBackup = LiquidRemindersSaved.reminders or {}
    end

    -- Profiles are introduced
    if internalVersion < 17 then
        if not LiquidRemindersSaved.settings.timeline.selectedProfiles then
            LiquidRemindersSaved.settings.timeline.selectedProfiles = {}
        end

        for _, encounterReminders in pairs(LiquidRemindersSaved.reminders) do
            for difficultyID, difficultyReminders in pairs(encounterReminders) do
                if not difficultyReminders["Default profile"] then
                    local reminders = {}

                    -- Verify reminder integrity while we're at it
                    for reminderID, reminderData in pairs(difficultyReminders) do
                        if LRP:VerifyReminderIntegrity(reminderData) then
                            reminders[reminderID] = reminderData
                        end
                    end

                    encounterReminders[difficultyID] = {
                        ["Default profile"] = reminders
                    }
                end
            end
        end
    end

    -- Phase triggers for City of Threads last boss got changed
    if internalVersion < 18 then
        for encounterID, encounterReminders in pairs(LiquidRemindersSaved.reminders) do
            if encounterID == 2909 then -- Izo, the Grand Splicer
                for _, difficultyReminders in pairs(encounterReminders) do
                    for _, profileReminders in pairs(difficultyReminders) do
                        for _, reminderData in pairs(profileReminders) do
                            local relativeTo = reminderData.trigger.relativeTo

                            if relativeTo and relativeTo.event == "SPELL_CAST_START" and relativeTo.value == 438860 then -- Umbral Weave
                                relativeTo.value = 439401 -- Shifting Anomalies
                                reminderData.trigger.time = reminderData.trigger.time + 12
                            end
                        end
                    end
                end
            end
        end
    end

    -- Somehow users ended up with reminders that are not inside a difficulty (or a profile) table
    -- By this time, the reminder data is gone and it'll be overwritten by "default profile"
    -- Just delete these
    if internalVersion < 19 then
        for _, encounterReminders in pairs(LiquidRemindersSaved.reminders) do
            for difficulty in pairs(encounterReminders) do
                if difficulty ~= 1 and difficulty ~= 2 then
                    encounterReminders[difficulty] = nil
                end
            end
        end
    end

    -- Backup for profiles
    if internalVersion < 20 then
        LiquidRemindersSaved.remindersBackup = LiquidRemindersSaved.reminders or {}
    end

    -- Linger option got added
    if internalVersion < 21 then
        for _, encounterReminders in pairs(LiquidRemindersSaved.reminders) do
            for _, difficultyReminders in pairs(encounterReminders) do
                for _, profileReminders in pairs(difficultyReminders) do
                    for _, reminderData in pairs(profileReminders) do
                        if not reminderData.trigger.linger then
                            reminderData.trigger.linger = 0
                        end
                    end
                end
            end
        end

        if LiquidRemindersSaved.settings.defaultReminder and not LiquidRemindersSaved.settings.defaultReminder.trigger.linger then
            LiquidRemindersSaved.settings.defaultReminder.trigger.linger = 0
        end
    end

    LiquidRemindersSaved.internalVersion = version
end

