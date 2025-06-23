local _, addon = ...;

local HiddenFrame = CreateFrame("Frame");
HiddenFrame:Hide();

local function UpdateBlizzArenaFrames(hide)
    -- LUA errors if trying to do it during combat
    -- 1x [ADDON_ACTION_BLOCKED] AddOn 'SweepyBoop' tried to call the protected function 'UNKNOWN()'.
    if InCombatLockdown() then return end

    if hide then
        CompactArenaFrame:SetParent(HiddenFrame);
    else
        CompactArenaFrame:SetParent(UIParent);
    end
end

-- We hide Blizzard arena frames by parenting it to a hidden frame
local eventFrame;

function SweepyBoop:SetupHideBlizzArenaFrames()
    if SweepyBoop.db.profile.misc.hideBlizzArenaFrames and ( Gladius or GladiusEx or sArena ) then
        if ( not eventFrame ) then
            eventFrame = CreateFrame("Frame");
            eventFrame:SetScript("OnEvent", function(self, event, ...)
                UpdateBlizzArenaFrames(true);
            end);
        end

        eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD); -- Don't need ZONE_CHANGED_NEW_AREA

        -- According to Blizzard interface code, these are the events that are likely to reshow CompactArenaFrame
        eventFrame:RegisterEvent(addon.ARENA_OPPONENT_UPDATE);
        eventFrame:RegisterEvent(addon.PVP_MATCH_STATE_CHANGED);
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
        UpdateBlizzArenaFrames(true); -- Do one-off hide initially
    else
        if eventFrame then
            eventFrame:UnregisterAllEvents();
        end
        UpdateBlizzArenaFrames(false); -- Restore Blizzard arena frames
    end
end
