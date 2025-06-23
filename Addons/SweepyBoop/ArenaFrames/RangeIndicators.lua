local _, addon = ...;

local class = addon.GetUnitClass("player");
local arenaFramePrefix = ( GladiusEx and "GladiusExButtonFramearena" ) or ( Gladius and "GladiusButtonFramearena" ) or ( sArena and "sArenaEnemyFrame" ) or "CompactArenaFrameMember";

local function EnsureIndicator(frame)
    local config = SweepyBoop.db.profile.misc;

    if not frame.rangeIndicator then
        frame.rangeIndicator = CreateFrame("Frame", nil, frame);
        local size = config.rangeCheckerSize;
        frame.rangeIndicator:SetSize(size, size);
        frame.rangeIndicator:SetPoint("CENTER", frame, "CENTER", config.rangeCheckerOffsetX, config.rangeCheckerOffsetY);
        frame.rangeIndicator:SetMouseClickEnabled(false);

        frame.rangeIndicator.tex = frame.rangeIndicator:CreateTexture(nil, "OVERLAY");
        frame.rangeIndicator.tex:SetAllPoints();
        frame.rangeIndicator.tex:SetAtlas("CircleMaskScalable");
        frame.rangeIndicator.tex:SetVertexColor(0, 1, 0); -- Green

        frame.rangeIndicator:Hide();

        frame.rangeIndicator.lastModified = config.lastModified;
    end

    if frame.rangeIndicator.lastModified ~= config.lastModified then
        local size = config.rangeCheckerSize;
        frame.rangeIndicator:SetSize(size, size);
        frame.rangeIndicator:SetPoint("CENTER", frame, "CENTER", config.rangeCheckerOffsetX, config.rangeCheckerOffsetY);
        frame.rangeIndicator.lastModified = config.lastModified;
    end
end

local function ShowIndicator(frame)
    EnsureIndicator(frame);
    frame.rangeIndicator:Show();
end

local function HideIndicator(frame)
    if frame.rangeIndicator then
        frame.rangeIndicator:Hide();
    end
end

local function HideAll()
    for i = 1, addon.MAX_ARENA_SIZE do
        local frame = _G[arenaFramePrefix .. i];
        if frame and frame.rangeIndicator then
            HideIndicator(frame);
        end
    end
end

local function UpdateIndicators()
    local config = SweepyBoop.db.profile.misc;
    for i = 1, addon.MAX_ARENA_SIZE do
        local frame = _G[arenaFramePrefix .. i];
        if frame and frame:IsShown() then
            local spell = config.rangeCheckerSpells[class];
            if C_Spell.IsSpellInRange(spell, "arena" .. i) then
                ShowIndicator(frame);
            else
                HideIndicator(frame);
            end
        else
            HideIndicator(frame);
        end
    end
end

function SweepyBoop:TestRangeChecker()
    if IsInInstance() then
        addon.PRINT("Test mode can only be used outside instances");
        return;
    end

    if GladiusEx then
        local frame = _G["GladiusExButtonFramearena1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            GladiusEx:SetTesting(3);
        end
    elseif Gladius then
        local frame = _G["GladiusButtonFramearena1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            if SlashCmdList["GLADIUS"] then
                SlashCmdList["GLADIUS"]("test 3")
            end
        end
    elseif sArena then
        local frame = _G["sArenaEnemyFrame1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            sArena:Test();
        end
    else
        -- Use Blizzard arena frames
        if ( not CompactArenaFrame:IsShown() ) then
            CompactArenaFrame:Show();
            for i = 1, addon.MAX_ARENA_SIZE do
                _G["CompactArenaFrameMember" .. i]:Show();
            end
        end
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        local frame = _G[arenaFramePrefix .. i];
        if frame and frame:IsShown() then
            ShowIndicator(frame);
        end
    end
end

function SweepyBoop:HideTestRangeChecker()
    HideAll();
end

function SweepyBoop:RefreshRangeCheckerTestMode()
    if IsInInstance() then -- Test mode can only be used outside instances
        return;
    end

    for i = 1, addon.MAX_ARENA_SIZE do
        local frame = _G[arenaFramePrefix .. i];
        if frame and frame.rangeIndicator and frame.rangeIndicator:IsShown() then
            EnsureIndicator(frame);
        end
    end
end

local refreshFrame;
local eventFrame;
function SweepyBoop:SetupRangeChecker()
    if ( not refreshFrame ) then
        refreshFrame = CreateFrame("Frame");
        refreshFrame.timer = 0;
        refreshFrame:SetScript("OnUpdate", function (self, elapsed)
            self.timer = self.timer + elapsed;
            if self.timer > 0.01 then
                UpdateIndicators();
                self.timer = 0;
            end
        end)
        refreshFrame:Hide();
    end

    if ( not eventFrame ) then
        eventFrame = CreateFrame("Frame");
        eventFrame:RegisterEvent("PVP_MATCH_ACTIVE");
        eventFrame:RegisterEvent("PVP_MATCH_COMPLETE");
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
        eventFrame:SetScript("OnEvent", function (self, event)
            local isEnabled = SweepyBoop.db.profile.misc.rangeCheckerEnabled;
            if event == "PLAYER_ENTERING_WORLD" then
                refreshFrame:SetShown(isEnabled and IsActiveBattlefieldArena()); -- If somehow we loaded during an arena game
                HideAll(); -- Hide test indicators
            elseif event == "PVP_MATCH_ACTIVE" then
                refreshFrame:SetShown(isEnabled and IsActiveBattlefieldArena()); -- This should be the proper handler to start tracking
            elseif event == "PVP_MATCH_COMPLETE" then
                refreshFrame:Hide();
                HideAll();
            end
        end)
    end

    -- If somehow we loaded during an arena game
    refreshFrame:SetShown(SweepyBoop.db.profile.misc.rangeCheckerEnabled and IsActiveBattlefieldArena());
    -- Hide initially, in case we are disabling the feature
    -- The next frame will refresh them if we are in an arena with feature enabled
    HideAll();
end
