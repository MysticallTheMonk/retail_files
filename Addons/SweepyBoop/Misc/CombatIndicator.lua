local _, addon = ...;

local iconSize = 36;

local unitToFrame = {
    player = PlayerFrame,
    target = TargetFrame,
    focus = FocusFrame
};

local anchors;
if addon.PROJECT_MAINLINE then
    anchors = {
        player = { relativeTo = PlayerFrame.PlayerFrameContainer.PlayerPortrait, relativePoint = "LEFT" },
        target = { relativeTo = TargetFrame.TargetFrameContainer.Portrait, relativePoint = "RIGHT" },
        focus = { relativeTo = FocusFrame.TargetFrameContainer.Portrait, relativePoint = "RIGHT" },
    };
else -- TODO: implement for classic

end

local function UpdateCombatIndicator(frame, unit)
    if ( not frame.combatIndicator ) then
        frame.combatIndicator = CreateFrame("Frame", nil, frame);
        frame.combatIndicator:SetMouseClickEnabled(false);
        frame.combatIndicator:SetFrameStrata("HIGH");
        frame.combatIndicator:SetSize(iconSize, iconSize);
        frame.combatIndicator:SetPoint("CENTER", anchors[unit].relativeTo, anchors[unit].relativePoint);

        frame.combatIndicator.icon = frame.combatIndicator:CreateTexture(nil, "OVERLAY");
        frame.combatIndicator.icon:SetAtlas("countdown-swords");
        frame.combatIndicator.icon:SetAllPoints();
    end

    frame.combatIndicator:SetShown(UnitAffectingCombat(unit));
end

local eventFrame = CreateFrame("Frame");
eventFrame:SetScript("OnEvent", function(_, event, unit)
    if ( event == addon.UNIT_FLAGS ) then
        local frame = unitToFrame[unit];
        if frame then
            UpdateCombatIndicator(frame, unit);
        end
    else
        for unit, frame in pairs(unitToFrame) do
            UpdateCombatIndicator(frame, unit);
        end
    end
end);

function SweepyBoop:SetupCombatIndicator()
    eventFrame:UnregisterAllEvents();
    if SweepyBoop.db.profile.misc.combatIndicator then
        -- Seems like UNIT_FLAGS is only fired for units that return true for UnitPlayerControlled
        eventFrame:RegisterUnitEvent(addon.UNIT_FLAGS, "player", "target", "focus");
        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
        eventFrame:RegisterEvent(addon.PLAYER_TARGET_CHANGED);
        eventFrame:RegisterEvent(addon.PLAYER_FOCUS_CHANGED);
        for unit, frame in pairs(unitToFrame) do
            UpdateCombatIndicator(frame, unit);
        end
    else
        for _, frame in pairs(unitToFrame) do
            if frame.combatIndicator then
                frame.combatIndicator:Hide();
            end
        end
    end
end
