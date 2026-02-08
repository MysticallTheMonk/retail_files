local _, LRP = ...

local LS = LibStub("LibSpecialization")

local initialized = false
local updateQueued = false

local eventShorthands = {
    SCS = "SPELL_CAST_START",
    SCC = "SPELL_CAST_SUCCESS",
    SAA = "SPELL_AURA_APPLIED",
    SAR = "SPELL_AURA_REMOVED",
    UD = "UNIT_DIED",
    USS = "UNIT_SPELLCAST_START",
    USC = "UNIT_SPELLCAST_SUCCEEDED",
    CMMY = "CHAT_MSG_MONSTER_YELL"
}

-- Outputs a trigger info table
local function ParseTrigger(triggerText)
    if not triggerText then return end

    local event, value, count
    local minutes, seconds = triggerText:match("time:(%d-):([0-9.]+)$")

    -- If this reminder is relative to an event, match a different pattern
    if not minutes then
        minutes, seconds, event, value, count = triggerText:match("time:(%d-):([0-9.]-),(%a-):(.-):(%d+)")
    end

    -- This typically should not happen, but if the count is omitted the above might still not match correctly
    if not minutes then
        minutes, seconds, event, value = triggerText:match("time:(%d-):([0-9.]-),(%a-):(%.+)")
        count = 1
    end

    minutes = tonumber(minutes)
    seconds = tonumber(seconds)

    if not minutes then return end
    if not seconds then return end

    if event then
        value = event == "CMMY" and value or tonumber(value)
        count = tonumber(count)
        event = eventShorthands[event]

        if not value then return end
        if not count then return end
        if not event then return end

        return {
            relativeTo = {
                event = event,
                value = value,
                count = count
            },
            time = minutes * 60 + seconds,
            duration = 8,
            linger = 0,
            hideOnUse = true
        }
    else
        return {
            time = minutes * 60 + seconds,
            duration = 8,
            linger = 0,
            hideOnUse = true
        }
    end
end

-- Outputs a load info table
local function ParseLoad(loadText)
    if not loadText then return end

    loadText = loadText:match("||c%x%x%x%x%x%x%x%x(.-)||r") or loadText -- Remove colors (if any)

    if loadText:match("{everyone}") then
        return {
            type = "ALL"
        }
    else
        local loadType, loadTarget = loadText:match("(.-):(.+)")

        if loadType and loadTarget then
            loadType = loadType:upper()
            loadTarget = loadTarget:upper()

            if loadType == "CLASS" then
                return {
                    type = "CLASS_SPEC",
                    class = loadTarget,
                    spec = loadTarget
                }
            elseif loadType == "SPEC" then
                local class, specIndex = loadTarget:match("(%a-):(%d)")

                specIndex = tonumber(specIndex)

                if class and specIndex then
                    return {
                        type = "CLASS_SPEC",
                        class = class,
                        spec = specIndex
                    }
                end
            elseif loadType == "GROUP" then
                return {
                    type = "GROUP",
                    group = tonumber(loadTarget) or 0
                }
            elseif loadType == "ROLE" then
                return {
                    type = "ROLE",
                    role = loadTarget
                }
            elseif loadType == "TYPE" then
                return {
                    type = "POSITION",
                    position = loadTarget
                }
            end
        else
            loadText = loadText:lower():gsub("^%l", string.upper) -- Capitalise only first letter for names

            return {
                type = "NAME",
                name = loadText
            }
        end
    end
end

-- Returns a display table with color set to white (color is not supported for note reminders)
local function ParseDisplay(displayText)
    if not displayText then return end

    local text = displayText:match("{[Tt][Ee][Xx][Tt]}(.-){/[Tt][Ee][Xx][Tt]}")

    if text then -- Text reminder
        return {
            type = "TEXT",
            text = text,
            color = {
                r = 1,
                g = 1,
                b = 1
            }
        }
    else -- Spell reminder
        local spellID = tonumber(displayText:match("{spell:(%d+)}"))

        if not spellID then return end

        return {
            type = "SPELL",
            spellID = spellID,
            color = {
                r = 1,
                g = 1,
                b = 1
            }
        }
    end
end

local function ParseGlow(glowText)
    if not glowText then
        return {
            enabled = false,
            names = {},
            type = "PIXEL",
            color = {
                r = 0.95,
                g = 0.95,
                b = 0.32
            }
        }
    end

    local glowNames = {}

    for name in string.gmatch(glowText, "([^,]+)") do
        name = strtrim(name:lower():gsub("^%l", string.upper)) -- Remove space and make sure only the first letter is capitalised
        
        table.insert(glowNames, name)
    end

    if #glowNames > 0 then
        return {
            enabled = true,
            names = glowNames,
            type = "PIXEL",
            color = {
                r = 0.95,
                g = 0.95,
                b = 0.32
            }
        }
    else
        return {
            enabled = false,
            names = {},
            type = "PIXEL",
            color = {
                r = 0.95,
                g = 0.95,
                b = 0.32
            }
        }
    end
end

-- Operates on a single line of the note
-- A line is structured as follows: [trigger] - [load][display][glow]  [load][display][glow]  [load][display][glow], etc.
-- The [glow] portion can alternatively be placed after the load portion (rather than after display), i.e. [load][glow][display]
-- This function feeds the respective parts into their corresponding functions
-- The output is a table of relevant reminders with each their own trigger, display, tts, and glow tables
local function ParseLine(line)
    -- The gmatch pattern below only matches the last reminder if the line has two trailing spaces
    -- This is fine if the note is output from the Viserio sheet, but often is forgotten about when made manually
    -- We just add them here (even if they were already there, it's fine)
    line = line .. "  "

    local reminders = {}
    local triggerText, reminderText = line:match("^{(.-)}.-%s%-%s(.+)")

    -- If the ability name is not included, the above match fails
    if not triggerText then
        triggerText, reminderText = line:match("^{(.-)}(.+)")
    end

    local trigger = ParseTrigger(triggerText)

    if not trigger then return reminders end

    for reminder in reminderText:gmatch("(.-)%s%s") do
        local loadText, displayText, glowText, load

        -- First test if the line is formatted like Llorgs output (no load text, just a single display text)
        displayText = strtrim(reminder):match("^{spell:%d+}$")

        if displayText then
            load = {
                type = "ALL"
            }
        else -- If it's not formatted like Llorgs, attempt to match Viserio/LR note output
            loadText, displayText, glowText = reminder:match("(.-)%s({.+})(.*)")

            if loadText then
                -- For Viserio reminders, the glow text is part of the load text (split by an @)
                if loadText:match("@") then
                    loadText, glowText = loadText:match("(.-)@(.+)")
                elseif glowText then
                    glowText = glowText:match("%s?@(.+)") -- Remove the @ (and possible space) from the glow text portion
                end

                load = ParseLoad(loadText)
            end
        end

        if load then
            local display = ParseDisplay(displayText)

            if display then
                local glow = ParseGlow(glowText)

                local reminderData = {
                    load = load,
                    trigger = trigger,
                    display = display,
                    glow = glow,
                    sound = {
                        enabled = false,
                        time = 0,
                        file = "Interface\\Addons\\TimelineReminders\\Media\\Sounds\\TR_Beep.mp3"
                    },
                    countdown = {
                        enabled = false,
                        start = 3,
                        voice = "Sara"
                    },
                    tts = {
                        enabled = false,
                        time = 0,
                        voice = 0
                    }
                }

                table.insert(reminders, reminderData)
            end
        end
    end

    return reminders
end

function LRP:ApplyDefaultSettingsToNote()
    if not LRP.MRTReminders then return end

    for _, reminderTypeTable in pairs(LRP.MRTReminders) do -- Personal/public
        for _, encounterTypeTable in pairs(reminderTypeTable) do -- Encounter/all
            for _, reminderData in pairs(encounterTypeTable) do
                -- Only apply is to relevant reminders
                -- Don't give the impression that reminders made for others use our default settings
                -- (they use the receiver's default settings, which we do not have access to)
                if LRP:IsRelevantReminder(reminderData) then
                    LRP:ApplyDefaultSettingsToReminder(reminderData)
                end
            end
        end
    end
end

-- Parses a note for reminders
-- Returns a table in the form {ALL = {array}, [encounterID_1] = {array}, [encounterID_2] = {array}, etc.}
function LRP:ParseReminderNote(note)
    local encounterID = "ALL"
    local reminders = {}
    
    for line in note:gmatch("[^\r\n]+") do
        local newEncounterID = tonumber(line:match("^{[Ee]:(%d+)}$"))

        if newEncounterID then
            encounterID = newEncounterID
        elseif line:match("^{/[Ee]}$") then
            encounterID = "ALL"
        end

        local lineReminders = ParseLine(line)

        if next(lineReminders) then
            if not reminders[encounterID] then
                reminders[encounterID] = {}
            end

            tAppendAll(reminders[encounterID], lineReminders)
        end
    end

    return reminders
end

-- Calls ParseLine() on every line of the public/personal MRT note
-- Populates LRP.MRTReminders
local function ParseMRTNote()
    LRP.MRTReminders = {personal = {}, public = {}}
    updateQueued = false

    if not VMRT then return end
    if not VMRT.Note then return end

    local notes = {
        personal = VMRT.Note.SelfText,
        public = VMRT.Note.Text1
    }

    for noteType, note in pairs(notes) do
        local reminderArray = LRP:ParseReminderNote(note)

        -- For comparison against reminders we set ourselves (those always have string keys)
        for encounter, reminders in pairs(reminderArray) do
            LRP.MRTReminders[noteType][encounter] = {}

            for i, reminder in ipairs(reminders) do
                LRP.MRTReminders[noteType][encounter][string.format("%s-%d", tostring(encounter), i)] = reminder
            end
        end
    end

    LRP:ApplyDefaultSettingsToNote()
end

function LRP:InitializeNoteInterpreter()
    if not initialized and MRTNote and MRTNote.text then
        initialized = true

        hooksecurefunc(
            MRTNote.text,
            "SetText",
            function()
                if not updateQueued then
                    updateQueued = true

                    C_Timer.After(
                        1,
                        function()
                            ParseMRTNote()

                            LRP:BuildReminderLines()
                        end
                    )
                end
            end
        )
    end
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
eventFrame:SetScript(
    "OnEvent",
    function(_, event)
        if event == "LOADING_SCREEN_DISABLED" then
            ParseMRTNote()

            LRP:BuildReminderLines()
        end
    end
)
