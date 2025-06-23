local _, NS = ...
local Widgets = NS.Widgets

function Widgets:CreateButton(parent, text, tooltipText, func)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:GetFontString():SetPoint("CENTER", -1, 0)
    button:SetMotionScriptsWhileDisabled(true)
    button:RegisterForClicks("AnyUp")

    button:SetText(text)
    button:SetWidth(max(110, button:GetFontString():GetStringWidth() + 24))
    button.tooltipText = tooltipText

    button:SetScript("OnClick", func)
    button:SetScript("OnEnter", Widgets.OnEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)

    return button
end
