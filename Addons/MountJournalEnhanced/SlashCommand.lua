local _, ADDON = ...

SLASH_MOUNTJOURNALENHANCED1, SLASH_MOUNTJOURNALENHANCED2 = '/mountjournalenhanced', '/mje'

local function printHelp()
    print("Syntax:")
    print("/mje options       Opens addon options")
    print("/mje reset size    Resets journal frame size to default")
    print("/mje set date [Mount Name] YYYY-MM-DD You can set the collection date of an already collected mount. This only works for mounts which don't have a date set yet. This means: you can set the date ONLY ONCE.")
end

function SlashCmdList.MOUNTJOURNALENHANCED(input)
    local loweredInput = input:lower():trim()

    if ADDON.TakeScreenshots and loweredInput == "screenshot" then
        ADDON:TakeScreenshots()
    elseif loweredInput == "reset size" then
        ADDON.UI:RestoreWindowSize()
    elseif loweredInput == "options" then
        ADDON:OpenOptions()
    else
        local setMount, setYear, setMonth, setDay = string.match(input, "set date (.+) (%d%d%d%d)-(%d%d)-(%d%d)")
        if setMount then
            local spellId = string.match(input, "mount:(%d+):")
            if not spellId then
                spellId = string.match(input, "spell:(%d+):")
            end
            if not spellId then
                spellId = C_Spell.GetSpellIDForSpellIdentifier(setMount)
            end
            if spellId then
                local mountId = C_MountJournal.GetMountFromSpell(spellId)
                if mountId then
                    ADDON:SetLearnedDate(mountId, setYear + 0, setMonth + 0, setDay + 0)
                    print("learned date set.")
                    return
                end
            end
        end

        printHelp()
    end
end