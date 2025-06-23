local _, NS = ...
local Widgets = NS.Widgets

function Widgets:CreateEditbox(parent, labelText, tooltipText)
    local editbox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editbox:SetSize(180, 22)
    editbox:EnableMouse(true)
    editbox:SetAltArrowKeyMode(false)
    editbox:SetAutoFocus(false)
    editbox:SetFontObject(ChatFontSmall)
    editbox:SetTextInsets(6, 6, 2, 0)
    editbox:SetMaxLetters(40)

    editbox.tooltipText = tooltipText
    editbox:SetScript("OnEnter", Widgets.OnEnter)
    editbox:SetScript("OnLeave", GameTooltip_Hide)

    local label = editbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", editbox, "TOPLEFT", 0, 3)
    label:SetPoint("BOTTOMRIGHT", editbox, "TOPRIGHT", -0, 3)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)

    return editbox
end
