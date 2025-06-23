local _, addon = ...;
local icon = addon.Icon;

function icon.SetMoreTooltipContent(tooltip)
    tooltip:AddLine(addon.L["Left click"] .. " " .. addon.L["Icon Left click"]:SetColorAddonBlue());
    tooltip:AddLine(addon.L["Right click"] .. " "  .. addon.L["Icon Right click"]:SetColorAddonBlue());
end

function icon.OnLeftClick()
    local menu = KrowiEVU_OptionsButton:BuildMenu();
    menu:Open();
end

function icon.OnRightClick()
    addon.Options:Open();
end