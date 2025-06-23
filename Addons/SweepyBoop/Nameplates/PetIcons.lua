local _, addon = ...;

local function EnsureIcon(nameplate)
    if ( not nameplate.FriendlyPetIcon ) then
        nameplate.FriendlyPetIcon = addon.CreateClassOrSpecIcon(nameplate, "BOTTOM", "BOTTOM", true);
        nameplate.FriendlyPetIcon.icon:SetTexture(addon.ICON_ID_PET);
        nameplate.FriendlyPetIcon:Hide();
    end

    return nameplate.FriendlyPetIcon;
end

addon.UpdatePetIconTargetHighlight = function (nameplate, frame)
    if nameplate.FriendlyPetIcon then
        nameplate.FriendlyPetIcon.targetHighlight:SetShown(UnitIsUnit(frame.unit, "target"));
    end
end

addon.UpdatePetIcon = function(nameplate, frame)
    -- Only update if config changes (we have separated out pet icon from class / healer / flag carrier icons, and pet icon has fixed texture)
    local iconFrame = EnsureIcon(nameplate);
    local config = SweepyBoop.db.profile.nameplatesFriendly;
    local lastModifiedFriendly = config.lastModified;
    if ( iconFrame.lastModifiedFriendly ~= lastModifiedFriendly ) then
        iconFrame:SetScale(config.petIconSize);
        iconFrame:SetPoint("BOTTOM", nameplate, "BOTTOM", 0, config.classIconOffset);
        iconFrame.lastModifiedFriendly = lastModifiedFriendly;
    end

    addon.UpdatePetIconTargetHighlight(nameplate, frame);
end

addon.ShowPetIcon = function (nameplate, frame)
    addon.UpdatePetIcon(nameplate, frame);
    if nameplate.FriendlyPetIcon then
        nameplate.FriendlyPetIcon:Show();
    end
end

addon.HidePetIcon = function(nameplate)
    if nameplate.FriendlyPetIcon then
        nameplate.FriendlyPetIcon:Hide();
    end
end
