local _, ArenaAnalytics = ...; -- Addon Namespace
local Options = ArenaAnalytics.Options;

-- Local module aliases
local Filters = ArenaAnalytics.Filters;
local AAtable = ArenaAnalytics.AAtable;
local Tooltips = ArenaAnalytics.Tooltips;
local Dropdown = ArenaAnalytics.Dropdown;
local Export = ArenaAnalytics.Export;
local API = ArenaAnalytics.API;
local PlayerTooltip = ArenaAnalytics.PlayerTooltip;
local ImportBox = ArenaAnalytics.ImportBox;
local Debug = ArenaAnalytics.Debug;

-------------------------------------------------------------------------

function Options:RegisterCategory(frame, name, parent)
    assert(frame)

    frame.name = name;

    if parent and parent.category then
        local parentcategory = Settings.GetCategory(parent)
        frame.category = Settings.RegisterCanvasLayoutSubcategory(parent.category, frame, name);
    else
        frame.category = Settings.RegisterCanvasLayoutCategory(frame, name);
        Settings.RegisterAddOnCategory(frame.category);
    end
end

function Options:OpenCategory(frame)
    if(not frame or not frame.category) then
        ArenaAnalytics:Log("Options: Invalid options frame, cannot open.");
        return;
    end

    Settings.OpenToCategory(frame.category.ID);
end

local ArenaAnalyticsOptionsFrame = nil;
function Options:Open()
    Options:OpenCategory(ArenaAnalyticsOptionsFrame);
end

-------------------------------------------------------------------------
-- Standardized Updated Option Response Functions

local function HandleSettingsChanged()
    Filters:ResetAll(false);
    PlayerTooltip:OnSettingsChanged();
end

-------------------------------------------------------------------------

-- User settings
ArenaAnalyticsSharedSettingsDB = ArenaAnalyticsSharedSettingsDB or {};

local defaults = {};

-- Adds a setting with loaded or default value.
local function AddSetting(setting, default)
    assert(setting ~= nil);
    assert(default ~= nil, "Nil values for settings are not supported.");

    if(ArenaAnalyticsSharedSettingsDB[setting] == nil) then
        ArenaAnalyticsSharedSettingsDB[setting] = default;
        ArenaAnalytics:Log("Added setting:", setting, default);
    end
    assert(ArenaAnalyticsSharedSettingsDB[setting] ~= nil);

    -- Cache latest defaults
    defaults[setting] = default;
end

local function RemoveSetting(setting)
    assert(setting ~= nil);
    if(ArenaAnalyticsSharedSettingsDB[setting] == nil) then
        return;
    end

    ArenaAnalyticsSharedSettingsDB[setting] = nil;
    defaults[setting] = nil;
end

-- Adds a setting that does not save across reloads. (Use with caution)
local function AddTransientSetting(setting, default)
    ArenaAnalyticsSharedSettingsDB[setting] = default;
end

local hasOptionsLoaded = nil;
function Options:LoadSettings()
    if hasOptionsLoaded then return end;

    ArenaAnalytics:Log("Loading settings..");

    -- General
    AddSetting("fullSizeSpecIcons", true);
    AddSetting("alwaysShowDeathOverlay", true);
    AddSetting("alwaysShowSpecOverlay", false);
    AddSetting("unsavedWarningThreshold", 10);

    AddSetting("hideZeroRatingDelta", true);
    AddSetting("hidePlayerTooltipZeroRatingDelta", false);
    AddSetting("ignoreGroupForSkirmishSession", true);

    AddSetting("muteArenaDialogSounds", false);

    AddSetting("surrenderByMiddleMouseClick", false);
    AddSetting("enableSurrenderAfkOverride", true);
    AddSetting("enableDoubleAfkToLeave", true);
    AddSetting("enableSurrenderGoodGameCommand", true);

    AddSetting("hideMinimapButton", false);
    AddSetting("hideFromCompartment", false);

    AddSetting("printAsSystem", true);

    -- Filters
    AddSetting("defaultCurrentSeasonFilter", false);
    AddSetting("defaultCurrentSessionFilter", false);

    AddSetting("showSkirmish", true);
    AddSetting("showWarGames", true);

    AddSetting("showCompDropdownInfoText", true);

    AddSetting("sortCompFilterByTotalPlayed", true);
    AddSetting("compDisplayAverageMmr", true);
    AddSetting("showSelectedCompStats", false);

    AddSetting("minimumCompsPlayed", 0); -- Minimum games to appear on comp dropdowns
    AddSetting("compDropdownVisibileLimit", 10);
    AddSetting("dropdownScrollStep", 1);

    -- Selection (NYI)
    AddSetting("selectionControlModInversed", false);

    -- Import/Export
    AddSetting("allowImportDataMerge", false);

    -- Search
    AddSetting("searchDefaultExplicitEnemy", false);

    -- Quick Search
    AddSetting("quickSearchEnabled", true);
    AddSetting("searchShowTooltipQuickSearch", true);

    AddSetting("quickSearchIncludeRealm", "Other Realms"); -- None, All, Other Realms, My Realm
    AddSetting("quickSearchDefaultAppendRule", "New Search"); -- New Search, New Segment, Same Segment
    AddSetting("quickSearchDefaultValue", "Name");

    AddSetting("quickSearchAppendRule_NewSearch", "None");
    AddSetting("quickSearchAppendRule_NewSegment", "Shift");
    AddSetting("quickSearchAppendRule_SameSegment", "None");

    AddSetting("quickSearchAction_Inverse", "Alt");

    AddSetting("quickSearchAction_Team", "None");
    AddSetting("quickSearchAction_Enemy", "RMB");
    AddSetting("quickSearchAction_ClickedTeam", "LMB");

    AddSetting("quickSearchAction_Name", "None");
    AddSetting("quickSearchAction_Spec", "Ctrl");
    AddSetting("quickSearchAction_Race", "None");
    AddSetting("quickSearchAction_Faction", "None");

    -- Debugging
    AddSetting("debuggingLevel", 0);
    AddSetting("hideErrorLogs", false);

    -- Temp Fix
    if(API.requiresMoPFix or true) then
        AddSetting("enableMoPHealerCharacterPanelFix", true);
    end

    hasOptionsLoaded = true;
    ArenaAnalytics:Log("Settings loaded successfully.");
    return true;
end

function Options:HasLoaded()
    return hasOptionsLoaded;
end

function Options:IsValid(setting)
    return setting and ArenaAnalyticsSharedSettingsDB[setting] ~= nil;
end

function Options:IsDefault(setting)
    assert(Options:IsValid(setting));

    return ArenaAnalyticsSharedSettingsDB[setting] == defaults[setting];
end

-- Gets a setting, regardless of location between 
function Options:Get(setting)
    assert(setting);

    if(hasOptionsLoaded == false) then
        ArenaAnalytics:Log("Force loaded settings to immediately get:", setting);
        local successful = Options:LoadSettings();
        if not successful then return end;
    end

    local value = ArenaAnalyticsSharedSettingsDB[setting];

    if(value == nil) then
        ArenaAnalytics:Log("Setting not found: ", setting, value)
        return nil;
    end

    return value;
end

function Options:Set(setting, value)
    assert(setting and hasOptionsLoaded);
    assert(ArenaAnalyticsSharedSettingsDB[setting] ~= nil, "Setting invalid option: " .. (setting or "nil"));

    if(value == nil) then
        value = defaults[setting];
    end
    assert(value ~= nil);

    if(value == ArenaAnalyticsSharedSettingsDB[setting]) then
        return;
    end

    local oldValue = ArenaAnalyticsSharedSettingsDB[setting];
    ArenaAnalyticsSharedSettingsDB[setting] = value;
    ArenaAnalytics:Log("Setting option:   ", setting, "  new:", value, "  old:", oldValue);

    HandleSettingsChanged();
end

function Options:Reset(setting)
    Options:Set(setting, nil);
end

local exportOptionsFrame = nil;

function Options:TriggerStateUpdates()
    if(exportOptionsFrame and exportOptionsFrame.ImportBox and exportOptionsFrame.ImportBox.stateFunc) then
        exportOptionsFrame.ImportBox:stateFunc();
    end
end

local TabTitleSize = 18;
local TabHeaderSize = 16;
local GroupHeaderSize = 14;
local TextSize = 12;

local OptionsSpacing = 10;

-- Offset to use while creating settings tabs
local offsetY = 0;

-------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------

local function SetupTooltip(owner, frames)
    assert(owner ~= nil);

    frames = frames or owner;
    frames = (type(frames) == "table" and frames or { frames });

    for i,frame in ipairs(frames) do
        frame:SetScript("OnEnter", function ()
            if(owner.tooltip) then
                Tooltips:DrawOptionTooltip(owner, owner.tooltip);
            end
        end);

        frame:SetScript("OnLeave", function ()
            if(owner.tooltip) then
                GameTooltip:Hide();
            end
        end);
    end
end

local function InitializeTab(parent)
    local addonNameText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    addonNameText:SetPoint("TOPLEFT", parent, "TOPLEFT", -5, 32)
    addonNameText:SetTextHeight(TabTitleSize);
    addonNameText:SetText("Arena|cff00ccffAnalytics|r   |cff666666v" .. API:GetAddonVersion() .. "|r");
    
    -- Reset Y offset
    offsetY = 0;
end

local function CreateSpace(explicit)
    offsetY = offsetY - max(0, explicit or 20)
end

local function CreateHeader(text, size, parent, relative, x, y, icon)
    local frame = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame:SetPoint("TOPLEFT", relative or parent, "TOPLEFT", x, y)
    frame:SetTextHeight(size);
    frame:SetText(text or "");

    offsetY = offsetY - OptionsSpacing - frame:GetHeight() + y;

    return frame;
end

local function CreateButton(setting, parent, x, width, text, func)
    assert(type(func) == "function");

    -- Create the button
    local button = CreateFrame("Button", "ArenaAnalyticsButton_" .. (setting or text or ""), parent, "UIPanelButtonTemplate");

    -- Set the button's position
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, offsetY);

    -- Set the button's size and text
    button:SetSize(width or 120, 30)
    button:SetText(text or "")

    -- Add a script for the button's click action
    button:SetScript("OnClick", function()
        func(setting);
    end)

    SetupTooltip(button, nil);

    offsetY = offsetY - OptionsSpacing - button:GetHeight();

    return button;
end

local function CreateImportBox(parent, x, width, height)
    local ImportBox = ImportBox:Create(parent, "ArenaAnalyticsImportDialogBox", width, (height or 25));
    ImportBox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, offsetY);

    function ImportBox:stateFunc()
        if(Options:Get("allowImportDataMerge") or not ArenaAnalytics:HasStoredMatches()) then
            self.frame.editbox:Enable();
        else
            self:Disable();
        end
    end

    ImportBox:stateFunc();

    offsetY = offsetY - ImportBox:GetHeight();

    return ImportBox;
end

local function CreateCheckbox(setting, parent, x, text, func)
    assert(setting ~= nil);
    assert(type(setting) == "string");

    local checkbox = CreateFrame("CheckButton", "ArenaAnalyticsScrollFrame_"..setting, parent, "OptionsSmallCheckButtonTemplate");

    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, offsetY);

    checkbox.text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5);
    checkbox.text:SetTextHeight(TextSize);
    checkbox.text:SetText(text or "");

    checkbox:SetChecked(Options:Get(setting));

    checkbox:SetScript("OnClick", function()
		Options:Set(setting, checkbox:GetChecked());
        
        if(func) then
            func(setting);
        end
	end);

    SetupTooltip(checkbox, {checkbox, checkbox.text});

    offsetY = offsetY - OptionsSpacing - checkbox:GetHeight() + 10;

    parent[setting] = checkbox;
    return checkbox;
end

local function CreateInputBox(setting, parent, x, text, func)
    offsetY = offsetY - 2; -- top padding

    local inputBox = CreateFrame("EditBox", "exportFrameScroll", parent, "InputBoxTemplate");
    inputBox:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 8, offsetY);
    inputBox:SetWidth(50);
    inputBox:SetHeight(20);
    inputBox:SetNumeric();
    inputBox:SetAutoFocus(false);
    inputBox:SetMaxLetters(5);
    inputBox:SetText(tonumber(Options:Get(setting)) or "");
    inputBox:SetCursorPosition(0);
    inputBox:HighlightText(0,0);    

    -- Text
    inputBox.text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    inputBox.text:SetPoint("LEFT", inputBox, "RIGHT", 5, 0);
    inputBox.text:SetTextHeight(TextSize);
    inputBox.text:SetText(text or "");

    inputBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus();
    end);

    inputBox:SetScript("OnEscapePressed", function(self)
		inputBox:SetText(Options:Get(setting) or "");
        self:ClearFocus();
    end);

    inputBox:SetScript("OnEditFocusLost", function(self)
		local oldValue = tonumber(Options:Get(setting));
		local newValue = tonumber(inputBox:GetText());
        Options:Set(setting, newValue or oldValue)
		inputBox:SetText(tonumber(Options:Get(setting)) or "");
        inputBox:SetCursorPosition(0);
		inputBox:HighlightText(0,0);
        
		AAtable:CheckUnsavedWarningThreshold();
    end);

    SetupTooltip(inputBox, {inputBox, inputBox.text});

    if(func) then
        func(setting);
    end

    offsetY = offsetY - OptionsSpacing - inputBox:GetHeight() + 5;

    return inputBox;
end

local function CreateDropdown(setting, parent, x, text, entries, func)
    assert(setting and entries and #entries > 0);
    assert(Options:IsValid(setting));

    offsetY = offsetY - 2;

    local function SetSettingFromDropdown(dropdownContext, btn)
        if(btn == "RightButton") then
            Options:Reset(dropdownContext.key);
        else
            Options:Set(dropdownContext.key, (dropdownContext.value or dropdownContext.label));
        end

        if(func) then
            func(dropdownContext, btn, parent);
        end
    end

    local function IsSettingEntryChecked(dropdownContext)
        assert(dropdownContext ~= nil, "Invalid contextFrame");
    
        return Options:Get(dropdownContext.key) == (dropdownContext.value or dropdownContext.label);
    end

    local function ResetSetting(dropdownContext, btn)
        if(btn == "RightButton") then
            Options:Reset(dropdownContext.key);
            dropdownContext:Refresh();

            if(func) then
                func(dropdownContext, btn, parent);
            end
        else
            dropdownContext.parent:Toggle();
        end
    end

    local function GenerateEntries()
        local entryTable = {}
        for _,entry in ipairs(entries) do 
            if(entry) then
                tinsert(entryTable, {
                    label = entry,
                    alignment = "LEFT",
                    key = setting,
                    onClick = SetSettingFromDropdown,
                    checked = IsSettingEntryChecked,
                });
            end
        end
        return entryTable;
    end

    local function GetSelectedLabel(dropdownContext)
        local selected = Options:Get(dropdownContext.key) or "";
        if(selected == "None") then
            return "|cff555555" .. selected .. "|r";
        end
        return selected;
    end

    local config = {
        mainButton = {
            label = GetSelectedLabel,
            alignment = "CENTER",
            key = setting,
            onClick = ResetSetting
        },
        entries = GenerateEntries;
    }

    local newDropdown = Dropdown:Create(parent, "Setting", setting.."Dropdown", config, 150, 25) -- parent, dropdownType, frameName, config, width, height
    newDropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x, offsetY);

    -- Text
    newDropdown.text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    newDropdown.text:SetPoint("LEFT", newDropdown:GetFrame(), "RIGHT", 5, 0);
    newDropdown.text:SetTextHeight(TextSize);
    newDropdown.text:SetText(text or "");

    offsetY = offsetY - OptionsSpacing - newDropdown:GetHeight() + 10;
    return newDropdown;
end

-------------------------------------------------------------------
-- General Tab
-------------------------------------------------------------------

function SetupTab_General()
    -- Title
    InitializeTab(ArenaAnalyticsOptionsFrame);
    local parent = ArenaAnalyticsOptionsFrame;
    local offsetX = 20;    

    parent.tabHeader = CreateHeader("General", TabHeaderSize, parent, nil, 15, -15);

    -- Setup options
    CreateCheckbox("hideMinimapButton", parent, offsetX, "Hide minimap icon.", ArenaAnalytics.MinimapButton.Update);

    if(AddonCompartmentFrame) then
        CreateCheckbox("hideFromCompartment", parent, offsetX, "Hide from addon compartment.", ArenaAnalytics.MinimapButton.Update);
    end

    CreateSpace();

    CreateCheckbox("printAsSystem", parent, offsetX, "Print messages using system messages.    |cffaaaaaa(Alternative is general chat only prints)|r");
    CreateCheckbox("hideErrorLogs", parent, offsetX, "Hide error logging in chat.     |cffaaaaaa(Consider reporting errors instead)|r");

    CreateSpace();

    CreateCheckbox("fullSizeSpecIcons", parent, offsetX, "Full size spec icons.");
    CreateCheckbox("alwaysShowDeathOverlay", parent, offsetX, "Always show death overlay (Otherwise mouseover only)");
    CreateCheckbox("alwaysShowSpecOverlay", parent, offsetX, "Always show spec (Otherwise mouseover only)");
    CreateInputBox("unsavedWarningThreshold", parent, offsetX, "Unsaved games threshold before showing |cff00cc66/reload|r warning.");

    CreateSpace();

    CreateCheckbox("hideZeroRatingDelta", parent, offsetX, "Hide delta for unchanged rating.");
    CreateCheckbox("hidePlayerTooltipZeroRatingDelta", parent, offsetX, "Hide delta for unchanged rating on player tooltips.");
    CreateCheckbox("ignoreGroupForSkirmishSession", parent, offsetX, "Sessions ignore skirmish team check.");

    CreateSpace();

    CreateCheckbox("muteArenaDialogSounds", parent, offsetX, "Mute dialog sound during arena.", API.UpdateDialogueVolume);

    if(API:HasSurrenderAPI()) then
        local function UpdateDoubleAfkState()
            if(parent.enableDoubleAfkToLeave) then
                if(Options:Get("enableSurrenderAfkOverride")) then
                    parent.enableDoubleAfkToLeave:Enable();
                else
                    parent.enableDoubleAfkToLeave:Disable();
                end
            end
        end

        CreateSpace();
        CreateCheckbox("surrenderByMiddleMouseClick", parent, offsetX, "Surrender by middle mouse clicking the minimap icon.");
        CreateCheckbox("enableSurrenderGoodGameCommand", parent, offsetX, "Register |cff00ccff/gg|r surrender command.", ArenaAnalytics.UpdateSurrenderCommands);
        CreateCheckbox("enableSurrenderAfkOverride", parent, offsetX, "Enable |cff00ccff/afk|r surrender override.", function()
            UpdateDoubleAfkState();
            ArenaAnalytics.UpdateSurrenderCommands();
        end);
        CreateCheckbox("enableDoubleAfkToLeave", parent, offsetX*2, "Double |cff00ccff/afk|r to leave the arena.    |cffaaaaaa(Type |cff00ccff/afk|r twice within 5 seconds to confirm.)|r");
        UpdateDoubleAfkState();
    end

    if(API.requiresMoPFix) then
        CreateSpace();

        local frame = CreateCheckbox("enableMoPHealerCharacterPanelFix", parent, offsetX, "Force healer character panel fix.     |cffaaaaaa(Workaround for MoP Beta Bug)|r", function()
            if(SHOW_COMBAT_HEALING == nil and Options:Get("enableMoPHealerCharacterPanelFix")) then
                ArenaAnalytics:LogTemp("Forcing MoP Fix from option change!");
                SHOW_COMBAT_HEALING = "";
            end
        end);
        frame.tooltip = { "MoP Stats Fix", "Fixes MoP Beta Character Panel Stats for healers.\n\n\n|cffff0000Experimental! Limited testing against taint. Use at own risk.|r" };
    end
end

-------------------------------------------------------------------
-- Filter Tab
-------------------------------------------------------------------

function SetupTab_Filters()
    local filterOptionsFrame = CreateFrame("frame");
    Options:RegisterCategory(filterOptionsFrame, "Filters", ArenaAnalyticsOptionsFrame);

    -- Title
    InitializeTab(filterOptionsFrame);
    local parent = filterOptionsFrame;
    local offsetX = 20;

    parent.tabHeader = CreateHeader("Filters", TabHeaderSize, parent, nil, 15, -15);

    CreateCheckbox("showSkirmish", parent, offsetX, "Show Skirmish in match history.");
    CreateCheckbox("showWarGames", parent, offsetX, "Show War Games in match history.");

    CreateSpace();

    -- Setup options
    CreateCheckbox("defaultCurrentSeasonFilter", parent, offsetX, "Apply current season filter by default.");
    CreateCheckbox("defaultCurrentSessionFilter", parent, offsetX, "Apply latest session only by default.");

    CreateSpace();

    CreateCheckbox("showCompDropdownInfoText", parent, offsetX, "Show info text by comp dropdown titles.", function()
        local dropdownFrame = ArenaAnalyticsScrollFrame.filterCompsDropdown;
        if(dropdownFrame and dropdownFrame.title and dropdownFrame.info) then
            if(Options:Get("showCompDropdownInfoText")) then
                dropdownFrame.title.info:Show();
            else
                dropdownFrame.title.info:Hide();
            end
        end

        dropdownFrame = ArenaAnalyticsScrollFrame.filterEnemyCompsDropdown;
        if(dropdownFrame and dropdownFrame.title and dropdownFrame.info) then
            if(Options:Get("showCompDropdownInfoText")) then
                dropdownFrame.title.info:Show();
            else
                dropdownFrame.title.info:Hide();
            end
        end
    end);

    CreateSpace();

    CreateCheckbox("sortCompFilterByTotalPlayed", parent, offsetX, "Sort comp filter dropdowns by total played.");
    CreateCheckbox("showSelectedCompStats", parent, offsetX, "Show played and winrate for selected comp in filters.");
    CreateCheckbox("compDisplayAverageMmr", parent, offsetX, "Show average mmr in comp dropdown.", function()
        local info = Options:Get("compDisplayAverageMmr") and "Games || Comp || Winrate || mmr" or "Games || Comp || Winrate";

        local dropdownFrame = ArenaAnalyticsScrollFrame.filterCompsDropdown;
        if(dropdownFrame and dropdownFrame.title and dropdownFrame.info) then
            dropdownFrame.title.info:SetText(info or "");
        end

        dropdownFrame = ArenaAnalyticsScrollFrame.filterEnemyCompsDropdown;
        if(dropdownFrame and dropdownFrame.title and dropdownFrame.info) then
            dropdownFrame.title.info:SetText(info or "");
        end
    end);

    parent.minimumCompsPlayed = CreateInputBox("minimumCompsPlayed", parent, offsetX, "Minimum games required to appear on comp filter.");
    parent.compDropdownVisibileLimit = CreateInputBox("compDropdownVisibileLimit", parent, offsetX, "Maximum comp dropdown entries visible.");
    parent.dropdownScrollStep = CreateInputBox("dropdownScrollStep", parent, offsetX, "Dropdown entries to scroll past per through per step.");
end

-------------------------------------------------------------------
-- Search Tab
-------------------------------------------------------------------

function SetupTab_Search()
    local filterOptionsFrame = CreateFrame("frame");
    --filterOptionsFrame.name = "Search";
    Options:RegisterCategory(filterOptionsFrame, "Search", ArenaAnalyticsOptionsFrame);

    -- Title
    InitializeTab(filterOptionsFrame);
    local parent = filterOptionsFrame;
    local offsetX = 20;

    parent.tabHeader = CreateHeader("Search", TabHeaderSize, parent, nil, 15, -15);

    -- Setup options
    -- TODO: Convert to explicit team dropdown (Any, Team, Enemy)
    CreateCheckbox("searchDefaultExplicitEnemy", parent, offsetX, "Search defaults enemy team.   |cffaaaaaa(Override by adding keyword: '|cff00ccffteam|r' for explicit friendly team.)|r", function()
        if(Debug:Assert(ArenaAnalyticsScrollFrame.searchBox.title)) then
            local explicitEnemyText = Options:Get("searchDefaultExplicitEnemy") and "Enemy Search" or "Search";
            ArenaAnalyticsScrollFrame.searchBox.title:SetText(explicitEnemyText or "");
        end
    end);
end

-------------------------------------------------------------------
-- Quick Search Tab
-------------------------------------------------------------------

local function ForceUniqueAppendRuleShortcut(dropdownContext, _, parent)
    local setting = dropdownContext and dropdownContext.key or nil;

    if(Options:IsValid(setting)) then
        local value = Options:Get(setting);

        local appendRuleFrames = { "quickSearchAppendRule_NewSearch", "quickSearchAppendRule_NewSegment", "quickSearchAppendRule_SameSegment" }
        for _,appendRule in ipairs(appendRuleFrames) do
            if(appendRule ~= setting) then
                local appendRuleValue = Options:Get(appendRule);

                -- Clear the existing append rule shortcut, if it's being reused now.
                if(appendRuleValue == value) then
                    Options:Set(appendRule, "None");

                    local otherDropdown = parent and parent[appendRule];
                    if(otherDropdown and otherDropdown.Refresh) then
                        otherDropdown:Refresh();
                    end
                end
            end
        end
    end
end

function SetupTab_QuickSearch()
    local filterOptionsFrame = CreateFrame("frame");
    --filterOptionsFrame.name = "Quick Search";
    Options:RegisterCategory(filterOptionsFrame, "Quick Search", ArenaAnalyticsOptionsFrame);

    -- Title
    InitializeTab(filterOptionsFrame);
    local parent = filterOptionsFrame;
    local offsetX = 20;    

    parent.tabHeader = CreateHeader("Quick Search", TabHeaderSize, parent, nil, 15, -15);

    -- Setup options
    CreateCheckbox("quickSearchEnabled", parent, offsetX, "Enable Quick Search");
    CreateCheckbox("searchShowTooltipQuickSearch", parent, offsetX, "Show Quick Search shortcuts in Player Tooltips");

    CreateSpace(15);

    local includeRealmOptions = { "None", "All", "Other Realms", "My Realm" };
    parent.includeRealmDropdown = CreateDropdown("quickSearchIncludeRealm", parent, offsetX, "Include realms from Quick Search.", includeRealmOptions);

    local appendRules = { "New Search", "New Segment", "Same Segment" };
    parent.defaultAppendRuleDropdown = CreateDropdown("quickSearchDefaultAppendRule", parent, offsetX, "Default append rule, if not overridden by shortcuts.", appendRules);

    local valueOptions = { "Name", "Spec", "Race", "Faction" };
    parent.defaultValueDropdown = CreateDropdown("quickSearchDefaultValue", parent, offsetX, "Default value to add, if not overridden by shortcuts.", valueOptions);

    CreateSpace(15);

    local shortcuts = { "None", "LMB", "RMB", "Nomod", "Shift", "Ctrl", "Alt" };

    parent.quickSearchAppendRule_NewSearch = CreateDropdown("quickSearchAppendRule_NewSearch", parent, offsetX, "New Search append rule shortcut.", shortcuts, ForceUniqueAppendRuleShortcut);
    parent.quickSearchAppendRule_NewSegment = CreateDropdown("quickSearchAppendRule_NewSegment", parent, offsetX, "New Segment append rule shortcut.", shortcuts, ForceUniqueAppendRuleShortcut);
    parent.quickSearchAppendRule_SameSegment = CreateDropdown("quickSearchAppendRule_SameSegment", parent, offsetX, "Same Segment append rule shortcut.", shortcuts, ForceUniqueAppendRuleShortcut);

    CreateSpace(15);

    parent.inverseValueDropdown = CreateDropdown("quickSearchAction_Inverse", parent, offsetX, "Inverse segment shortcut.", shortcuts);

    CreateSpace(15);

    parent.clickedTeamValueDropdown = CreateDropdown("quickSearchAction_ClickedTeam", parent, offsetX, "Team of clicked player shortcut.", shortcuts);
    parent.teamValueDropdown = CreateDropdown("quickSearchAction_Team", parent, offsetX, "Team shortcut.", shortcuts);
    parent.enemyValueDropdown = CreateDropdown("quickSearchAction_Enemy", parent, offsetX, "Enemy shortcut.", shortcuts);

    CreateSpace(15);

    parent.nameValueDropdown = CreateDropdown("quickSearchAction_Name", parent, offsetX, "Name shortcut.", shortcuts);
    parent.specValueDropdown = CreateDropdown("quickSearchAction_Spec", parent, offsetX, "Spec shortcut.", shortcuts);
    parent.raceValueDropdown = CreateDropdown("quickSearchAction_Race", parent, offsetX, "Race shortcut.", shortcuts);
    parent.factionValueDropdown = CreateDropdown("quickSearchAction_Faction", parent, offsetX, "Faction shortcut.", shortcuts);
end

-------------------------------------------------------------------
-- Import/Export Tab
-------------------------------------------------------------------

function SetupTab_ImportExport()
    exportOptionsFrame = CreateFrame("frame");
    Options:RegisterCategory(exportOptionsFrame, "Import / Export", ArenaAnalyticsOptionsFrame);

    InitializeTab(exportOptionsFrame);
    local parent = exportOptionsFrame;
    local offsetX = 20;

    parent.tabHeader = CreateHeader("Import / Export", TabHeaderSize, parent, nil, 15, -15);

    parent.exportButton = CreateButton(nil, parent, offsetX, 120, "Export", function() end);
    parent.exportButton:Disable();
    parent.exportButton.tooltip = { "ArenaAnalytics Export", "Not Yet Implemented" }

    CreateSpace();

    -- Import button (Might want an option at some point for whether we'll allow importing to merge with existing entries)
    parent.ImportBox = CreateImportBox(parent, offsetX, 380);

    local frame = CreateCheckbox("allowImportDataMerge", parent, offsetX, "Allow Import Merge", function()
        parent.ImportBox:stateFunc();
    end);
    frame.tooltip = { "Allow Import Merge", "Enables importing with stored matches.\nSkip matches within 24 hours of first and last arena, and matches between the two dates.\n\n|cffff0000Experimental! It is recommended to backup character specific SavedVariable first." }

    CreateSpace();

    parent.purgeButton = CreateButton(nil, parent, offsetX, 213, "Purge Match History", ArenaAnalytics.ShowPurgeConfirmationDialog);

    exportOptionsFrame:SetScript("OnShow", function() parent.ImportBox:stateFunc() end);
end

-------------------------------------------------------------------
-- Initialize Options Menu
-------------------------------------------------------------------

function Options:Init()
    Options:LoadSettings();

    if not ArenaAnalyticsOptionsFrame then
        ArenaAnalyticsOptionsFrame = CreateFrame("Frame");
        Options:RegisterCategory(ArenaAnalyticsOptionsFrame, "Arena|cff00ccffAnalytics|r");

        -- Setup tabs
        SetupTab_General();
        SetupTab_Filters();
        SetupTab_Search();
        SetupTab_QuickSearch();
        SetupTab_ImportExport();   -- TODO: Implement updated import/export
    end
end