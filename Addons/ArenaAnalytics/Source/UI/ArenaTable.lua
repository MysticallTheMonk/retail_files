local _, ArenaAnalytics = ...; -- Addon Namespace
local AAtable = ArenaAnalytics.AAtable;
HybridScrollMixin = ArenaAnalytics.AAtable; -- HybridScroll.xml wants access to this

-- Local module aliases
local Options = ArenaAnalytics.Options;
local Filters = ArenaAnalytics.Filters;
local FilterTables = ArenaAnalytics.FilterTables;
local Search = ArenaAnalytics.Search;
local Dropdown = ArenaAnalytics.Dropdown;
local Selection = ArenaAnalytics.Selection;
local API = ArenaAnalytics.API;
local Import = ArenaAnalytics.Import;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local Internal = ArenaAnalytics.Internal;
local Constants = ArenaAnalytics.Constants;
local ImportBox = ArenaAnalytics.ImportBox;
local ArenaIcon = ArenaAnalytics.ArenaIcon;
local Helpers = ArenaAnalytics.Helpers;
local Tooltips = ArenaAnalytics.Tooltips;
local PlayerTooltip = ArenaAnalytics.PlayerTooltip;
local Sessions = ArenaAnalytics.Sessions;

-------------------------------------------------------------------------

local hasLoaded = false;

function ArenaAnalytics:ColorText(text, color)
    text = text or "";

    if(not color) then
        return text;
    end

    if(#color == 6) then
        color = "ff" .. color;
    end

    return "|c" .. color .. text .. "|r"
end

function ArenaAnalytics:SetFrameText(frame, text, color)
    assert(frame and frame.SetText, "Invalid frame provided for SetText.");

    text = ArenaAnalytics:ColorText(text, color);
    frame:SetText(text);
end

-- Filtered stats
local wins, sessionGames, sessionWins = 0, 0, 0;

function AAtable:GetDropdownTemplate(overrideTemplate)
    return overrideTemplate or API.defaultButtonTemplate or "UIPanelButtonTemplate";
end

-- Returns button based on params
function AAtable:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text, template)
    local btn = CreateFrame("Button", nil, relativeFrame, AAtable:GetDropdownTemplate(template));
    btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);

    local height = (template == "UIPanelButtonTemplate" and 35 or 25);
    btn:SetSize(120, height);

    btn:SetText(text);
    btn:SetNormalFontObject("GameFontHighlight");
    btn:SetHighlightFontObject("GameFontHighlight");
    btn:SetDisabledFontObject("GameFontDisableSmall");
    
    if(btn.money) then
        btn.money:Hide();
    end
    
    return btn;
end

-- Returns string frame
function ArenaAnalyticsCreateText(parent, anchor, relativeFrame, relPoint, xOff, yOff, text, fontSize)
    local fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    fontString:SetPoint(anchor, relativeFrame, relPoint, xOff, yOff);
    fontString:SetText(text);
    fontString:SetFont(fontString:GetFont(), tonumber(fontSize) or 12, "");
    return fontString
end

local function CreateFilterTitle(filterFrame, text, info, offsetX, size)
    text = ArenaAnalytics:ColorText(text, Constants.headerColor);

    filterFrame.title = ArenaAnalyticsCreateText(filterFrame, "TOPLEFT", filterFrame, "TOPLEFT", offsetX or 2, 15, text, size);

    if(info) then
        info = ArenaAnalytics:ColorText(info, Constants.infoColor);
        filterFrame.title.info = ArenaAnalyticsCreateText(filterFrame, "TOPRIGHT", filterFrame, "TOPRIGHT", -5, 11, info, 8);

        if(not Options:Get("showCompDropdownInfoText")) then
            filterFrame.title.info:Hide();
        end
    end
end

-- Creates addOn text, filters, table headers
function AAtable:OnLoad()
    ArenaAnalyticsScrollFrame:SetFrameStrata("HIGH");

    ArenaAnalyticsScrollFrame.ListScrollFrame.update = function() AAtable:RefreshLayout(); end

    ArenaAnalyticsScrollFrame.filterCompsDropdown = {}
    ArenaAnalyticsScrollFrame.filterEnemyCompsDropdown = {}

    HybridScrollFrame_SetDoNotHideScrollBar(ArenaAnalyticsScrollFrame.ListScrollFrame, true);
    ArenaAnalyticsScrollFrame.Bg:SetColorTexture(0, 0, 0, 0.8);
    ArenaAnalyticsScrollFrame.TitleBg:SetColorTexture(0,0,0,0.8);

    -- Add the addon title to the main frame
    ArenaAnalyticsScrollFrame.title = ArenaAnalyticsScrollFrame:CreateFontString(nil, "OVERLAY");
    ArenaAnalyticsScrollFrame.title:SetPoint("CENTER", ArenaAnalyticsScrollFrame.TitleBg, "CENTER", 0, 0);
    ArenaAnalyticsScrollFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "");
    ArenaAnalyticsScrollFrame.title:SetText("Arena Analytics");

    -- Add the version to the main frame header
    ArenaAnalyticsScrollFrame.titleVersion = ArenaAnalyticsScrollFrame:CreateFontString(nil, "OVERLAY");
    ArenaAnalyticsScrollFrame.titleVersion:SetPoint("LEFT", ArenaAnalyticsScrollFrame.title, "RIGHT", 10, -1);
    ArenaAnalyticsScrollFrame.titleVersion:SetFont("Fonts\\FRIZQT__.TTF", 11, "");
    ArenaAnalyticsScrollFrame.titleVersion:SetText("|cff909090v" .. API:GetAddonVersion() .. "|r");

    ArenaAnalyticsScrollFrame.searchBox = CreateFrame("EditBox", "searchBox", ArenaAnalyticsScrollFrame, "SearchBoxTemplate")
    ArenaAnalyticsScrollFrame.searchBox:SetPoint("TOPLEFT", ArenaAnalyticsScrollFrame, "TOPLEFT", 35, -47);
    ArenaAnalyticsScrollFrame.searchBox:SetSize(225, 25);
    ArenaAnalyticsScrollFrame.searchBox:SetAutoFocus(false);
    ArenaAnalyticsScrollFrame.searchBox:SetMaxBytes(1024);

    local searchTitle = Options:Get("searchDefaultExplicitEnemy") and "Enemy Search" or "Search";
    CreateFilterTitle(ArenaAnalyticsScrollFrame.searchBox, searchTitle, nil, -5);

    ArenaAnalyticsScrollFrame.searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus();
        Search:CommitSearch(self:GetText());
    end);

    ArenaAnalyticsScrollFrame.searchBox:SetScript("OnEscapePressed", function(self) 
        self:SetText(Search:GetLastDisplay());
        self:ClearFocus();
    end);

    local superOnTextChanged = ArenaAnalyticsScrollFrame.searchBox:GetScript("OnTextChanged");
    ArenaAnalyticsScrollFrame.searchBox:SetScript("OnTextChanged", function(self)
        assert(superOnTextChanged);
        superOnTextChanged(self);

        Search:Update(self:GetText());
    end);

    ArenaAnalyticsScrollFrame.searchBox:SetScript("OnTextSet", function(self) 
        if(self:GetText() == "" and not Search:IsEmpty()) then
            ArenaAnalytics:Log("Clearing search..");
            Search:CommitSearch("");
            self:SetText("");
        end
    end);

    -- Filter Bracket Dropdown
    ArenaAnalyticsScrollFrame.filterBracketDropdown = nil;
    ArenaAnalyticsScrollFrame.filterBracketDropdown = Dropdown:Create(ArenaAnalyticsScrollFrame, "Simple", "FilterBracket", FilterTables.brackets, 55, 35, 25);
    ArenaAnalyticsScrollFrame.filterBracketDropdown:SetPoint("LEFT", ArenaAnalyticsScrollFrame.searchBox, "RIGHT", 10, 0);

    CreateFilterTitle(ArenaAnalyticsScrollFrame.filterBracketDropdown:GetFrame(), "Bracket");

    AAtable:CreateDropdownForFilterComps(false); -- isEnemyComp == false
    AAtable:CreateDropdownForFilterComps(true);

    ArenaAnalyticsScrollFrame.settingsButton = CreateFrame("Button", nil, ArenaAnalyticsScrollFrame, "GameMenuButtonTemplate");
    ArenaAnalyticsScrollFrame.settingsButton:SetPoint("TOPLEFT", ArenaAnalyticsScrollFrame, "TOPRIGHT", -46, -1);
    ArenaAnalyticsScrollFrame.settingsButton:SetText([[|TInterface\Buttons\UI-OptionsButton:0|t]]);
    ArenaAnalyticsScrollFrame.settingsButton:SetNormalFontObject("GameFontHighlight");
    ArenaAnalyticsScrollFrame.settingsButton:SetHighlightFontObject("GameFontHighlight");
    ArenaAnalyticsScrollFrame.settingsButton:SetSize(24, 19);
    ArenaAnalyticsScrollFrame.settingsButton:SetScript("OnClick", function()
        local enableOldSettings = false;
        if not enableOldSettings then
            Options:Open();
        else
            if (not ArenaAnalyticsScrollFrame.settingsFrame:IsShown()) then  
                ArenaAnalyticsScrollFrame.settingsFrame:Show();
                ArenaAnalyticsScrollFrame.allowReset:SetChecked(false);
                ArenaAnalyticsScrollFrame.resetBtn:Disable();
            else
                ArenaAnalyticsScrollFrame.settingsFrame:Hide();
            end
        end
    end);

    -- Table headers
    local verticalPadding = -93;
    ArenaAnalyticsScrollFrame.dateTitle = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame,"BOTTOMLEFT", ArenaAnalyticsScrollFrame, "TOPLEFT", 30, verticalPadding, ArenaAnalytics:ColorText("Date", Constants.headerColor));
    ArenaAnalyticsScrollFrame.mapTitle = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "TOPLEFT", 150, verticalPadding, ArenaAnalytics:ColorText("Map", Constants.headerColor));
    ArenaAnalyticsScrollFrame.durationTitle = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "TOPLEFT", 210, verticalPadding, ArenaAnalytics:ColorText("Duration", Constants.headerColor));
    ArenaAnalyticsScrollFrame.teamTitle = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "TOPLEFT", 330, verticalPadding, ArenaAnalytics:ColorText("Team", Constants.headerColor));
    ArenaAnalyticsScrollFrame.ratingTitle = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "TOPLEFT", 490, verticalPadding, ArenaAnalytics:ColorText("Rating", Constants.headerColor));
    ArenaAnalyticsScrollFrame.mmrTitle = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "TOPLEFT", 600, verticalPadding, ArenaAnalytics:ColorText("MMR", Constants.headerColor));
    ArenaAnalyticsScrollFrame.enemyTeamTitle = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "TOPLEFT", 670, verticalPadding, ArenaAnalytics:ColorText("Enemy Team", Constants.headerColor));
    ArenaAnalyticsScrollFrame.enemyMmrTitle = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "TOPLEFT", 830, verticalPadding, ArenaAnalytics:ColorText("Enemy MMR", Constants.headerColor));

    -- Recorded arena number and winrate
    ArenaAnalyticsScrollFrame.sessionStats = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "BOTTOMLEFT", 30, 27, "");

    ArenaAnalyticsScrollFrame.overallStats = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "BOTTOMLEFT", 30, 10, "");

    local coloredSessionPrefix = ArenaAnalytics:ColorText("Session Duration: ", Constants.prefixColor);
    ArenaAnalyticsScrollFrame.sessionDuration = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "BOTTOM", -65, 27, coloredSessionPrefix);

    local selectedPrefixText = ArenaAnalytics:ColorText("Selected: ", Constants.prefixColor);
    ArenaAnalyticsScrollFrame.selectedStats = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMLEFT", ArenaAnalyticsScrollFrame, "BOTTOM", -65, 10, selectedPrefixText .. " (click matches to select)");

    Sessions:TryStartSessionDurationTimer();

    ArenaAnalyticsScrollFrame.clearSelected = AAtable:CreateButton("BOTTOMRIGHT", ArenaAnalyticsScrollFrame, "BOTTOMRIGHT", -30, 8, "Clear Selected", AAtable:GetDropdownTemplate());
    ArenaAnalyticsScrollFrame.clearSelected:SetWidth(110)
    ArenaAnalyticsScrollFrame.clearSelected:Hide();
    ArenaAnalyticsScrollFrame.clearSelected:SetScript("OnClick", function() Selection:ClearSelectedMatches() end);

    ArenaAnalyticsScrollFrame.unsavedWarning = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame, "BOTTOMRIGHT", ArenaAnalyticsScrollFrame, "BOTTOMRIGHT", -160, 13, unsavedWarningText);
    ArenaAnalyticsScrollFrame.unsavedWarning:Hide();
    ArenaAnalyticsScrollFrame.unsavedWarning:Show();

    -- First time user import popup if no matches are stored
    if (not ArenaAnalytics:HasStoredMatches()) then
        AAtable:TryShowimportDialogFrame(ArenaAnalyticsScrollFrame);
    end

    -- Add esc to close frame
    _G["ArenaAnalyticsScrollFrame"] = ArenaAnalyticsScrollFrame 
    tinsert(UISpecialFrames, ArenaAnalyticsScrollFrame:GetName()) 

    -- Make frame draggable
    ArenaAnalyticsScrollFrame:SetMovable(true)
    ArenaAnalyticsScrollFrame:EnableMouse(true)
    ArenaAnalyticsScrollFrame:RegisterForDrag("LeftButton")
    ArenaAnalyticsScrollFrame:SetScript("OnDragStart", ArenaAnalyticsScrollFrame.StartMoving)
    ArenaAnalyticsScrollFrame:SetScript("OnDragStop", ArenaAnalyticsScrollFrame.StopMovingOrSizing)
    ArenaAnalyticsScrollFrame:SetScript("OnHide", function()
        Dropdown:CloseAll();
    end);

    ArenaAnalyticsScrollFrame.specFrames = {}
    ArenaAnalyticsScrollFrame.deathFrames = {}

    HybridScrollFrame_CreateButtons(ArenaAnalyticsScrollFrame.ListScrollFrame, "ArenaAnalyticsScrollListMatch");

    ArenaAnalyticsScrollFrame.moreFiltersDrodown = Dropdown:Create(ArenaAnalyticsScrollFrame, "Comp", "MoreFilters", FilterTables.moreFilters, 90, 35, 25);
    ArenaAnalyticsScrollFrame.moreFiltersDrodown:SetPoint("LEFT", ArenaAnalyticsScrollFrame.filterEnemyCompsDropdown:GetFrame(), "RIGHT", 10, 0);

    ArenaAnalyticsScrollFrame.filterBtn_ClearFilters = AAtable:CreateButton("LEFT", ArenaAnalyticsScrollFrame.moreFiltersDrodown:GetFrame(), "RIGHT", 10, 0, "Clear", AAtable:GetDropdownTemplate());
    ArenaAnalyticsScrollFrame.filterBtn_ClearFilters:SetWidth(50);

    -- Clear all filters
    ArenaAnalyticsScrollFrame.filterBtn_ClearFilters:SetScript("OnClick", function() 
        ArenaAnalytics:Log("Clearing filters..");
        Filters:ResetAll(IsShiftKeyDown());
    end);

    -- Active Filters text count
    ArenaAnalyticsScrollFrame.activeFilterCountText = ArenaAnalyticsScrollFrame.moreFiltersDrodown:GetFrame():CreateFontString(nil, "OVERLAY")
    ArenaAnalyticsScrollFrame.activeFilterCountText:SetFont("Fonts\\FRIZQT__.TTF", 10, "");
    ArenaAnalyticsScrollFrame.activeFilterCountText:SetPoint("BOTTOM", ArenaAnalyticsScrollFrame.filterBtn_ClearFilters, "TOP", 0, 5);
    ArenaAnalyticsScrollFrame.activeFilterCountText:SetText("");

    hasLoaded = true;

    -- This will also update UI
    Filters:Refresh();

    -- Default to hidden
    ArenaAnalyticsScrollFrame:Hide();
end

function AAtable:TryShowimportDialogFrame(parent)
    if(ArenaAnalyticsScrollFrame.importDialogFrame == nil) then
        ArenaAnalyticsScrollFrame.importDialogFrame = CreateFrame("Frame", "ArenaAnalyticsImportFrame", parent or UIParent, "BasicFrameTemplateWithInset")
        ArenaAnalyticsScrollFrame.importDialogFrame:SetPoint("CENTER")
        ArenaAnalyticsScrollFrame.importDialogFrame:SetSize(440, 125)
        ArenaAnalyticsScrollFrame.importDialogFrame:SetFrameStrata("DIALOG");
        ArenaAnalyticsScrollFrame.importDialogFrame.title = ArenaAnalyticsScrollFrame.importDialogFrame:CreateFontString(nil, "OVERLAY");
        ArenaAnalyticsScrollFrame.importDialogFrame.title:SetPoint("TOP", ArenaAnalyticsScrollFrame.importDialogFrame, "TOP", -10, -5);
        ArenaAnalyticsScrollFrame.importDialogFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "");
        ArenaAnalyticsScrollFrame.importDialogFrame.title:SetText("Import");

        local supportedSourcesText = "|cffffffffPaste the |cff00ccffArenaStats|r or |cff00ccffREFlex|r import string in the edit box.|r";
        ArenaAnalyticsScrollFrame.importDialogFrame.Text1 = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame.importDialogFrame, "CENTER", ArenaAnalyticsScrollFrame.importDialogFrame, "TOP", 0, -45, supportedSourcesText);

        local noteText = "|cffCCCCCCNote:|r |cff888888Import may be missing data required for some filters.|r";
        ArenaAnalyticsScrollFrame.importDialogFrame.Text2 = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame.importDialogFrame, "CENTER", ArenaAnalyticsScrollFrame.importDialogFrame, "TOP", 0, -65, noteText);

        -- Import Edit Box
        ArenaAnalyticsScrollFrame.importDialogFrame.importBox = ImportBox:Create(ArenaAnalyticsScrollFrame.importDialogFrame, "ArenaAnalyticsImportDialogBox", 380, 25);
        ArenaAnalyticsScrollFrame.importDialogFrame.importBox:SetPoint("TOP", ArenaAnalyticsScrollFrame.importDialogFrame.Text2, "BOTTOM", 0, -8);
    end

    ArenaAnalyticsScrollFrame.importDialogFrame:SetParent(parent or UIParent);
    ArenaAnalyticsScrollFrame.importDialogFrame:Show();
end

-- Creates the Export DB frame
function AAtable:CreateExportDialogFrame()
    if (not ArenaAnalytics:HasStoredMatches()) then
        return;
    end

	if(ArenaAnalyticsScrollFrame.exportDialogFrame == nil) then
		ArenaAnalyticsScrollFrame.exportDialogFrame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
		ArenaAnalyticsScrollFrame.exportDialogFrame:SetFrameStrata("DIALOG");
		ArenaAnalyticsScrollFrame.exportDialogFrame:SetFrameLevel(10);
		ArenaAnalyticsScrollFrame.exportDialogFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
		ArenaAnalyticsScrollFrame.exportDialogFrame:SetSize(400, 150);

		-- Make frame draggable
		ArenaAnalyticsScrollFrame.exportDialogFrame:SetMovable(true)
		ArenaAnalyticsScrollFrame.exportDialogFrame:EnableMouse(true)
		ArenaAnalyticsScrollFrame.exportDialogFrame:RegisterForDrag("LeftButton")
		ArenaAnalyticsScrollFrame.exportDialogFrame:SetScript("OnDragStart", ArenaAnalyticsScrollFrame.exportDialogFrame.StartMoving)
		ArenaAnalyticsScrollFrame.exportDialogFrame:SetScript("OnDragStop", ArenaAnalyticsScrollFrame.exportDialogFrame.StopMovingOrSizing)

		ArenaAnalyticsScrollFrame.exportDialogFrame.Title = ArenaAnalyticsScrollFrame.exportDialogFrame:CreateFontString(nil, "OVERLAY");
		ArenaAnalyticsScrollFrame.exportDialogFrame.Title:SetPoint("TOP", ArenaAnalyticsScrollFrame.exportDialogFrame, "TOP", -10, -5);
		ArenaAnalyticsScrollFrame.exportDialogFrame.Title:SetFont("Fonts\\FRIZQT__.TTF", 12, "");
		ArenaAnalyticsScrollFrame.exportDialogFrame.Title:SetText("ArenaAnalytics Export");

		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame = CreateFrame("EditBox", "exportFrameEditbox", ArenaAnalyticsScrollFrame.exportDialogFrame, "InputBoxTemplate");
		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetPoint("CENTER", ArenaAnalyticsScrollFrame.exportDialogFrame, "CENTER");
		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetSize(350, 25);
		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetAutoFocus(true);
		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetFont("Fonts\\FRIZQT__.TTF", 10, "");
		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetMultiLine(false);
		ArenaAnalyticsScrollFrame.exportDialogFrame:Hide();

		ArenaAnalyticsScrollFrame.exportDialogFrame.WarningText = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame.exportDialogFrame,"BOTTOM", ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame, "TOP", 13, 0, "|cffff0000Warning:|r Pasting long string here will crash WoW!");
		ArenaAnalyticsScrollFrame.exportDialogFrame.totalText = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame.exportDialogFrame,"TOPLEFT", ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame, "BOTTOMLEFT", -3, 0, "Total arenas: " .. #ArenaAnalyticsDB);
		ArenaAnalyticsScrollFrame.exportDialogFrame.lengthText = ArenaAnalyticsCreateText(ArenaAnalyticsScrollFrame.exportDialogFrame,"TOPRIGHT", ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame, "BOTTOMRIGHT", -3, 0, "Export length: 0");

		ArenaAnalyticsScrollFrame.exportDialogFrame.selectBtn = AAtable:CreateButton("BOTTOM", ArenaAnalyticsScrollFrame.exportDialogFrame, "BOTTOM", 0, 17, "Select All");
		ArenaAnalyticsScrollFrame.exportDialogFrame.selectBtn:SetScript("OnClick", function() ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:HighlightText() end);

		-- Escape to close
		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetScript("OnEscapePressed", function(self)
			ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:ClearFocus();
			ArenaAnalyticsScrollFrame.exportDialogFrame:Hide();
		end);

		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetScript("OnEnterPressed", function(self)
			self:ClearFocus();
		end);

		-- Highlight on focus gained
		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetScript("OnEditFocusGained", function(self)
			self:HighlightText();
		end);

		-- Clear text
		ArenaAnalyticsScrollFrame.exportDialogFrame.exportFrame:SetScript("OnHide", function(self)
			-- Garbage collect
			self:SetText("");
            ArenaAnalyticsScrollFrame.exportDialogFrame = nil;
            ArenaAnalytics:Log("Export Frame going away..")
            collectgarbage("collect");
            ArenaAnalytics:Log("Garbage Collection forced by export frame.");
		end);
	end

    ArenaAnalyticsScrollFrame.exportDialogFrame:Show();
end

local function setupTeamPlayerFrames(teamPlayerFrames, match, matchIndex, isEnemyTeam, scrollEntry)
    if(not match) then
        return;
    end

    for i = 1, #teamPlayerFrames do
        local playerFrame = teamPlayerFrames[i];
        assert(playerFrame);
        playerFrame:Show();

        playerFrame.player = ArenaMatch:GetPlayer(match, isEnemyTeam, i);
        if (playerFrame.player) then
            playerFrame.match = match;
            playerFrame.matchIndex = matchIndex;
            playerFrame.isEnemyTeam = isEnemyTeam;

            if(not playerFrame.icon) then
                playerFrame.icon = ArenaIcon:Create(playerFrame, 25);
            end

            local spec_id = ArenaMatch:GetPlayerSpec(playerFrame.player);
            local isFirstDeath = ArenaMatch:IsPlayerFirstDeath(playerFrame.player);

            playerFrame.icon:SetSpec(spec_id);
            playerFrame.icon:SetIsFirstDeath(isFirstDeath, Options:Get("alwaysShowDeathOverlay"));

            if (not Options:Get("alwaysShowSpecOverlay")) then
                playerFrame.icon:SetSpecVisibility(false);
            end

            if (not Options:Get("alwaysShowDeathOverlay")) then
                playerFrame.icon:SetDeathVisibility(false);
            end

            -- Quick Search
            playerFrame:RegisterForClicks("LeftButtonDown", "RightButtonDown");
            playerFrame:SetScript("OnClick", function(self, btn)
                Search:QuickSearch(self, btn);
            end);

            -- Mouseover events
            playerFrame:SetScript("OnEnter", function(self) PlayerTooltip:SetPlayerFrame(self) end);
            playerFrame:SetScript("OnLeave", function(self)
                self.isShowingTooltip = nil;
                Tooltips:HideAll();
            end);

            -- Update tooltip to match new values
            if(playerFrame.isShowingTooltip) then
                PlayerTooltip:SetPlayerFrame(playerFrame);
                --PlayerTooltip:SetPoint("TOPRIGHT", playerFrame, "TOPLEFT");
            end

            playerFrame:Show()
        else
            playerFrame:Hide();
        end
    end
end

-- Hide/Shows Spec icons on the class' bottom-right corner
function AAtable:ToggleSpecsAndDeathOverlay(entry)
    if (entry == nil) then
        return;
    end

    local matchData = { entry:GetChildren() };
    local visible = entry:GetAttribute("selected") or entry:GetAttribute("hovered");

    for i = 1, #matchData do
        local playerFrame = matchData[i];
        assert(playerFrame);

        if(playerFrame.icon) then
            playerFrame.icon:SetSpecVisibility(visible or Options:Get("alwaysShowSpecOverlay"));
            playerFrame.icon:SetDeathVisibility(visible or Options:Get("alwaysShowDeathOverlay"));
        end
    end
end

-- Sets button row's background according to session
local function setColorForSession(button, session, index)
    local isOddSession = (session or 0) % 2 == 1;
    local oddAlpha, evenAlpha = 0.8, 0.4;
    
    local alpha = isOddSession and oddAlpha or evenAlpha;

    local isOddIndex = (index or 0) % 2 == 1;
    if(isOddIndex) then
        local delta = isOddSession and -0.07 or 0.07;
        alpha = alpha + delta;
    end

    if isOddSession then
        local c = 0.05;
        button.Background:SetColorTexture(c, c, c, min(alpha, 1))
    else
        local c = 0.25;
        button.Background:SetColorTexture(c, c, c, min(alpha, 1))
    end
end

-- Create dropdowns for the Comp filters
function AAtable:CreateDropdownForFilterComps(isEnemyComp)
    local config = isEnemyComp and FilterTables.enemyComps or FilterTables.comps;
    local frameName = isEnemyComp and "FitlerEnemyComp" or "FilterComp";
    local newDropdown = Dropdown:Create(ArenaAnalyticsScrollFrame, "Comp", frameName, config, 235, 35, 25);
    local relativeFrame = isEnemyComp and ArenaAnalyticsScrollFrame.filterCompsDropdown or ArenaAnalyticsScrollFrame.filterBracketDropdown;
    newDropdown:SetPoint("LEFT", relativeFrame:GetFrame(), "RIGHT", 10, 0);
        
    local title = isEnemyComp and "Enemy Comp" or "Comp"
    local info = nil;
    if(Options:Get("showCompDropdownInfoText")) then
        info = Options:Get("compDisplayAverageMmr") and "Games || Comp || Winrate || mmr" or "Games || Comp || Winrate";
    end
    
    CreateFilterTitle(newDropdown:GetFrame(), title, info);
    

    if(isEnemyComp) then
        ArenaAnalyticsScrollFrame.filterEnemyCompsDropdown = newDropdown;
    else
        ArenaAnalyticsScrollFrame.filterCompsDropdown = newDropdown;
    end
end

-- Forcefully clear and recreate the comp filters for new filters. Optionally staying visible.
function AAtable:ForceRefreshFilterDropdowns()
    if(not hasLoaded) then
        ArenaAnalytics:Log("ForceRefresh called before OnLoad. Skipped.");
        return;
    end

    ArenaAnalyticsScrollFrame.filterBracketDropdown:Refresh();
    ArenaAnalyticsScrollFrame.filterCompsDropdown:Refresh();
    ArenaAnalyticsScrollFrame.filterEnemyCompsDropdown:Refresh();
end

function AAtable:CheckUnsavedWarningThreshold()
    if(ArenaAnalytics.unsavedArenaCount >= Options:Get("unsavedWarningThreshold")) then
        -- Show and update unsaved arena threshold
        local unsavedWarningText = "|cffff0000" .. ArenaAnalytics.unsavedArenaCount .." unsaved matches!\n |cff00cc66/reload|r |cffff0000to save!|r"
        ArenaAnalyticsScrollFrame.unsavedWarning:SetText(unsavedWarningText);
        ArenaAnalyticsScrollFrame.unsavedWarning:Show();
    else
        ArenaAnalyticsScrollFrame.unsavedWarning:Hide();
    end
end

local function GetArenaText(arenaCount)
    return arenaCount == 1 and "arena" or "arenas";
end

local function CombineStatsText(total, wins, losses, draws)
    total = total or 0;

    local winrateText = total > 0 and math.floor(wins * 100 / total) or 0;
    local winsText =  ArenaAnalytics:ColorText(wins, Constants.winColor);
    local lossesText = ArenaAnalytics:ColorText(losses, Constants.lossColor);

    local includeDraws = draws ~= nil; -- Add option?
    local drawText = includeDraws and (" / " .. ArenaAnalytics:ColorText(draws, Constants.drawColor)) or "";

    local valueText = total .. " " .. GetArenaText(total) .. "   " .. winsText .. " / " .. lossesText .. drawText .. "  " .. winrateText .. "% Winrate";
    return ArenaAnalytics:ColorText(valueText, Constants.statsColor);
end

-- Updates the displayed data for a new match
function AAtable:HandleArenaCountChanged()
    if(not hasLoaded) then
        -- Load will trigger call soon
        return;
    end

    Options:TriggerStateUpdates()
    AAtable:RefreshLayout();

    if(not ArenaAnalytics:HasStoredMatches() and ArenaAnalyticsScrollFrame.exportDialogFrame) then
        ArenaAnalyticsScrollFrame.exportDialogFrame:Hide();
    end

    local wins, losses, draws = 0,0,0;
    local sessionGames, sessionWins, sessionLosses, sessionDraws = 0,0,0,0;

    -- Update arena count & winrate
    for i=ArenaAnalytics.filteredMatchCount, 1, -1 do
        local match, filteredSession = ArenaAnalytics:GetFilteredMatch(i);
        if(match and filteredSession) then
            if(ArenaMatch:IsVictory(match)) then 
                wins = wins + 1;
            elseif(ArenaMatch:IsLoss(match)) then
                losses = losses + 1;
            elseif(ArenaMatch:IsDraw(match)) then
                draws = draws + 1;
            end

            if (filteredSession == 1) then
                sessionGames = sessionGames + 1;

                if(ArenaMatch:IsVictory(match)) then 
                    sessionWins = sessionWins + 1;
                elseif(ArenaMatch:IsLoss(match)) then
                    sessionLosses = sessionLosses + 1;
                elseif(ArenaMatch:IsDraw(match)) then
                    sessionDraws = sessionDraws + 1;
                end
            end
        end
    end

    -- Update displayed session stats text
    local _, expired = Sessions:GetLatestSession();
    local sessionText = expired and "Last session: " or "Current session: ";
    sessionText = ArenaAnalytics:ColorText(sessionText, Constants.prefixColor);

    local valuesText = CombineStatsText(sessionGames, sessionWins, sessionLosses, sessionDraws);
    ArenaAnalyticsScrollFrame.sessionStats:SetText(sessionText .. valuesText);

    -- Update the overall stats
    local hasActiveFilters = Filters:GetActiveFilterCount() > 0;
    local text = hasActiveFilters and "Filtered total: " or ("Total " .. GetArenaText(#ArenaAnalyticsDB) .. ": ");

    -- Color the text
    text = ArenaAnalytics:ColorText(text, Constants.prefixColor);

    local valuesText = CombineStatsText(ArenaAnalytics.filteredMatchCount, wins, losses, draws);
    ArenaAnalyticsScrollFrame.overallStats:SetText(text .. valuesText);

    AAtable.CheckUnsavedWarningThreshold();
end

function AAtable:UpdateSelected()
    if(not hasLoaded) then
        -- Load will trigger call soon
        return;
    end

    local total, wins, losses, draws = 0, 0, 0, 0;

    local deselectedCache = Selection.latestDeselect;
    local selectedTables = { Selection.latestMultiSelect, Selection.selectedGames }

    -- Merge the selected tables to prevent duplicates, excluding deselected
    local uniqueSelected = {}
    for _, selectedTable in ipairs(selectedTables) do
        for index in pairs(selectedTable) do 
            if (not deselectedCache[index]) then
                uniqueSelected[index] = true;
            end
        end
    end

    for index in pairs(uniqueSelected) do
        local match = ArenaAnalytics:GetFilteredMatch(index);
        if(match) then
            total = total + 1;

            if(ArenaMatch:IsVictory(match)) then 
                wins = wins + 1;
            elseif(ArenaMatch:IsLoss(match)) then
                losses = losses + 1;
            elseif(ArenaMatch:IsDraw(match)) then
                draws = draws + 1;
            end
        else
            ArenaAnalytics:Log("Updating selected found index: ", index, " not found in filtered match history!");
        end
    end

    local newSelectedText = ""

    -- Update the UI
    if (total > 0) then
        newSelectedText = CombineStatsText(total, wins, losses, draws);
        ArenaAnalyticsScrollFrame.clearSelected:Show();
    else
        newSelectedText = ArenaAnalytics:ColorText("(click matches to select)", Constants.statsColor);
        ArenaAnalyticsScrollFrame.clearSelected:Hide();
    end

    local selectedPrefixText = ArenaAnalytics:ColorText("Selected: ", Constants.prefixColor);
    ArenaAnalyticsScrollFrame.selectedStats:SetText(selectedPrefixText .. newSelectedText)
end

-- Refreshes matches table
function AAtable:RefreshLayout()
    if(not hasLoaded) then
        -- Load will trigger call soon
        return;
    end

    if(ArenaAnalyticsScrollFrame.filterBtn_ClearFilters) then
        local activeFilterCount = Filters:GetActiveFilterCount();
        if(activeFilterCount > 0) then
            ArenaAnalyticsScrollFrame.activeFilterCountText:SetText("(" .. activeFilterCount .." active)");
            ArenaAnalyticsScrollFrame.filterBtn_ClearFilters:Enable();
        else
            ArenaAnalyticsScrollFrame.activeFilterCountText:SetText("");

            if(not Options:Get("defaultCurrentSeasonFilter") and not Options:Get("defaultCurrentSessionFilter")) then
                ArenaAnalyticsScrollFrame.filterBtn_ClearFilters:Disable();
            end
        end
    end

    local buttons = HybridScrollFrame_GetButtons(ArenaAnalyticsScrollFrame.ListScrollFrame);
    local offset = HybridScrollFrame_GetOffset(ArenaAnalyticsScrollFrame.ListScrollFrame);

    for buttonIndex = 1, #buttons do
        local button = buttons[buttonIndex];
        local matchIndex = ArenaAnalytics.filteredMatchCount - (buttonIndex + offset - 1);

        local match, filteredSession = ArenaAnalytics:GetFilteredMatch(matchIndex);
        if (match ~= nil) then
            setColorForSession(button, filteredSession, matchIndex);

            local matchDate = ArenaMatch:GetDate(match);
            local map = ArenaMatch:GetMap(match, true);
            local duration = ArenaMatch:GetDuration(match);
            local bracket = ArenaMatch:GetBracket(match);

            ArenaAnalytics:SetFrameText(button.Date, Helpers:FormatDate(matchDate), Constants.valueColor);
            ArenaAnalytics:SetFrameText(button.Map, map, Constants.valueColor);
            ArenaAnalytics:SetFrameText(button.Duration, (duration and SecondsToTime(duration)), Constants.valueColor);

            local teamIconsFrames = {button.Team1, button.Team2, button.Team3, button.Team4, button.Team5}
            local enemyTeamIconsFrames = {button.EnemyTeam1, button.EnemyTeam2, button.EnemyTeam3, button.EnemyTeam4, button.EnemyTeam5}

            -- Setup player class frames
            setupTeamPlayerFrames(teamIconsFrames, match, matchIndex, false, button);
            setupTeamPlayerFrames(enemyTeamIconsFrames, match, matchIndex, true, button);

            -- Paint winner green, loser red
            local outcome = ArenaMatch:GetMatchOutcome(match);
            local hex = nil;
            if(outcome == nil) then
                hex = Constants.invalidColor;
            elseif(outcome == 2) then
                hex = Constants.drawColor;
            else
                hex = (outcome == 1) and Constants.winColor or Constants.lossColor;
            end

            -- Party Rating & Delta
            local ratingText = "-";
            local matchType = ArenaMatch:GetMatchType(match);
            if(matchType == "rated") then
                local rating, ratingDelta = ArenaMatch:GetPartyRating(match), ArenaMatch:GetPartyRatingDelta(match);
                ratingText = Helpers:RatingToText(rating, ratingDelta) or "-";
            elseif(matchType == "skirmish") then
                ratingText = "SKIRMISH";
            elseif(matchType == "wargame") then
                ratingText = "WAR GAME";
            end

            button.Rating:SetText("|c" .. hex .. (ratingText or "") .."|r");

            -- Party MMR
            ArenaAnalytics:SetFrameText(button.MMR, (ArenaMatch:GetPartyMMR(match) or "-"), Constants.valueColor);

            -- Enemy team MMR
            ArenaAnalytics:SetFrameText(button.EnemyMMR, (ArenaMatch:GetEnemyMMR(match) or "-"), Constants.valueColor);

            local isSelected = Selection:isMatchSelected(matchIndex);
            button:SetAttribute("selected", isSelected);
            if(isSelected) then
                button.Tooltip:Show();
                AAtable:ToggleSpecsAndDeathOverlay(button);
            else
                button.Tooltip:Hide();
            end

            button:SetScript("OnEnter", function(args)
                args:SetAttribute("hovered", true);
                AAtable:ToggleSpecsAndDeathOverlay(args);

                if(ArenaMatch:IsShuffle(match)) then
                    button.isShowingTooltip = true;
                    Tooltips:DrawShuffleTooltip(button, match);
                else
                    Tooltips:HideShuffleTooltip();
                end
            end);

            button:SetScript("OnLeave", function(args) 
                args:SetAttribute("hovered", false);
                button.isShowingTooltip = nil;
                AAtable:ToggleSpecsAndDeathOverlay(args);
                Tooltips:HideShuffleTooltip();
            end);

            -- Update tooltip to match new values
            if(button.isShowingTooltip) then
                Tooltips:DrawShuffleTooltip(button, match);
                --PlayerTooltip:SetPoint("TOPRIGHT", playerFrame, "TOPLEFT");
            end
            
            button:RegisterForClicks("LeftButtonDown", "RightButtonDown", "LeftButtonUp", "RightButtonUp");
            button:SetScript("OnClick", function(args, key, down)
                if down then
                    Selection:handleMatchEntryClicked(key, false, matchIndex);
                end
            end);

            button:SetScript("OnDoubleClick", function(args, key)
                Selection:handleMatchEntryClicked(key, true, matchIndex);
            end);

            AAtable:ToggleSpecsAndDeathOverlay(button);

            button:SetWidth(ArenaAnalyticsScrollFrame.ListScrollFrame.scrollChild:GetWidth());
            button:Show();
        else
            button:Hide();
        end
    end

    local buttonHeight = ArenaAnalyticsScrollFrame.ListScrollFrame.buttonHeight;
    local totalHeight = ArenaAnalytics.filteredMatchCount * buttonHeight;
    local shownHeight = #buttons * buttonHeight;
    HybridScrollFrame_Update(ArenaAnalyticsScrollFrame.ListScrollFrame, totalHeight, shownHeight);
end

----------------------------------------------------------------------------------------------------------------------------
-- Session Duration

local isSessionTimerActive = false;
local function formatSessionDuration(duration)
    duration = tonumber(duration);
    if(duration == nil) then
        return "";
    end

    local hours = math.floor(duration / 3600) .. "h"
    local minutes = string.format("%02dm", math.floor((duration % 3600) / 60));
    local seconds = string.format("%02ds", duration % 60);

    if duration < 3600 then
        return minutes .. " " .. seconds;
    else
        return hours .. " " .. minutes;
    end
end

function AAtable:SetLatestSessionDurationText(expired, startTime, endTime)
    endTime = expired and endTime or time();
    local duration = startTime and endTime - startTime or nil;

    local text = expired and "Last Session Duration: " or "Session Duration: ";
    text = ArenaAnalytics:ColorText(text, Constants.prefixColor);
    ArenaAnalytics:SetFrameText(ArenaAnalyticsScrollFrame.sessionDuration, text .. formatSessionDuration(duration), Constants.statsColor)
end
