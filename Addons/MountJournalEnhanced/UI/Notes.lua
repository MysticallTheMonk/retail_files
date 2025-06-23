local _, ADDON = ...

local AceGUI = LibStub("AceGUI-3.0")

local notesText

local function getLabelText(mountId)
    local text = ''
    local note = ADDON.settings.notes[mountId]
    if note then
        text = NORMAL_FONT_COLOR:WrapTextInColorCode(NOTE_COLON) .. " " .. HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(note)
    end

    return text
end

local function updateText()
    local mountId = ADDON.Api:GetSelected()
    if mountId and notesText then
        notesText:SetText(getLabelText(mountId))
    end
end

function ADDON.UI:CreateNotesFrame(mountId)

    local note = AceGUI:Create("Window")

    -- Create frame
    note:SetTitle(SET_NOTE)
    note:SetHeight(150)
    note:SetWidth(400)
    note:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
    note:SetLayout("List")
    note:EnableResize(false)

    -- Create Edit Box
    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetLabel("")
    editbox:SetWidth(375)
    editbox:SetText(ADDON.settings.notes[mountId] or "")
    editbox:DisableButton(true)
    note:AddChild(editbox)

    -- Create button
    local button = AceGUI:Create("Button")
    button:SetText(SAVE)
    button:SetWidth(375)
    button:SetCallback("OnClick", function()
        local text = strtrim(editbox:GetText(), " \n")
        if strlen(text) > 0 then
            ADDON.settings.notes[mountId] = text
        elseif ADDON.settings.notes[mountId] then
            ADDON.settings.notes[mountId] = nil
            ADDON.settings.notes = tFilter(ADDON.settings.notes, function(v)
                return v ~= nil
            end)
        end
        updateText()
        note:Hide()
    end)
    note:AddChild(button)

    -- Display
    note:ClearAllPoints()
    note:SetPoint("BOTTOM", MountJournal.MountDisplay, "BOTTOM", 0, 0)
    note:Show()
    editbox:SetFocus()

    return note
end

-- show notes in display
local function setupFontString()
    local frame = MountJournal.MountDisplay.InfoButton

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", frame.Lore, "BOTTOMLEFT", 0, -6)
    text:SetSize(345, 0)
    text:SetJustifyH("LEFT")

    return text
end

ADDON.Events:RegisterCallback("loadUI", function()
    notesText = setupFontString()
    ADDON.Events:RegisterCallback("OnUpdateMountDisplay", updateText, 'DisplayNotes')
end, "display notes")

-- show notes in mount tooltips
ADDON.Events:RegisterCallback("OnLogin", function()
    hooksecurefunc(GameTooltip, "SetMountBySpellID", function(tooltip, spellId)
        local mountId = C_MountJournal.GetMountFromSpell(spellId)
        if mountId then
            local text = getLabelText(mountId)
            if text then
                tooltip:AddLine(text)
                tooltip:Show()
            end
        end
    end)
end, "notes")