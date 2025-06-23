local _, ArenaAnalytics = ...; -- Addon Namespace
local PlayerTooltip = ArenaAnalytics.PlayerTooltip;
PlayerTooltip.__index = PlayerTooltip;

-- Local module aliases
local Tooltips = ArenaAnalytics.Tooltips;
local ArenaIcon = ArenaAnalytics.ArenaIcon;
local TablePool = ArenaAnalytics.TablePool;
local Helpers = ArenaAnalytics.Helpers;
local API = ArenaAnalytics.API;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local Internal = ArenaAnalytics.Internal;
local Options = ArenaAnalytics.Options;
local Constants = ArenaAnalytics.Constants;
local Debug = ArenaAnalytics.Debug;

-------------------------------------------------------------------------

--[[
  Shuffle Tooltip
    Header
        Class/Spec icon
        Full Name
        Race
        Spec
        Faction Icon
    Separator line
    Statistics
        Kills
        Deaths
        Damage
        Healing
        DPS
        HPS
        Rating / Rating Delta (Retail rated only)
        MMR / MMR Delta (Retail rated only)
        Wins (Shuffle only)
    Quick Search shortcuts
        Separator line
--]]

-------------------------------------------------------------------------

local tooltipSingleton = nil;

local baseWidth = 290;

local statsRowHeight = 15;
local statsPadding = 10;

-- General function to fill a container with a list of values
local function FillContainerValues(container, values, rowHeight, padding, yOffset)
    padding = padding or 0;
    yOffset = yOffset or 0;
    rowHeight = rowHeight - 0.3; -- Fix rounding layout issues

    -- Ensure the frames table exists on the container for reuse
    container.frames = container.frames or TablePool:Acquire();

    container.leftColumn = container.leftColumn or CreateFrame("Frame", nil, container);
    container.leftColumn:SetPoint("TOPLEFT", padding, 0);

    container.rightColumn = container.rightColumn or CreateFrame("Frame", nil, container);
    container.rightColumn:SetPoint("TOPLEFT", container.leftColumn, "TOPRIGHT", padding, 0);

    local isLeft = true;

    -- Assign minimum widths
    container.leftColumn.desiredWidth = baseWidth/2;
    container.rightColumn.desiredWidth = 0;

    local maxIndex = max(#values, #container.frames)
    for i = 1, maxIndex do
        local frame = container.frames[i];
        local value = values[i];

        if value == nil then
            -- Hide and clear extra font strings
            if frame then
                frame:SetText("")
                frame:Hide()
            end
        elseif(tonumber(value)) then
            if(i ~= #values) then
                -- Adjust yOffset for numerical spacer values
                yOffset = yOffset + tonumber(value);
                if(not isLeft) then
                    yOffset = yOffset + rowHeight;
                end

                isLeft = true;
            else
                ArenaAnalytics:Log("Ignoring number stat spacer", value)
            end
        else
            local column = isLeft and container.leftColumn or container.rightColumn;

            -- Create or reuse a font string for the value
            if not frame then
                frame = container:CreateFontString(nil, "OVERLAY", "GameFontNormal");
                container.frames[i] = frame;
            end

            frame:Show();
            frame:SetText(value);

            -- Position the value in either the left or right column
            frame:SetPoint("TOPLEFT", column, "TOPLEFT", -0.3, -yOffset);

            -- Check for increased required size
            if(frame:GetWidth() > column.desiredWidth) then
                column.desiredWidth = frame:GetWidth();
            end

            -- Update line offset
            if(i < #values and not isLeft or i == #values) then
                yOffset = yOffset + rowHeight;
            end

            isLeft = not isLeft;
        end
    end

    container.leftColumn:SetSize(container.leftColumn.desiredWidth, yOffset);
    container.rightColumn:SetSize(container.rightColumn.desiredWidth + padding, yOffset);

    local width = (2 * padding) + container.leftColumn:GetWidth() + container.rightColumn:GetWidth();
    container:SetSize(width, yOffset);
    return yOffset;
end

local function ClearContainer(container)
    if(not container.frames) then
        return;
    end

    for i=1, #container.frames do
        local frame = container.frames[i];
        if(frame) then
            frame:SetText("");
            frame:Hide();
        end
        container.frames[i] = nil;
    end

    container.frames = nil;
end

-- Get existing shuffle tooltip, or create a new one
local function GetOrCreateSingleton()
    if(not tooltipSingleton) then
        local self = setmetatable({}, PlayerTooltip);
        tooltipSingleton = self;

        self.frame = Helpers:CreateDoubleBackdrop(ArenaAnalyticsScrollFrame, "ArenaAnalyticsPlayerTooltip", "TOOLTIP");
        self.frame:Hide();

        self.icon = ArenaIcon:Create(self.frame, 36, true);
        self.icon:SetPoint("TOPLEFT", 8, -8);
        self.icon:SetFrameLevel(self.frame:GetFrameLevel());

        self.factionIcon = self.frame:CreateTexture(nil, "ARTWORK");
        self.factionIcon:SetSize(47,47);
        self.factionIcon:SetPoint("TOPRIGHT", -3, -8);
        self.factionIcon:SetTexture(134400);

        self.name = nil;
        self.info = ArenaAnalyticsCreateText(self.frame, "BOTTOMLEFT", self.icon, "BOTTOMRIGHT", 5, 1, "", 12);

        self.separator = self.frame:CreateTexture(nil, "ARTWORK")
        self.separator:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
        self.separator:SetSize(1,1);
        self.separator:SetPoint("TOPLEFT", self.icon, "BOTTOMLEFT", 0, 3);

        -- Statistics
        self.stats = TablePool:Acquire();
        self.statsContainer = CreateFrame("Frame", nil, self.frame);
        self.statsContainer:SetSize((self.frame:GetWidth() - 6), 25);
        self.statsContainer:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 3, -(self.icon:GetHeight() + 25));

        self.quickSearchContainer = CreateFrame("Frame", nil, self.frame);
        self.quickSearchContainer:SetPoint("TOPLEFT", self.statsContainer, "BOTTOMLEFT");
        self.quickSearchContainer:SetHeight(0);

        ArenaAnalytics:Log("Created new Player Tooltip singleton!");

        -- Update quick search tips
        PlayerTooltip:UpdateQuickSearchTips();
    end

    assert(tooltipSingleton);
    return tooltipSingleton;
end

function PlayerTooltip:OnSettingsChanged()
    local self = GetOrCreateSingleton();
    PlayerTooltip:UpdateQuickSearchTips();
end

function PlayerTooltip:UpdateQuickSearchTips()
    local self = GetOrCreateSingleton(); -- Tooltip singleton

    local container = CreateFrame("Frame", nil, self.frame);
    container:SetPoint("TOPLEFT", self.statsContainer, "BOTTOMLEFT");

    container.separator = container:CreateTexture(nil, "ARTWORK");
    container.separator:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent");
    container.separator:SetSize(container:GetWidth() - 10, 16);
    container.separator:SetPoint("TOPLEFT", container, "TOPLEFT", 5, 0);

    ClearContainer(container);

    local defaultAppendRule = Options:Get("quickSearchDefaultAppendRule");
    local defaultValue = Options:Get("quickSearchDefaultValue");

    local newSearchRuleShortcut = Options:Get("quickSearchAppendRule_NewSearch");
    local newSegmentRuleShortcut = Options:Get("quickSearchAppendRule_NewSegment");
    local sameSegmentRuleShortcut = Options:Get("quickSearchAppendRule_SameSegment");

    local inverseShortcut = Options:Get("quickSearchAction_Inverse");

    local clickedTeamShortcut = Options:Get("quickSearchAction_ClickedTeam");
    local teamShortcut = Options:Get("quickSearchAction_Team");
    local enemyShortcut = Options:Get("quickSearchAction_Enemy");

    local nameShortcut = Options:Get("quickSearchAction_Name");
    local specShortcut = Options:Get("quickSearchAction_Spec");
    local raceShortcut = Options:Get("quickSearchAction_Race");
    local factionShortcut = Options:Get("quickSearchAction_Faction");

    -- Combine entries to display
    local entries = TablePool:Acquire();

    tinsert(entries, "Quick Search Tips:");
    tinsert(entries, 0); -- Force new line

    local function TryInsertShortcut(descriptor, shortcut, forced)
        if(forced or shortcut and shortcut ~= "None") then
            descriptor = ArenaAnalytics:ColorText(descriptor, Constants.prefixColor);
            shortcut = ArenaAnalytics:ColorText(shortcut, Constants.statsColor);

            tinsert(entries, descriptor..shortcut);
        end
    end

    TryInsertShortcut("Rule: ", defaultAppendRule);
    TryInsertShortcut("Value: ", defaultValue);

    TryInsertShortcut("New Search: ", newSearchRuleShortcut);
    TryInsertShortcut("New Segment: ", newSegmentRuleShortcut);
    TryInsertShortcut("Same Segment: ", sameSegmentRuleShortcut);
    TryInsertShortcut("Inversed: ", inverseShortcut);

    -- Spacer
    tinsert(entries, statsRowHeight);

    TryInsertShortcut("Clicked Team: ", clickedTeamShortcut, true);
    tinsert(entries, 0);

    TryInsertShortcut("Team: ", teamShortcut, true);
    TryInsertShortcut("Enemy: ", enemyShortcut, true);
    TryInsertShortcut("Name: ", nameShortcut, true);
    TryInsertShortcut("Spec: ", specShortcut, true);
    TryInsertShortcut("Race: ", raceShortcut, true);
    TryInsertShortcut("Faction: ", factionShortcut, true);

    container.desiredHeight = FillContainerValues(container, entries, statsRowHeight, statsPadding, container.separator:GetHeight());

    -- Update dynamic visibility
    PlayerTooltip:UpdateQuickSearchVisibility();

    container:RegisterEvent("MODIFIER_STATE_CHANGED");    
    container:SetScript("OnEvent", function(frame)
        PlayerTooltip:UpdateQuickSearchVisibility();
        PlayerTooltip:RecomputeSize();
    end);

    self.quickSearchContainer = container;
    return container;
end

function PlayerTooltip:UpdateQuickSearchVisibility()
    local self = GetOrCreateSingleton(); -- Tooltip singleton

    self.shouldShowShortcuts = false;
    if(Options:Get("quickSearchEnabled") and Options:Get("searchShowTooltipQuickSearch")) then
        if(IsShiftKeyDown()) then
            self.shouldShowShortcuts = true;
        end
    end

    local container = self.quickSearchContainer;

    local isShown = container:IsShown() and container:GetHeight() > 0;
    if(self.shouldShowShortcuts == isShown) then
        return;
    end

    if(self.shouldShowShortcuts) then
        container:SetHeight(container.desiredHeight);
        container:Show();
    else
        container:SetHeight(0);
        container:Hide();
    end
end

function PlayerTooltip:SetInfo(race_id, spec_id)
    local race = Internal:GetRace(race_id);
    if(race) then
        local factionColor = Internal:GetRaceFactionColor(race_id);
        race = ArenaAnalytics:ColorText(race, factionColor);
    end

    local class, spec = Internal:GetClassAndSpec(spec_id);

    local specialization = nil;
    if(class and spec) then
        specialization = string.format("%s %s", spec, class);
    else
        specialization = class or spec or "";
    end

    if(specialization ~= "") then
        local color = Internal:GetClassColor(spec_id) or "ffffff";
        specialization = ArenaAnalytics:ColorText(specialization, color);
    end

    local text = race and string.format("%s  %s", race, specialization) or specialization;

    local self = GetOrCreateSingleton(); -- Tooltip singleton
    self.info:SetText(text);
end

function PlayerTooltip:SetFaction(race_id)
    faction = tonumber(race_id) and tonumber(race_id) % 2;

    local texture = "";
    if(faction == 0) then
        texture = "Interface\\FriendsFrame\\PlusManz-Horde";
    elseif(faction == 1) then
        texture = "Interface\\FriendsFrame\\PlusManz-Alliance";
    end

    local self = GetOrCreateSingleton(); -- Tooltip singleton
    self.factionIcon:SetTexture(texture);
end

function PlayerTooltip:ClearStats()
    local self = GetOrCreateSingleton(); -- Tooltip singleton

    TablePool:Release(self.stats);
    self.stats = TablePool:Acquire();
end

function PlayerTooltip:AddStatistic(prefix, text)
    prefix = ArenaAnalytics:ColorText(prefix, Constants.prefixColor);
    text = ArenaAnalytics:ColorText(text, Constants.statsColor);

    local self = GetOrCreateSingleton(); -- Tooltip singleton
    tinsert(self.stats, prefix .. text);
end

function PlayerTooltip:AddNumberStatistic(prefix, value)
    value = Helpers:FormatNumber(value);
    PlayerTooltip:AddStatistic(prefix, value);
end

function PlayerTooltip:AddRatingStatistic(prefix, value, delta)
    local text = tonumber(value) or "-";
    delta = tonumber(delta);

    -- Format or hide delta
    if(delta and (delta ~= 0 or not Options:Get("hidePlayerTooltipZeroRatingDelta"))) then
        local hex = nil;

        if(delta > 0) then
            delta = "+"..delta;
            hex = Constants.winColor;
        else
            hex = (delta < 0) and Constants.lossColor or Constants.drawColor;
        end

        text = text .. ArenaAnalytics:ColorText(" ("..delta..")", hex);
    end

    PlayerTooltip:AddStatistic(prefix, text);
end

-- Skips to new line, optionally adding a y offset.
function PlayerTooltip:AddSpacer(offset)
    offset = offset or 0;
    tinsert(self.stats, offset);
end

-- Updated PlayerTooltip:DrawStats using the general FillContainerValues function
function PlayerTooltip:DrawStats()
    local self = GetOrCreateSingleton() -- Tooltip singleton
    FillContainerValues(self.statsContainer, self.stats, statsRowHeight, statsPadding);
end

local function SetNameText(text)
    local self = GetOrCreateSingleton();

    -- Remove any existing name font string
    if self.name then
        self.name:SetText("");
        self.name:Hide();
        self.name = nil;
    end

    -- Desired font size and limits
    local desiredSize = 18;
    local minSize = 14;
    local widthLimit = baseWidth - PlayerTooltip:GetStaticHeaderWidth();
    local russianFontAdjustment = 1;

    -- Create a new font string
    self.name = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    self.name:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 5, -1);
    self.name:SetText(text or "");

    -- Get the current font to check if it is the one used for Russian text
    local fontPath, fontHeight, fontFlags = self.name:GetFont();

    -- Adjust the font size if it detects the Russian font
    -- Replace "your_russian_font_path" with the actual font file path for Russian
    if(fontPath == "Fonts\\FRIZQT___CYR.TTF") then
        desiredSize = desiredSize + russianFontAdjustment
    end

    -- Set the initial font size
    self.name:SetFont(fontPath, desiredSize, fontFlags)

    -- Measure the text width in pixels
    local textWidth = self.name:GetStringWidth()

    -- Adjust the size based on the text width exceeding the maximum allowed width
    local size = desiredSize
    if textWidth > widthLimit then
        local scaleFactor = (widthLimit / textWidth);
        size = max(desiredSize * scaleFactor, minSize);
    end

    -- Apply the adjusted font size
    self.name:SetFont(fontPath, size, fontFlags);

    -- Ensure the name font string is shown
    self.name:Show()
end

function PlayerTooltip:Reset()
    PlayerTooltip:Hide();

    local self = GetOrCreateSingleton();
    self.parent = nil;
end

function PlayerTooltip:SetPlayerFrame(frame)
    if(not frame or not frame.player) then
        PlayerTooltip:Reset();
        return;
    end

    Tooltips:HideAll();

    local self = GetOrCreateSingleton();
    self.parent = frame;

    local name = ArenaMatch:GetPlayerFullName(frame.player, true);
    local race_id = ArenaMatch:GetPlayerRace(frame.player);
    local spec_id = ArenaMatch:GetPlayerSpec(frame.player);

    self.icon:SetSpec(spec_id);
    SetNameText(name);
    PlayerTooltip:SetInfo(race_id, spec_id);
    PlayerTooltip:SetFaction(race_id);

    -- Reset stats
    PlayerTooltip:ClearStats();

    local kills, deaths, damage, healing = ArenaMatch:GetPlayerStats(frame.player);

    PlayerTooltip:AddNumberStatistic("Kills: ", kills);
    PlayerTooltip:AddNumberStatistic("Deaths: ", deaths);
    PlayerTooltip:AddNumberStatistic("Damage: ", damage);
    PlayerTooltip:AddNumberStatistic("Healing: ", healing);

    -- DPS / HPS
    local duration = ArenaMatch:GetDuration(frame.match);
    if(duration and duration > 0) then
        local dps = damage and damage / duration or "-";
        local hps = healing and healing / duration or "-";

        PlayerTooltip:AddNumberStatistic("DPS: ", dps);
        PlayerTooltip:AddNumberStatistic("HPS: ", hps);
    end

    -- Player Rating Info
    if(ArenaMatch:IsRated(frame.match)) then
        local rating, ratingDelta, mmr, mmrDelta = ArenaMatch:GetPlayerRatedInfo(frame.player);
        if(rating or API.showPerPlayerRatedInfo) then
            PlayerTooltip:AddRatingStatistic("Rating: ", rating, ratingDelta);
        end

        if(mmr or API.showPerPlayerRatedInfo) then
            PlayerTooltip:AddRatingStatistic("MMR: ", mmr, mmrDelta);
        end
    end

    if(ArenaMatch:IsShuffle(frame.match)) then
        PlayerTooltip:AddShuffleStats(frame);
    end

    -- Draw in the added stats
    PlayerTooltip:DrawStats();

    self.parent = frame;
    self.frame:SetPoint("TOPLEFT", self.parent, "TOPRIGHT");
    PlayerTooltip:Show();
end

function PlayerTooltip:AddShuffleStats(frame)
    local wins = ArenaMatch:GetPlayerVariableStats(frame.player);
    PlayerTooltip:AddNumberStatistic("Wins: ", wins);
end

local function GetLeftColumnWidth(container)
    if(not container or not container.leftColumn) then
        return 0;
    end

    return container.leftColumn:GetWidth();
end

function PlayerTooltip:RecomputeSize()
    if(not PlayerTooltip:IsValid()) then
        PlayerTooltip:Hide();
        return;
    end

    local self = GetOrCreateSingleton(); -- Tooltip singleton

    -- Update left column widths
    if(self.quickSearchContainer) then
        local bestWidth = max(GetLeftColumnWidth(self.statsContainer), GetLeftColumnWidth(self.quickSearchContainer));

        if(self.statsContainer.leftColumn) then
            self.statsContainer.leftColumn:SetWidth(bestWidth);
        end

        if(self.quickSearchContainer.leftColumn) then
            self.quickSearchContainer.leftColumn:SetWidth(bestWidth);
        end
    end

    local width, height = PlayerTooltip:GetRequiredSize();
    PlayerTooltip:SetSize(width+7, height);
end

function PlayerTooltip:GetStaticHeaderWidth()
    local self = GetOrCreateSingleton(); -- Tooltip singleton
    return 11 + self.icon:GetWidth() + self.factionIcon:GetWidth();
end

function PlayerTooltip:GetRequiredSize()
    local self = GetOrCreateSingleton(); -- Tooltip singleton

    -- Header
    local headerHeight = 25 + self.icon:GetHeight();

    local longestHeaderText = max(self.name:GetWidth(), self.info:GetWidth());
    local headerWidth = PlayerTooltip:GetStaticHeaderWidth() + longestHeaderText;

    -- Stats
    local statsWidth, statsHeight = self.statsContainer:GetSize();

    -- Quick Search
    local quickSearchWidth, quickSearchHeight = self.quickSearchContainer:GetSize();

    -- Tooltip sizing
    local longestWidth = max(headerWidth, statsWidth, quickSearchWidth);
    local totalHeight = headerHeight + statsHeight + quickSearchHeight + 10;

    return longestWidth, totalHeight;
end

function PlayerTooltip:SetSize(x,y)
    local self = GetOrCreateSingleton(); -- Tooltip singleton
    self.frame:SetSize(x, y);

    self.separator:SetSize(x - self.factionIcon:GetWidth() - 5, 16);

    if(self.quickSearchContainer and self.quickSearchContainer.separator) then
        self.quickSearchContainer.separator:SetSize(x - 19.5, 16);
    end
end

function PlayerTooltip:SetPoint(...)
    local self = GetOrCreateSingleton();
    self.frame:SetPoint(...);
end

function PlayerTooltip:Show()
    local self = GetOrCreateSingleton();
    PlayerTooltip:UpdateQuickSearchVisibility();
    PlayerTooltip:RecomputeSize();

    if(self.parent) then
        self.parent.isShowingTooltip = true;
    end

    self.frame:Show();
end

function PlayerTooltip:Hide()
    if(self.parent) then
        self.parent.isShowingTooltip = nil;
    end

    local self = GetOrCreateSingleton();
    self.frame:Hide();
end

function PlayerTooltip:IsValid()
    local self = GetOrCreateSingleton();
    return self and self.icon and self.name and self.info and self.statsContainer;
end