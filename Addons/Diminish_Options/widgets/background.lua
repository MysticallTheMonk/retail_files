local _, NS = ...
local Widgets = NS.Widgets

local panelBackdrop = {
    bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 16,
    edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
}

function Widgets:CreatePanelBackground(parent)
    local frame = CreateFrame("Frame", nil, parent, _G.BackdropTemplateMixin and "BackdropTemplate")
    frame:SetBackdrop(panelBackdrop)
    frame:SetBackdropColor(0.06, 0.06, 0.06, 0.4)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    return frame
end
