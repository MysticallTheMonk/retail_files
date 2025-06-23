local _, NS = ...
local Widgets = NS.Widgets

local count = 0

local function OnValueChanged(self, value)
    local val = ceil(value)
    _G[self:GetName() .. "High"]:SetText(val)

    if self.callbackFunc and self.hasRefreshed then
        self.callbackFunc(self, val)
    end
    self.hasRefreshed = true -- only run callback after panel.refresh() has been triggered once after startup
end

function Widgets:CreateSlider(parent, text, tooltipText, minValue, maxValue, valueStep, func)
    local name = format("%sSlider%d", self.ADDON_NAME, count)

    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetSize(180, 15)
    slider:SetMinMaxValues(minValue or 1, maxValue or 100)
    slider:SetValueStep(valueStep or 1)

    local label = _G[name .. "Text"]
    label:SetFontObject("GameFontNormalLeft")
    label:ClearAllPoints()
    label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 3)
    label:SetText(text)
    slider.labelText = label

    local value =  _G[name .. "High"]
    value:SetFontObject("GameFontHighlightSmall")
    value:ClearAllPoints()
    value:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 3)
    slider.valueText = value

    slider.tooltipText = tooltipText
    slider:SetScript("OnEnter", Widgets.OnEnter)
    slider:SetScript("OnLeave", GameTooltip_Hide)
    slider.callbackFunc = func
    slider:SetScript("OnValueChanged", OnValueChanged)
    _G[name .. "Low"]:SetText("")

    count = count + 1

    return slider
end
