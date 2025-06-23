local _, addon = ...;

local LCG = LibStub("LibCustomGlow-1.0");
local framePrefix = ( C_AddOns.IsAddOnLoaded("ElvUI") and "ElvUF_PartyGroup1UnitButton" ) or "CompactPartyFrameMember";

local threatColors = {
    [1] = {r = 1, g = 1, b = 0}, -- yellow
    [2] = {r = 1, g = 0.5, b = 0}, -- orange
    [3] = {r = 1, g = 0, b = 0}, -- red
};

local function GetThreatCounters()
    local threatCounters = {};

    for i = 1, addon.MAX_ARENA_SIZE do
        local guid = UnitGUID("arena" .. i .. "target");
        if guid then
            threatCounters[guid] = ( threatCounters[guid] or 0 ) + 1;
        end
    end

    return threatCounters;
end

local function ShowCustomAggroHighlight(frame, threatCount)
    if not frame.customAggroHighlight then
        local customAggroHighlight = CreateFrame("Frame", nil, frame);
        customAggroHighlight:SetAllPoints();
        frame.customAggroHighlight = customAggroHighlight;
    end

    local color = threatColors[threatCount];
    local thickness = SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightThickness;
    local speed = SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightAnimationSpeed;
    if speed == 0 then
        speed = 1e-10; -- Set to a very small frequency, essentially no animation
    end

    LCG.PixelGlow_Start(
        frame.customAggroHighlight, -- frame
        { color.r, color.g, color.b, SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightAlpha }, -- color
        16, -- number of frames
        0.025 * speed, -- frequency (default is 0.25)
        nil, -- actions.glow_length,
        thickness, -- actions.glow_thickness,
        nil, -- actions.glow_XOffset,
        nil, -- actions.glow_YOffset,
        false -- actions.glow_border and true or false,
        -- id
    );
end

local function HideCustomAggroHighlight(frame)
    if frame.customAggroHighlight then
        LCG.PixelGlow_Stop(frame.customAggroHighlight);
    end
end

function SweepyBoop:SetupRaidFrameAggroHighlight()
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent(addon.PLAYER_ENTERING_WORLD);
    if addon.PROJECT_MAINLINE then -- Between solo shuffle rounds (retail only)
        eventFrame:RegisterEvent(addon.ARENA_PREP_OPPONENT_SPECIALIZATIONS);
    end
    eventFrame:RegisterEvent(addon.UNIT_TARGET);
    eventFrame:RegisterEvent(addon.NAME_PLATE_UNIT_ADDED); -- For cases when stealthy classes appear (we need to run an update before they change target)
    eventFrame:SetScript("OnEvent", function (_, event, unitId)
        local shouldUpdate, hideAll;

        if ( not IsActiveBattlefieldArena() ) or ( not SweepyBoop.db.profile.raidFrames.raidFrameAggroHighlightEnabled ) then -- not in arena or feature disabled
            hideAll = true;
        else
            if event == addon.UNIT_TARGET then
                shouldUpdate = ( unitId == "arena1" ) or ( unitId == "arena2" ) or ( unitId == "arena3" );
            else
                shouldUpdate = true;
            end
        end

        if hideAll then
            for i = 1, 6 do -- 3 players and 3 pets in arena
                local frame = _G[framePrefix .. i];
                if frame then
                    if frame.aggroHighlight then
                        frame.aggroHighlight:SetAlpha(1);
                    end
                    HideCustomAggroHighlight(frame);
                end
            end
        elseif shouldUpdate then
            local threatCounts = GetThreatCounters();
            for i = 1, 6 do -- 3 players and 3 pets in arena
                local frame = _G[framePrefix .. i];
                if frame then
                    if frame.aggroHighlight then
                        frame.aggroHighlight:SetAlpha(0);
                    end

                    local unitGUID = frame.unit and UnitGUID(frame.unit);
                    local threatCount = unitGUID and threatCounts[unitGUID];
                    if threatCount then
                        ShowCustomAggroHighlight(frame, threatCount);
                    else
                        HideCustomAggroHighlight(frame);
                    end
                end
            end
        end
    end);
end
