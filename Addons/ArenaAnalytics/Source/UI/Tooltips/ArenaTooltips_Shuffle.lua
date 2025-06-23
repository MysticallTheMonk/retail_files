local _, ArenaAnalytics = ...; -- Addon Namespace
local ShuffleTooltip = ArenaAnalytics.ShuffleTooltip;
ShuffleTooltip.__index = ShuffleTooltip;

-- Local module aliases
local Helpers = ArenaAnalytics.Helpers;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local Tooltips = ArenaAnalytics.Tooltips;
local ArenaIcon = ArenaAnalytics.ArenaIcon;
local Internal = ArenaAnalytics.Internal;
local Options = ArenaAnalytics.Options;
local Constants = ArenaAnalytics.Constants;
local TablePool = ArenaAnalytics.TablePool;

-------------------------------------------------------------------------

--[[
  Shuffle Tooltip
    Summary
                Total Wins
        Average Round Duration?
        Most Deaths   (player name)
    Per round
                Round Number
                Duration
                Win/Loss 
                Team
                Enemy Team
        First Death
--]]

-------------------------------------------------------------------------

local tooltipSingleton = nil;
local currentRounds = nil;

local function CreateRoundEntryFrame(index, parent)
    -- Create a frame for the round entry
    local newFrame = CreateFrame("Frame", nil, parent);

    local height = 30;
    local borderWidth = 3.5;
    local width = parent:GetWidth() - 2 * borderWidth;

    local yOffset = 2;

    -- Set the size and position for the row (width should match parent)
    newFrame:SetSize(parent:GetWidth(), height)
    newFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", borderWidth, -(height * index + yOffset)) -- Stack vertically

    -- Create the left round background texture
    newFrame.bgLeft = newFrame:CreateTexture(nil, "BACKGROUND");
    newFrame.bgLeft:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight");
    newFrame.bgLeft:SetTexCoord(0, 0.9, 0, 1); -- Use part of the texture (you can tweak it)
    newFrame.bgLeft:SetPoint("TOPLEFT", newFrame, "TOPLEFT");
    newFrame.bgLeft:SetSize(width / 2, height);

    -- Create the right round background texture
    newFrame.bgRight = newFrame:CreateTexture(nil, "BACKGROUND");
    newFrame.bgRight:SetTexture("Interface\\WorldStateFrame\\WorldStateFinalScore-Highlight");
    newFrame.bgRight:SetTexCoord(1, 0.1, 0, 1); -- Mirror the texture for the right side
    newFrame.bgRight:SetPoint("TOPLEFT", newFrame.bgLeft, "TOPRIGHT");
    newFrame.bgRight:SetSize(width / 2, height);

    -- Add a label for the round number
    newFrame.roundText = newFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    newFrame.roundText:SetPoint("LEFT", newFrame, "LEFT", 10, 0);
    ArenaAnalytics:SetFrameText(newFrame.roundText, ((index or "?") .. ":"), Constants.valueColor)

    -- Duration
    newFrame.duration = newFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    newFrame.duration:SetPoint("RIGHT", newFrame, "RIGHT", -15, 0);

    -- Separator
    newFrame.separator = newFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
    newFrame.separator:SetPoint("CENTER", newFrame, -40, 0);
    ArenaAnalytics:SetFrameText(newFrame.separator, "  vs  ", Constants.valueColor);

    -- Teams
    newFrame.team = {};
    newFrame.enemyTeam = {};

    local playerPadding = 4;
    local separatorPadding = 15;

    -- Team
    local lastFrame = newFrame.separator;
    for i=3, 1, -1 do
        local iconFrame = ArenaIcon:Create(newFrame, 24);

        iconFrame:SetPoint("RIGHT", lastFrame, "LEFT", -2, 0);
        lastFrame = iconFrame;

        newFrame.team[i] = iconFrame;
    end

    -- Enemies
    lastFrame = newFrame.separator;
    for i=1, 3 do
        local iconFrame = ArenaIcon:Create(newFrame, 22);
        iconFrame:SetPoint("LEFT", lastFrame, "RIGHT", 2, 0);
        lastFrame = iconFrame;

        tinsert(newFrame.enemyTeam, iconFrame);
    end

    function newFrame:SetData(team, enemy, firstDeath, duration, outcome, selfPlayer, players)
        self:SetOutcomeColor(outcome);

        ArenaAnalytics:SetFrameText(self.duration, (duration and SecondsToTime(duration)), Constants.valueColor);

        for i=2, 0, -1 do
            local spec_id, isFirstDeath;

            if(team ~= nil) then
                local playerIndex = (i == 0) and 0 or tonumber(team:sub(i,i));
                if(playerIndex) then
                    local player = (playerIndex == 0) and selfPlayer or players[playerIndex];
                    spec_id = ArenaMatch:GetPlayerSpec(player);
                    isFirstDeath = (playerIndex == firstDeath);
                end
            end

            local playerIcon = self.team[i+1];
            playerIcon:SetSpec(spec_id, true);
            playerIcon:SetIsFirstDeath(isFirstDeath, true);
        end

        for i=1, 3 do
            local spec_id, isFirstDeath;

            if(enemy ~= nil) then
                local playerIndex = tonumber(enemy:sub(i,i));
                if(playerIndex) then
                    local player = players[playerIndex];
                    spec_id = ArenaMatch:GetPlayerSpec(player);                    
                    isFirstDeath = (playerIndex == firstDeath);
                end
            end

            local playerIcon = self.enemyTeam[i];
            playerIcon:SetSpec(spec_id, true);
            playerIcon:SetIsFirstDeath(isFirstDeath, true);
        end
    end

    -- Set background color based on round win or loss
    function newFrame:SetOutcomeColor(outcome)
        if(outcome == nil) then -- Grey for unknown
            newFrame.bgLeft:SetVertexColor(0.7, 0.7, 0.7, 0.8);
            newFrame.bgRight:SetVertexColor(0.7, 0.7, 0.7, 0.8);
        elseif(outcome == 1) then -- Green for win
            newFrame.bgLeft:SetVertexColor(0.19, 0.57, 0.11, 0.8);
            newFrame.bgRight:SetVertexColor(0.19, 0.57, 0.11, 0.8);
        elseif(outcome == 2) then -- Yellow for draw
            newFrame.bgLeft:SetVertexColor(0.8, 0.67, 0.1, 0.8);
            newFrame.bgRight:SetVertexColor(0.8, 0.67, 0.1, 0.8);
        else -- Red for loss
            newFrame.bgLeft:SetVertexColor(0.52, 0.075, 0.18, 0.8);
            newFrame.bgRight:SetVertexColor(0.52, 0.075, 0.18, 0.8);
        end
    end

    return newFrame;
end

-- Get existing shuffle tooltip, or create a new one
local function GetOrCreateSingleton()
    if(not tooltipSingleton) then
        local self = setmetatable({}, ShuffleTooltip);
        tooltipSingleton = self;

        self.frame = Helpers:CreateDoubleBackdrop(ArenaAnalyticsScrollFrame, self.name, "TOOLTIP")
        self.frame:SetSize(320, 1);

        self.title = ArenaAnalyticsCreateText(self.frame, "TOPLEFT", self.frame, "TOPLEFT", 10, -10, ArenaAnalytics:ColorText("Solo Shuffle", Constants.valueColor), 18);
        self.winsText = ArenaAnalyticsCreateText(self.frame, "TOPRIGHT", self.frame, "TOPRIGHT", -10, -10, "", 15);

        self.rounds = {}

        for i=1, 6 do
            self.rounds[i] = CreateRoundEntryFrame(i, self.frame);
        end

        self.bottomStatTexts = {}

        ArenaAnalytics:Log("Created new Shuffle Tooltip singleton!");
    end

    assert(tooltipSingleton);
    return tooltipSingleton;
end

local function ClearBottomStats()
    local self = GetOrCreateSingleton(); -- Tooltip singleton

    for i=1, #self.bottomStatTexts do
        self.bottomStatTexts[i]:SetText("");
        self.bottomStatTexts[i] = nil;
    end

    TablePool:Release(self.bottomStatTexts);
    self.bottomStatTexts = TablePool:Acquire();
end

local function AddBottomStat(prefix, name, value, spec_id)
    if(not prefix or not value) then
        return;
    end

    local self = GetOrCreateSingleton(); -- Tooltip singleton

    prefix = ArenaAnalytics:ColorText(prefix, Constants.prefixColor);
    value = ArenaAnalytics:ColorText(value, Constants.statsColor);

    -- Player Name
    if(name) then
        local classColor = Internal:GetClassColor(spec_id);
        name = ArenaAnalytics:ColorText(name, classColor);
    end

    local yOffset = #self.bottomStatTexts * 15 + 10;
    
    local text = nil;
    if(name) then
        local textFormat = "%s %s  %s";
        text = string.format(textFormat, prefix, name, value);
    else
        local textFormat = "%s: %s";
        text = string.format(textFormat, prefix, value);
    end

    local fontString = ArenaAnalyticsCreateText(self.frame, "BOTTOMLEFT", self.frame, "BOTTOMLEFT", 10, yOffset, text, 12);
    tinsert(self.bottomStatTexts, fontString);
end

local function SetText(frame, text, yOffset)
    if(frame) then
        frame:SetText("");
    end

    frame = ArenaAnalyticsCreateText(self.frame, "BOTTOMLEFT", self.frame, "BOTTOMLEFT", 10, yOffset, text, 12);
end

function ShuffleTooltip:SetMatch(match)
    local self = GetOrCreateSingleton();

    if(not ArenaMatch:IsShuffle(match)) then
        ShuffleTooltip:Hide();
        return;
    end

    Tooltips:HideAll();

    
    local newHeight = 35;
    local wins = 0;
    local deaths = TablePool:Acquire();

    local selfPlayer = ArenaMatch:GetSelf(match);
    local players = ArenaMatch:GetTeam(match, true);

    currentRounds = ArenaMatch:GetRounds(match);
    for i=1, 6 do
        local roundFrame = self.rounds[i];
        assert(roundFrame, "ShuffleTooltip should always have 6 round frames!" .. (self.rounds and #self.rounds or "nil"));

        local roundData = currentRounds and ArenaMatch:GetRoundDataRaw(currentRounds[i]);
        if(roundData) then
            newHeight = newHeight + roundFrame:GetHeight();

            local team, enemy, firstDeath, duration, outcome = ArenaMatch:SplitRoundData(roundData);

            if(firstDeath) then
                deaths[firstDeath] = (deaths[firstDeath] or 0) + 1;
            end

            roundFrame:SetData(team, enemy, firstDeath, duration, outcome, selfPlayer, players);

            if(outcome == 1) then
                wins = wins + 1;
            end

            roundFrame:Show();
        else
            roundFrame:Hide();
        end
    end

    -- Combine top score text
    local function GetTopScore(values)
        local bestIndex, highestCount;
        for playerIndex, deaths in pairs(values) do
            if(not bestIndex or highestCount and highestCount < deaths) then
                bestIndex = playerIndex;
                highestCount = deaths;
            end
        end

        if(bestIndex and highestCount) then
            local player = (bestIndex == 0) and selfPlayer or players[bestIndex];
            if(player) then
                local spec_id = ArenaMatch:GetPlayerSpec(player);
                local name = ArenaMatch:GetPlayerFullName(player, true);
                return name, highestCount, spec_id;
            end
        end

        return nil;
    end

    ClearBottomStats();

    -- Most Deaths
    local name, value, spec_id = GetTopScore(deaths);
    AddBottomStat("Most Deaths:", name, value, spec_id);

    -- Most Wins
    local winsTable = {}
    local function AddWins(player, playerIndex)
        local wins = player and ArenaMatch:GetPlayerVariableStats(player);
        if(wins) then
            winsTable[playerIndex] = wins;
        end
    end

    AddWins(selfPlayer, 0);
    for i,player in ipairs(players) do
        AddWins(player, i);
    end

    name, value, spec_id = GetTopScore(winsTable);
    AddBottomStat("Most Wins:", name, value, spec_id);

    TablePool:Release(deaths);
    TablePool:Release(winsTable);

    -- Win color
    local hex = Constants.invalidColor;
    if(wins ~= nil) then
        if(wins == 3) then
            hex = Constants.drawColor;
        else
            hex = (wins > 3) and Constants.winColor or Constants.lossColor;
        end
    end

    -- Set total wins text
    ArenaAnalytics:SetFrameText(self.winsText, "Wins: " .. wins, hex);

    local newHeight = newHeight + #self.bottomStatTexts * 15 + 10;

    -- Update dynamic background height
    self.frame:SetHeight(newHeight);
end

function ShuffleTooltip:SetEntryFrame(frame)
    if(not frame) then
        ShuffleTooltip:Hide();
        return;
    end

    local self = GetOrCreateSingleton();
    self.parent = frame;

    -- TODO: Put it on top if the dropdown would go off screen
    local doesFitUnder = true; -- Temp

    if(doesFitUnder) then
        self.frame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT");
    else
        self.frame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT");
    end
end

function ShuffleTooltip:Show()
    local self = GetOrCreateSingleton();

    if(self.parent) then
        self.parent.isShowingTooltip = true;
    end

    self.frame:Show();
end

function ShuffleTooltip:Hide()
    local self = GetOrCreateSingleton();
    
    if(self.parent) then
        self.parent.isShowingTooltip = nil;
    end

    self.frame:Hide();
end