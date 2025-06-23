local _, ArenaAnalytics = ...; -- Namespace

-- Declare Module Namespaces
ArenaAnalytics.Constants = {};
ArenaAnalytics.SpecSpells = {};
ArenaAnalytics.Localization = {};
ArenaAnalytics.Internal = {};
ArenaAnalytics.Bitmap = {};
ArenaAnalytics.TablePool = {};

ArenaAnalytics.Helpers = {};
ArenaAnalytics.API = {};
ArenaAnalytics.Inspection = {};

ArenaAnalytics.AAtable = {};
ArenaAnalytics.Selection = {};
ArenaAnalytics.ArenaIcon = {};
ArenaAnalytics.Tooltips = {};
ArenaAnalytics.ShuffleTooltip = {};
ArenaAnalytics.PlayerTooltip = {};
ArenaAnalytics.ImportProgressFrame = {};

ArenaAnalytics.Dropdown = {};
ArenaAnalytics.Dropdown.List = {};
ArenaAnalytics.Dropdown.Button = {};
ArenaAnalytics.Dropdown.EntryFrame = {};
ArenaAnalytics.Dropdown.Display = {};

ArenaAnalytics.Options = {};
ArenaAnalytics.AAmatch = {};
ArenaAnalytics.Events = {};
ArenaAnalytics.ArenaTracker = {};
ArenaAnalytics.Sessions = {};
ArenaAnalytics.ArenaMatch = {};
ArenaAnalytics.GroupSorter = {};

ArenaAnalytics.Search = {};
ArenaAnalytics.Filters = {};
ArenaAnalytics.FilterTables = {};

ArenaAnalytics.Export = {};
ArenaAnalytics.Import = {};
ArenaAnalytics.ImportBox = {};
ArenaAnalytics.VersionManager = {};

-- Local module aliases
local Internal = ArenaAnalytics.Internal;
local Bitmap = ArenaAnalytics.Bitmap;
local Options = ArenaAnalytics.Options;
local Filters = ArenaAnalytics.Filters;
local FilterTables = ArenaAnalytics.FilterTables;
local API = ArenaAnalytics.API;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local Sessions = ArenaAnalytics.Sessions;
local ArenaTracker = ArenaAnalytics.ArenaTracker;
local AAtable = ArenaAnalytics.AAtable;
local Events = ArenaAnalytics.Events;
local Search = ArenaAnalytics.Search;
local VersionManager = ArenaAnalytics.VersionManager;
local Selection = ArenaAnalytics.Selection;
local Dropdown = ArenaAnalytics.Dropdown;
local Tooltips = ArenaAnalytics.Tooltips;
local Debug = ArenaAnalytics.Debug;
local MinimapButton = ArenaAnalytics.MinimapButton;

-------------------------------------------------------------------------

function ArenaAnalyticsToggle()
	ArenaAnalytics:Toggle();
end

function ArenaAnalyticsOpenOptions()
	ArenaAnalytics.Options.Open();
end

--------------------------------------
-- Custom Slash Command
--------------------------------------
ArenaAnalytics.commands = {	
	["help"] = function()
		ArenaAnalytics:PrintSystemSpacer();
		ArenaAnalytics:PrintSystem("List of slash commands:");
		ArenaAnalytics:PrintSystem("|cff00cc66/aa|r Togggles ArenaAnalytics main panel.");
		ArenaAnalytics:PrintSystem("|cff00cc66/aa played|r Prints total duration of tracked arenas.");
		ArenaAnalytics:PrintSystem("|cff00cc66/aa version|r Prints the current ArenaAnalytics version.");
		ArenaAnalytics:PrintSystem("|cff00cc66/aa total|r Prints total unfiltered matches.");
		ArenaAnalytics:PrintSystem("|cff00cc66/aa purge|r Show dialog to permanently delete match history.");
		ArenaAnalytics:PrintSystem("|cff00cc66/aa credits|r Print addon credits.");
		ArenaAnalytics:PrintSystemSpacer();
	end,

	["credits"] = function()
		ArenaAnalytics:PrintSystem("ArenaAnalytics authors: Lingo, Zeetrax.   Developed in association with Hydra. www.twitch.tv/Hydramist");
	end,

	["version"] = function()
		ArenaAnalytics:PrintSystem("Current version: |cffAAAAAAv" .. (API:GetAddonVersion() or "Invalid Version") .. "|r");
	end,

	["total"] = function()
		ArenaAnalytics:PrintSystem("Total arenas stored: ", #ArenaAnalyticsDB);
	end,

	["played"] = function()
		local totalDurationInArenas = 0;
		local currentSeasonTotalPlayed = 0;
		local longestDuration = 0;
		for i=1, #ArenaAnalyticsDB do
			local match = ArenaAnalyticsDB[i];
			local duration = ArenaMatch:GetDuration(match) or 0;
			if(duration > 0) then
				totalDurationInArenas = totalDurationInArenas + duration;

				if(duration < 2760) then -- Only count valid duration (plus 60sec buffer)
					longestDuration = max(longestDuration, duration);
				end

				if(ArenaMatch:GetSeason(match) == API:GetCurrentSeason()) then
					currentSeasonTotalPlayed = currentSeasonTotalPlayed + duration;
				end
			end
		end

		-- TODO: Update coloring?
		ArenaAnalytics:PrintSystem("Total arena time played: ", SecondsToTime(totalDurationInArenas));
		ArenaAnalytics:PrintSystem("Time played this season: ", SecondsToTime(currentSeasonTotalPlayed));
		ArenaAnalytics:PrintSystem("Average arena duration: ", SecondsToTime(math.floor(totalDurationInArenas / #ArenaAnalyticsDB)));
		ArenaAnalytics:PrintSystem("Longest arena duration: ", SecondsToTime(math.floor(longestDuration)));
	end,

	-- Debug level
	["debug"] = function(level)
		Debug:SetDebugLevel(level);
	end,

	-- Toggle show 
	["error"] = function()
		ArenaAnalytics:LogError("Test error.");
	end,

	["convert"] = function()
		ArenaAnalytics:PrintSystem("Forcing data version conversion..");
		if(not ArenaAnalyticsDB or #ArenaAnalyticsDB == 0) then
			VersionManager:OnInit();
		end
        ArenaAnalyticsScrollFrame:Hide();
	end,

	["updatesessions"] = function()
		ArenaAnalytics:PrintSystem("Updating sessions in ArenaAnalyticsDB.");
		Sessions:RecomputeSessionsForMatchHistory();

        ArenaAnalyticsScrollFrame:Hide();
	end,

	["updategroupsort"] = function()
		ArenaAnalytics:PrintSystem("Updating group sorting in ArenaAnalyticsDB.");

		ArenaAnalytics:ResortGroupsInMatchHistory();

        ArenaAnalyticsScrollFrame:Hide();
	end,

	["purge"] = function()
		ArenaAnalytics:ShowPurgeConfirmationDialog();
	end,

	["debugcleardb"] = function()
		if(ArenaAnalytics:GetDebugLevel() == 0) then
			ArenaAnalytics:PrintSystem("Clearing ArenaAnalyticsDB requires debugging enabled.  |cffBBBBBB/aa debug|r. Not intended for users!");
		else -- Debug mode is enabled, allow debug clearing the DB
			if (ArenaAnalytics:HasStoredMatches()) then
				ArenaAnalytics:Log("Purging ArenaAnalyticsDB.");
				ArenaAnalytics:PurgeArenaAnalyticsDB();
			end
		end
	end,

	-- Debugging: Used for temporary explicit triggering of logic, for testing purposes.
	["dumprealms"] = function()
		print(" ");
		ArenaAnalytics:Print(" ================================================  ");
		ArenaAnalytics:Print("  Known Realms:     (Current realm: " .. (ArenaAnalytics:GetLocalRealmIndex() or "").. ")");

		for i,realm in ipairs(ArenaAnalyticsDB.realms) do
			ArenaAnalytics:Print("     ", i, "   ", realm);
		end
		ArenaAnalytics:Print("  ================================================  ");
		print(" ");
	end,

	-- Debugging: Used to gather zone and version info from users helping with version update
	["devcontext"] = function(...)
		print(" ");
		ArenaAnalytics:Print(" ================================================  ");
		ArenaAnalytics:Print("Interface Version:", select(4, GetBuildInfo()));

		if(API and API.IsInArena()) then
			ArenaAnalytics:Print("Arena Map ID:", API:GetCurrentMapID(), GetZoneText());
		end
		print(" ");
	end,

	-- Debugging: Used for temporary explicit triggering of logic, for testing purposes.
	["test"] = function(...)
		print(" ");
		ArenaAnalytics:Print(" ================================================  ");

		for classIndex = 1, GetNumClasses() do
			local classDisplayName, classToken, classID = GetClassInfo(classIndex)
			ArenaAnalytics:Log(classToken, classDisplayName, " (Index: ", classIndex, ")")

			for specIndex = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(classID) do
				local specID, specName = GetSpecializationInfoForClassID(classID, specIndex)
				if(specID) then
					ArenaAnalytics:Log("    ", specID, " - ", specName, API:GetMappedAddonSpecID(specID));
					if(GetSpecializationInfoByID(specID)) then
						ArenaAnalytics:Log("    ", GetSpecializationInfoByID(specID));
					end
				end
			end
		end

		-- MoP Missing specs info:
		-- Warrior 1
		-- Paladin 2
		-- Mage 8
		-- Monk 10
		-- Druid 11

		ArenaAnalytics:Print(" ");
	end,

	["inspect"] = function(...)
		ArenaAnalytics.Debug:NotifyInspectSpec(...);
	end,
};

local function HandleSlashCommands(str)	
	if (#str == 0) then	
		-- User just entered "/aa" with no additional args.
		ArenaAnalytics:Toggle();
		return;
	end

	local args = {};
	for _, arg in ipairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end
	
	local path = ArenaAnalytics.commands; -- required for updating found table.
	
	for id, arg in ipairs(args) do
		if (#arg > 0) then -- if string length is greater than 0.
			arg = arg:lower();			
			if (path[arg]) then
				if (type(path[arg]) == "function") then				
					-- all remaining args passed to our function!
					path[arg](select(id + 1, unpack(args))); 
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg]; -- another sub-table found!
				end
			else
				-- does not exist!
				ArenaAnalytics.commands.help();
				return;
			end
		end
	end
end

-------------------------------------------------------------------------

function ArenaAnalytics:Print(...)
    local hex = select(4, ArenaAnalytics:GetThemeColor());
    local prefix = string.format("|cff%s%s|r", hex:upper(), "ArenaAnalytics:");
    -- DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
	print(prefix, ...);
end

function ArenaAnalytics:PrintSystem(...)
	if(not Options:Get("printAsSystem")) then
		ArenaAnalytics:Print(...);
		return;
	end

    local hex = select(4, ArenaAnalytics:GetThemeColor());

	local params = {...};
	for key,value in pairs(params) do
		if(params[key] == nil) then
			params[key] = "nil";
		end
	end

	SendSystemMessage(format("|cff%sArenaAnalytics:|r |cffffffff%s|r", hex, table.concat(params, " ")));
end

function ArenaAnalytics:PrintSystemSpacer()
	if(not Options:Get("printAsSystem")) then
		print(" ");
		return;
	end

	SendSystemMessage(" ");
end

-------------------------------------------------------------------------

-- Returns devault theme color
function ArenaAnalytics:GetThemeColor()
	local defaults = {
		theme = {
			r = 0, 
			g = 0.8,
			b = 1,
			hex = "00ccff"
		}
	}
	local c = defaults.theme;
	return c.r, c.g, c.b, c.hex;
end

function ArenaAnalytics:GetTitleColored(asSingleColor)
	local hex = select(4, ArenaAnalytics:GetThemeColor());

	if(asSingleColor) then
		return "|cff".. hex .."ArenaAnalytics|r";
	else
		return "Arena|cff".. hex .."Analytics|r";
	end
end

-- Toggles addOn view/hide
function ArenaAnalytics:Toggle()
    if (not ArenaAnalyticsScrollFrame:IsShown()) then  
        Selection:ClearSelectedMatches();

        Filters:Refresh(function()
            AAtable:RefreshLayout();
        end);

        Dropdown:CloseAll();
        Tooltips:HideAll();

        ArenaAnalyticsScrollFrame:Show();
    else
        ArenaAnalyticsScrollFrame:Hide();
    end
end

function ArenaAnalytics:OpenOptions()
    if(Options.Open) then
        Options:Open();
    end
end

function ArenaAnalytics.HandleChatAfk(message)
	ArenaAnalytics:Log("/afk override triggered.");
	local surrendered = API:TrySurrenderArena("afk");
	if(surrendered == nil) then
		-- Fallback to base /afk
		SendChatMessage(message, "AFK");
	end
end

function ArenaAnalytics.HandleGoodGame()
	ArenaAnalytics:Log("/gg triggered.");
	API:TrySurrenderArena("gg");
end

function ArenaAnalytics.UpdateSurrenderCommands()
	if(not API:HasSurrenderAPI()) then
		return;
	end

	local isAfkOverrideActive = (SlashCmdList.CHAT_AFK == ArenaAnalytics.HandleChatAfk);
	if(Options:Get("enableSurrenderAfkOverride")) then
		if(not isAfkOverrideActive) then
			ArenaAnalytics.previousAfkFunc = SlashCmdList.CHAT_AFK;
			SlashCmdList.CHAT_AFK = ArenaAnalytics.HandleChatAfk;
		end
	elseif(isAfkOverrideActive and ArenaAnalytics.previousAfkFunc) then
		SlashCmdList.CHAT_AFK = ArenaAnalytics.previousAfkFunc;
	end

	local hasGoodGameCommand = (SLASH_ArenaAnalyticsSurrender1 ~= nil and SlashCmdList.ArenaAnalyticsSurrender ~= nil);
	if(Options:Get("enableSurrenderGoodGameCommand")) then
		if(not hasGoodGameCommand) then
			-- /gg to surrender
			SLASH_ArenaAnalyticsSurrender1 = "/gg";
			SlashCmdList.ArenaAnalyticsSurrender = ArenaAnalytics.HandleGoodGame;
		end
	elseif(hasGoodGameCommand) then
		SLASH_ArenaAnalyticsSurrender1 = nil;
		SlashCmdList.ArenaAnalyticsSurrender = nil;
	end
end

local function PrintWelcomeMessage()
	local welcomeMessageSeed = random(1, 10000);
	local text;

	local name = UnitNameUnmodified("player");

	if(welcomeMessageSeed < 10) then
		text = "You're being tracked.";
	elseif(welcomeMessageSeed < 100) then
		text = format("Have a wonderful day, %s!", name);
	elseif(welcomeMessageSeed == 213) then
		text = format("I'm watching you, %s!", name);
	else
		text = format("Tracking arena games, glhf %s!!", name);
	end

    ArenaAnalytics:PrintSystem(text);
end

function ArenaAnalytics:init()
	ArenaAnalytics:Log("Initializing..");

	-- allows using left and right buttons to move through chat 'edit' box
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
	end

	local version = API:GetAddonVersion();
	local versionText = version ~= -1 and " (Version: " .. version .. ")" or ""

	-- Welcome Message
	PrintWelcomeMessage();
	
	Debug:OnLoad();

	local successfulRequest = C_ChatInfo.RegisterAddonMessagePrefix("ArenaAnalytics");
	if(not successfulRequest) then
		ArenaAnalytics:Log("Failed to register Addon Message Prefix: 'ArenaAnalytics'!")
	end

	---------------------------------
	-- Register Slash Commands
	---------------------------------
	SLASH_ArenaAnalyticsCommands1 = "/AA";
	SLASH_ArenaAnalyticsCommands2 = "/ArenaAnalytics";
	SlashCmdList.ArenaAnalyticsCommands = HandleSlashCommands;

	if(API:HasSurrenderAPI()) then
		-- Override /afk to surrender in arenas
		SlashCmdList.CHAT_AFK = function(message)
			local surrendered = API:TrySurrenderArena("afk");
			if(surrendered == nil) then
				-- Fallback to base /afk
				SendChatMessage(message, "AFK");
			end
		end

		-- /gg to surrender
		SLASH_ArenaAnalyticsSurrender1 = "/gg";
		SlashCmdList.ArenaAnalyticsSurrender = function(msg)
			ArenaAnalytics:Log("/gg triggered.");
			local surrendered = API:TrySurrenderArena("gg");
		end
	end

	---------------------------------
	-- Initialize modules
	---------------------------------

	Bitmap:Initialize();
	Internal:Initialize();
	ArenaAnalytics:InitializeArenaAnalyticsDB();
	Search:Initialize();
	API:Initialize();
	Options:Init();
	FilterTables:Init();
	Filters:Init();

	---------------------------------
	-- Version Control
	---------------------------------

	VersionManager:OnInit();

	---------------------------------
	-- Startup
	---------------------------------

	-- Setup surrender commands
	ArenaAnalytics.UpdateSurrenderCommands();

	MinimapButton:Update();

	ArenaAnalytics:TryFixLastMatchRating();
	Events:RegisterGlobalEvents();

	-- Update cached rating as soon as possible, through PVP_RATED_STATS_UPDATE event
	RequestRatedInfo();

	AAtable:OnLoad();

	if(IsInInstance() or IsInGroup(1)) then
		local channel = IsInInstance() and "INSTANCE_CHAT" or "PARTY";
		local messageSuccess = C_ChatInfo.SendAddonMessage("ArenaAnalytics", UnitGUID("player") .. "_deliver|version#?=" .. version, channel)
	end

	-- Already in an arena
	if (not API:IsInArena() and ArenaAnalyticsDB.currentArena) then
		ArenaTracker:Clear();
	end
end

-- Delay the init a frame, to allow all files to be loaded
function ArenaAnalytics:delayedInit(event, name, ...)
	if (name ~= "ArenaAnalytics") then 
		return;
	end

	MinimapButton:Update();

	ArenaAnalyticsScrollFrame:Hide();
	C_Timer.After(0, function() ArenaAnalytics.init() end);
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", ArenaAnalytics.delayedInit);