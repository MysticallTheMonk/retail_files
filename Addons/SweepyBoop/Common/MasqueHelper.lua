local addonName, addon = ...;

local Masque = LibStub and LibStub("Masque", true);

local icons = nil;

if Masque then
    icons = Masque:Group(addonName, "All Icons");
end

function addon.MasqueAddIcon(frame, texture)
    if icons then
        icons:AddButton(frame, {Icon = texture});
    end
end

function addon.MasqueReskinIcon()
    if icons then
        icons:ReSkin();
    end
end
