local _, addon = ...;

local frame = CreateFrame('Frame', nil , UIParent, "UIWidgetTemplateIconAndText");
local widgetSetInfo = C_UIWidgetManager.GetWidgetSetInfo(C_UIWidgetManager.GetTopCenterWidgetSetID());
frame:SetPoint(UIWidgetTopCenterContainerFrame.verticalAnchorPoint, UIWidgetTopCenterContainerFrame, UIWidgetTopCenterContainerFrame.verticalRelativePoint, 0, widgetSetInfo.verticalPadding);
frame.Text:SetParent(frame);
frame:SetWidth(200);
frame.Text:SetAllPoints();
frame.Text:SetJustifyH("CENTER");

frame:SetScript("OnEvent", function(self, ...) 
    if ( not SweepyBoop.db.profile.misc.showDampenPercentage ) then
        self:Hide();
        return;
    end

    local _, instanceType = IsInInstance();
    if instanceType == "arena" then
        self:Show();
    else
        self:Hide();
    end
end);
frame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);

local dampeningText = C_Spell.GetSpellInfo(110310).name; -- This doesn't change so set it as constant
local updateInterval = 1; -- We don't need to update on every UNIT_AURA, just update every 1 sec via keeping track of timeSinceLastUpdate
frame.timeSinceLastUpdate = 0;
frame:SetScript('OnUpdate', function(self, elapsed)
    -- This callback is not triggered whlie frame is hidden outside of arena, so no concern on perf
    if ( not SweepyBoop.db.profile.misc.showDampenPercentage ) then
        self:Hide(); -- Once hidden, this callback will no longer trigger
        return;
    end

    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed;
    if self.timeSinceLastUpdate > updateInterval then
        self.Text:SetText(dampeningText..': ' .. C_Commentator.GetDampeningPercent() .. '%');
        self.timeSinceLastUpdate = 0;
    end
end)
