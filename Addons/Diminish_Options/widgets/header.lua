local _, NS = ...
local Widgets = NS.Widgets

function Widgets:CreateHeader(parent, titleText, versionText, notesText)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetPoint("TOPRIGHT", -16, -16)
    title:SetJustifyH("LEFT")
    title:SetText(titleText or parent.name)

    local version, notes

    if versionText then
        version = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
        version:SetPoint("TOPRIGHT", -16, -16)
        version:SetHeight(title:GetHeight())
        version:SetJustifyH("RIGHT")
        version:SetJustifyV("BOTTOM")
        version:SetFormattedText("%s: %s%s|r", GAME_VERSION_LABEL, HIGHLIGHT_FONT_COLOR_CODE, versionText)
        title:SetPoint("RIGHT", version, "LEFT", -8, 0)
    end

    if notesText ~= false then
        notes = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        notes:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        notes:SetPoint("RIGHT", -16, 0)
        notes:SetHeight(32)
        notes:SetJustifyH("LEFT")
        notes:SetJustifyV("TOP")
        notes:SetNonSpaceWrap(true)
        notes:SetText(notesText)
    end

    return title, notes, version
end

function Widgets:CreateSubHeader(parent, text)
    local anchor = CreateFrame("Frame", nil, parent)
    anchor:SetSize(200, 32)

    local title = anchor:CreateFontString(nil, "ARTWORK", "GameFontNormalMed1")
    title:SetJustifyH("LEFT")
    title:SetJustifyV("TOP")
    title:SetText(text)
    title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -3)

    local underline = anchor:CreateTexture(nil, "ARTWORK", "_UI-Frame-BtnBotTile")
    underline:ClearAllPoints()
    underline:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)

    return anchor
end
