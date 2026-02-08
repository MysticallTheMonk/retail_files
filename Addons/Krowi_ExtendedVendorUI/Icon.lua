local _, addon = ...
local icon = addon.Icon

local instructionsFormat = '%s: %s'
function icon.SetMoreTooltipContent(tooltip)
    tooltip:AddLine(string.format(instructionsFormat, addon.Util.L['Left-Click'], addon.L['Icon Left click']):SetColorTpInstr())
    tooltip:AddLine(string.format(instructionsFormat, addon.Util.L['Right-Click'], addon.L['Icon Right click']):SetColorTpInstr())
end

function icon.OnLeftClick()
    KrowiEVU_OptionsButton:ShowPopup()
end

function icon.OnRightClick()
    addon.Options:Open()
end