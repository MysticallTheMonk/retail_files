local _, addon = ...;

local function HideWidgets(nameplate)
    addon.HideClassIcon(nameplate);
    addon.HidePetIcon(nameplate);
    addon.HideNpcHighlight(nameplate);
    addon.HideCritterIcon(nameplate);
    addon.HideSpecIcon(nameplate);
end

-- Protected nameplates in dungeons and raids
local restricted = {
	party = true,
	raid = true,
};

local function IsRestricted()
    local instanceType = select(2, IsInInstance());
    return restricted[instanceType];
end

local function UpdateUnitFrameVisibility(nameplate, frame, show)
    -- Force frame's child elements to not ignore parent alpha
    -- This is still problematic at least in Retail, sometimes both healthBar and castBar show up
    -- healthBar seems fixed now, but name and castBar still show up
    if ( not frame.unsetIgnoreParentAlpha ) then
        for key, region in pairs(frame) do
            if ( type(region) == "table" ) and region.SetIgnoreParentAlpha then
                --print("[SweepyBoop] frame key:", key, "type:", type(region.SetIgnoreParentAlpha), "hasGetObjectType:", region.GetObjectType ~= nil);
                if addon.PROJECT_MAINLINE then
                    if (key ~= "HitTestFrame") then
                        region:SetIgnoreParentAlpha(false);
                    end
                else
                    if (key == "healthBar" or key == "selectionHighlight") then
                        region:SetIgnoreParentAlpha(false);
                    end
                end
            end
        end

        if addon.PROJECT_MAINLINE then
            for _, region in pairs(frame.castBar) do
                if ( type(region) == "table" ) and region.SetIgnoreParentAlpha then
                    region:SetIgnoreParentAlpha(false);
                end
            end
        end

        frame.unsetIgnoreParentAlpha = true;
    end

    show = show or SweepyBoop.db.profile.nameplatesFriendly.keepHealthBar;

    local alpha = ( show and 1 ) or 0;
    frame:SetAlpha(alpha);

    if addon.PROJECT_MAINLINE then
        frame.castBar:SetAlpha(alpha);
    end

    if nameplate.extended then -- NeatPlates
        -- Setting alpha on extended itself did not work, just set alpha on child elements
        for _, region in pairs(nameplate.extended.bars) do
            if ( type(region) == "table" ) and region.SetAlpha then
                region:SetAlpha(alpha);
            end
        end

        for _, region in pairs(nameplate.extended) do
            if ( type(region) == "table" ) and region.SetAlpha then
                region:SetAlpha(alpha);
            end
        end
    end
end

local function UpdateWidgets(nameplate, frame)
    -- Don't mess with personal resource display
    if ( UnitIsUnit(frame.unit, "player") ) then
        HideWidgets(nameplate);
        UpdateUnitFrameVisibility(nameplate, frame, true);
        return;
    end

    -- Comment out when testing on a target dummy
    if ( not UnitPlayerControlled(frame.unit) ) then
        HideWidgets(nameplate);
        UpdateUnitFrameVisibility(nameplate, frame, true);
        return;
    end

    -- Possible issue: after priest mind control, party member shows both class icon and health bar
    if ( not addon.UnitIsHostile(frame.unit) ) then -- Friendly units, show class icon for friendly players and party pets
        local configFriendly = SweepyBoop.db.profile.nameplatesFriendly;
        if configFriendly.classIconsEnabled then
            if UnitIsPlayer(frame.unit) then
                -- Issue: a pet that's not one of the above 3 showed an icon
                -- Maybe it was partypet2 and later someone else joined so this pet became partypet3
                addon.ShowClassIcon(nameplate, frame);
                addon.HidePetIcon(nameplate);
            elseif UnitIsUnit(frame.unit, "pet") or UnitIsUnit(frame.unit, "partypet1") or UnitIsUnit(frame.unit, "partypet2") then
                local shouldShow = true;
                local isArena = IsActiveBattlefieldArena();
                local isBattleground = ( UnitInBattleground("player") ~= nil );
                if configFriendly.hideOutsidePvP and ( not isArena ) and ( not isBattleground ) then
                    shouldShow = false;
                elseif configFriendly.hideInBattlegrounds and isBattleground and ( not isArena ) then
                    shouldShow = false;
                elseif configFriendly.showMyPetOnly and ( not UnitIsUnit(frame.unit, "pet") ) then
                    shouldShow = false;
                end

                addon.HideClassIcon(nameplate);
                if shouldShow then
                    addon.ShowPetIcon(nameplate, frame);
                else
                    addon.HidePetIcon(nameplate);
                end
            else
                addon.HideClassIcon(nameplate);
                addon.HidePetIcon(nameplate);
            end

            UpdateUnitFrameVisibility(nameplate, frame, false); -- if class icons are enabled, all friendly units' health bars should be hidden
        else
            addon.HideClassIcon(nameplate);
            UpdateUnitFrameVisibility(nameplate, frame, true); -- Will be overriden by nameplate filter later
        end

        addon.HideSpecIcon(nameplate);
        addon.HideNpcHighlight(nameplate);
        addon.HideCritterIcon(nameplate);
    else
        addon.HideClassIcon(nameplate);
        addon.HidePetIcon(nameplate);

        if UnitIsPlayer(frame.unit) then
            -- For Classic version, only show in arena
            local shouldShowSpecIcon;
            local configEnemy = SweepyBoop.db.profile.nameplatesEnemy;
            if addon.PROJECT_MAINLINE then
                shouldShowSpecIcon = configEnemy.arenaSpecIconHealer or configEnemy.arenaSpecIconOthers;
            else
                shouldShowSpecIcon = ( configEnemy.arenaSpecIconHealer or configEnemy.arenaSpecIconOthers ) and IsActiveBattlefieldArena();
            end

            if shouldShowSpecIcon then
                addon.ShowSpecIcon(nameplate); -- Control alpha in spec icon module for healer / non-healer
            else
                addon.HideSpecIcon(nameplate);
            end

            addon.HideNpcHighlight(nameplate);
            addon.HideCritterIcon(nameplate);
            UpdateUnitFrameVisibility(nameplate, frame, true); -- Always show enemy players
            return;
        end

        -- Process non-player hostile units
        addon.HideSpecIcon(nameplate);

        local npcOption, isCritter = addon.CheckNpcWhiteList(frame.unit);
        local shouldShowUnitFrame = true;
        if ( npcOption == addon.NpcOption.Highlight ) then
            addon.ShowNpcHighlight(nameplate, true);
        elseif ( npcOption == addon.NpcOption.ShowWithIcon ) then
            addon.ShowNpcHighlight(nameplate);
        elseif ( npcOption == addon.NpcOption.Show ) then
            addon.HideNpcHighlight(nameplate);
        else
            addon.HideNpcHighlight(nameplate);
            shouldShowUnitFrame = false;
        end

        -- Hide Beast Mastery Hunter secondary pets (this override the above setting)
        -- If we already decided to hide a unit, no need to perform this check!
        if shouldShowUnitFrame and addon.UnitIsHunterSecondaryPet(frame.unit) then
            shouldShowUnitFrame = false;
        end

        if SweepyBoop.db.profile.nameplatesEnemy.showCritterIcons and isCritter and ( not shouldShowUnitFrame ) then
            addon.ShowCritterIcon(nameplate);
        else
            addon.HideCritterIcon(nameplate);
        end

        UpdateUnitFrameVisibility(nameplate, frame, shouldShowUnitFrame);
    end
end

function SweepyBoop:SetupNameplateModules()
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED);
    if addon.PROJECT_MAINLINE then
        eventFrame:RegisterEvent(addon.UPDATE_BATTLEFIELD_SCORE);
    end
    eventFrame:RegisterEvent(addon.UNIT_FACTION);
    eventFrame:RegisterEvent(addon.UNIT_AURA);
    eventFrame:SetScript("OnEvent", function (_, event, unitId, ...)
        if event == addon.NAME_PLATE_UNIT_ADDED then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                HideWidgets(nameplate); -- Hide previous widgets (even in restricted areas)
                if IsRestricted() then
                    UpdateUnitFrameVisibility(nameplate, nameplate.UnitFrame, true); -- We don't want to hide the unit frame inside dungeons
                else
                    UpdateWidgets(nameplate, nameplate.UnitFrame);
                end

                addon.OnNamePlateAuraUpdate(nameplate.UnitFrame, nameplate.UnitFrame.unit);
            end
        elseif event == addon.UPDATE_BATTLEFIELD_SCORE then -- This cannot be triggered in restricted areas
            if ( UnitInBattleground("player") == nil ) then return end -- Only needed in battlegrounds for updating visible spec icons
            local nameplates = C_NamePlate.GetNamePlates();
            for i = 1, #(nameplates) do
                local nameplate = nameplates[i];
                if nameplate and nameplate.UnitFrame then
                    if nameplate.UnitFrame:IsForbidden() then return end
                    if nameplate.UnitFrame.optionTable.showPvPClassificationIndicator then
                        addon.UpdateSpecIcon(nameplate);
                    end
                end
            end
        elseif event == addon.UNIT_FACTION then -- This is triggered for Mind Control
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                if ( not IsRestricted() ) then
                    UpdateWidgets(nameplate, nameplate.UnitFrame);
                end
            end
        elseif event == addon.UNIT_AURA then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId);
            if nameplate and nameplate.UnitFrame then
                if nameplate.UnitFrame:IsForbidden() then return end
                local unitAuraUpdateInfo = ...;
                addon.OnNamePlateAuraUpdate(nameplate.UnitFrame, nameplate.UnitFrame.unit, unitAuraUpdateInfo);

                addon.UpdateClassIconCrowdControl(nameplate, nameplate.UnitFrame);
            end
        end
    end)

    -- When flag is picked up / dropped
    -- Issue, not immediately updated to flag carrier icon when someone picked up the flag
    -- if addon.PROJECT_MAINLINE then
    --     hooksecurefunc("CompactUnitFrame_UpdatePvPClassificationIndicator", function (frame)
    --         -- This will only be applied to nameplates in PvP instances
    --         if frame:IsForbidden() then return end
    --         if frame.optionTable.showPvPClassificationIndicator then
    --             -- UpdateClassIcon should include UpdateTargetHighlight
    --             -- Otherwise we can't guarantee the order of events CompactUnitFrame_UpdateClassificationIndicator and CompactUnitFrame_UpdateName
    --             -- Consequently we can't guarantee the target highlight is up-to-date on FC
    --             addon.UpdateClassIcon(frame:GetParent(), frame);
    --         end
    --     end)
    -- end

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if frame:IsForbidden() then return end

        -- Less efficient check for classic as showPvPClassificationIndicator is not available
        local isNamePlate = frame.optionTable.showPvPClassificationIndicator or ( ( not addon.PROJECT_MAINLINE ) and string.find(frame.unit, "nameplate") );
        if isNamePlate then
            addon.UpdateClassIconTargetHighlight(frame:GetParent(), frame);
            addon.UpdatePetIconTargetHighlight(frame:GetParent(), frame);
            addon.UpdatePlayerName(frame:GetParent(), frame);

            if IsActiveBattlefieldArena() and SweepyBoop.db.profile.nameplatesEnemy.arenaNumbersEnabled then
                for i = 1, 3 do
                    if UnitIsUnit(frame.unit, "arena" .. i) then
                        frame.name:SetText(i);
                        frame.name:SetTextColor(1,1,0); --Yellow
                        break;
                    end
                end
            end
        end
    end)

    -- if addon.PROJECT_MAINLINE then
    --     hooksecurefunc(NameplateBuffButtonTemplateMixin, "OnEnter", function(self)
    --         if self:IsForbidden() then return end
    --         if SweepyBoop.db.profile.nameplatesEnemy.auraFilterEnabled then
    --             self:EnableMouse(false);
    --         else
    --             self:EnableMouse(true);
    --         end
    --     end)
    -- end
end

function SweepyBoop:RefreshAllNamePlates(hideFirst)
    if IsRestricted() then return end

    local nameplates = C_NamePlate.GetNamePlates(true); -- isSecure = true to return nameplates in instances (to hide widgets)
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        if nameplate and nameplate.UnitFrame then
            if nameplate.UnitFrame:IsForbidden() then return end
            if hideFirst then
                HideWidgets(nameplate);
            end
            UpdateWidgets(nameplate, nameplate.UnitFrame);
        end
    end
end

function SweepyBoop:RefreshAurasForAllNamePlates()
    local nameplates = C_NamePlate.GetNamePlates(issecure());
    for i = 1, #(nameplates) do
        local nameplate = nameplates[i];
        if nameplate and nameplate.UnitFrame and ( nameplate.UnitFrame.BuffFrame or nameplate.UnitFrame.CustomBuffFrame ) then
            if nameplate.UnitFrame:IsForbidden() then return end
            addon.OnNamePlateAuraUpdate(nameplate.UnitFrame, nameplate.UnitFrame.unit);
        end
    end
end
