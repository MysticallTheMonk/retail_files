local _, NS = ...
local Widgets = NS.Widgets

local function OnDisable(self)
    self.labelText:SetFontObject(GameFontNormalLeftGrey)
end

local function OnEnable(self)
    self.labelText:SetFontObject(GameFontHighlightLeft)
end

function Widgets:CreateCheckbox(parent, text, tooltipText, func)
    local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    check:SetMotionScriptsWhileDisabled(true)
    check.labelText = check.Text

    check:SetScript("OnClick", func)
    check:SetScript("OnDisable", OnDisable)
    check:SetScript("OnEnable", OnEnable)
    check.GetValue = check.GetChecked
    check.SetValue = check.SetChecked

    check.labelText:SetText(text)
    check:SetHitRectInsets(0, -1 * max(100, check.labelText:GetStringWidth() + 4), 0, 0)
    check.tooltipText = tooltipText
    check:SetScript("OnEnter", Widgets.OnEnter)
    check:SetScript("OnLeave", GameTooltip_Hide)

    return check
end
