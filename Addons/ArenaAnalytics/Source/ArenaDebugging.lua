local _, ArenaAnalytics = ...; -- Addon Namespace
ArenaAnalytics.Debug = {};

-- Local module aliases
local Debug = ArenaAnalytics.Debug;

-------------------------------------------------------------------------

function ArenaAnalytics:GetDebugLevel()
    return tonumber(ArenaAnalyticsSharedSettingsDB["debuggingLevel"]) or 0;
end

function Debug:SetDebugLevel(level)
    local currentLevel = ArenaAnalytics.Options:Get("debuggingLevel");

    level = tonumber(level) or (currentLevel == 0 and 3) or 0;
    if(level == currentLevel and level > 0) then
        level = 0;
    end

    ArenaAnalytics.Options:Set("debuggingLevel", level);

    if(ArenaAnalytics:GetDebugLevel() == 0) then
        ArenaAnalytics:PrintSystem("Debugging disabled!");
    else
        ArenaAnalytics:LogForced(string.format("Debugging level %d enabled!", level));
    end
end

-------------------------------------------------------------------------
-- Logging

local logColor = "FF6EC7";
local warningColor = "FFD700";
local errorColor = "ff1111";
local logGreenColor = "1EFFA7";
local tempColor = "FE42EE";

function Debug:OnLoad()
    local debugLevel = ArenaAnalytics:GetDebugLevel();
	if(debugLevel > 0) then
        ArenaAnalytics:LogForced(string.format("Debugging Enabled at level: %d!  |cffBBBBBB/aa debug to disable.|r", debugLevel));
	end
end

-- Debug logging version of print
function ArenaAnalytics:LogSpacer()
	if(ArenaAnalytics:GetDebugLevel() < 1) then
		return;
	end

	print(" ");
end

-- Basic log forced regardless of debug level
function ArenaAnalytics:LogForced(...)
    local prefix = string.format("|cff%s%s|r", logColor, "ArenaAnalytics (Debug):");
	print(prefix, ...);
end

-------------------------------------------------------------------------
-- Debug level 1 (Error)

function ArenaAnalytics:LogError(...)
    if(ArenaAnalyticsSharedSettingsDB["hideErrorLogs"]) then
        return;
    end

    local prefix = string.format("|cff%s%s|r", errorColor, "ArenaAnalytics (Error):");
	print(prefix, ...);
end

-- Assert if debug is enabled. Returns value to allow wrapping within if statements.
function Debug:Assert(value, msg)
	if(ArenaAnalytics:GetDebugLevel() > 0) then
		assert(value, "Debug Assertion failed! " .. (msg or ""));
	end
	return value;
end

-------------------------------------------------------------------------
-- Debug level 2 (Warning)

function ArenaAnalytics:LogWarning(...)
	if(ArenaAnalytics:GetDebugLevel() < 2) then
		return;
	end

    local prefix = string.format("|cff%s%s|r", warningColor, "ArenaAnalytics (Warning):");
	print(prefix, ...);
end

-------------------------------------------------------------------------
-- Debug level 3 (Misc)
function ArenaAnalytics:Log(...)
	if(ArenaAnalytics:GetDebugLevel() < 3) then
		return;
	end

    ArenaAnalytics:LogForced(...);
end

function ArenaAnalytics:LogGreen(...)
	if(ArenaAnalytics:GetDebugLevel() < 3) then
		return;
	end

    local prefix = string.format("|cff%s%s|r", logGreenColor, "ArenaAnalytics (Debug):");
	print(prefix, ...);
end

function ArenaAnalytics:LogEscaped(...)
	if(ArenaAnalytics:GetDebugLevel() < 3) then
		return;
	end

    -- Process each argument and replace | with || in string values, to escape formatting
	local args = {...}
	for i = 1, #args do
		if(type(args[i]) == "string") then
			args[i] = args[i]:gsub("|", "||");
		end
	end

	-- Use unpack to print the modified arguments
	ArenaAnalytics:Log(unpack(args));
end

function Debug:LogFrameTime(context)
	if(ArenaAnalytics:GetDebugLevel() == 0) then
        return;
    end

    debugprofilestart();

    C_Timer.After(0, function()
        local elapsed = debugprofilestop();
        ArenaAnalytics:LogForced("DebugLogFrameTime:", elapsed, "Context:", context);
    end);
end

-------------------------------------------------------------------------
-- Temporary Debugging tools

function ArenaAnalytics:LogTemp(...)
	if(ArenaAnalytics:GetDebugLevel() < 1) then
		return;
	end

    local prefix = string.format("|cff%s%s|r", tempColor, "ArenaAnalytics (Temp):");
	print(prefix, ...);
end

function Debug:LogTable(table, level, maxLevel)
    if(ArenaAnalytics:GetDebugLevel() < 4) then
        return;
    end

    if(not table) then
        ArenaAnalytics:Log("DebugLogTable: Nil table");
        return;
    end

    level = level or 0;
    if(level > (maxLevel or 10)) then
        ArenaAnalytics:LogWarning("Debug:LogTable max level exceeded.");
        return;
    end

    local indentation = string.rep(" ", 3*level);

    if(type(table) ~= "table") then
        ArenaAnalytics:Log(indentation, table);
        return;
    end

    for key,value in pairs(table) do
        if(type(value) == "table") then
            ArenaAnalytics:Log(indentation, key);
            Debug:LogTable(value, level+1, maxLevel);
        else
            ArenaAnalytics:Log(indentation, key, value);
        end
    end
end

-------------------------------------------------------------------------
-- UI

-- Used to draw a solid box texture over a frame for testing
function Debug:DrawDebugBackground(frame, r, g, b, a)
	if(ArenaAnalytics:GetDebugLevel() < 5) then
        return;
	end

    -- TEMP testing
    if(not frame.debugBackground) then
        frame.debugBackground = frame:CreateTexture();
    end

    frame.debugBackground:SetAllPoints(frame);
    frame.debugBackground:SetColorTexture(r or 1, g or 0, b or 0, a or 0.4);
end

-- TEMP debugging
function Debug:PrintScoreboardStats(numPlayers)
	if(ArenaAnalytics:GetDebugLevel() < 5) then
        return;
	end

    local statIDs = {}
    local statNames = {}

    numPlayers = numPlayers or 1;

    for playerIndex=1, numPlayers do
        ArenaAnalytics:LogSpacer();

        local scoreInfo = C_PvP.GetScoreInfo(playerIndex);
        if(scoreInfo and scoreInfo.stats) then
            for i=1, #scoreInfo.stats do
                local stat = scoreInfo.stats[i];
                ArenaAnalytics:Log("Stat:", stat.pvpStatID, stat.pvpStatValue, stat.name);

                if(stat.pvpStatID) then
                    if(statIDs[stat.pvpStatID] and statIDs[stat.pvpStatID] ~= stat.name) then
                        ArenaAnalytics:Log("New stat name for ID!", stat.pvpStatID, stat.name);
                    end
                    statIDs[stat.pvpStatID] = stat.name;
                end
                
                if(stat.name) then
                    if(statIDs[stat.name] and statIDs[stat.name] ~= stat.pvpStatID) then
                        ArenaAnalytics:Log("New stat ID for name!", stat.pvpStatID, stat.name);
                    end
                    statNames[stat.name] = stat.pvpStatID;
                end
            end

            Debug:LogTable(scoreInfo and scoreInfo.stats);
        else
            ArenaAnalytics:Log("No current stats found!");
        end
    end
end

-------------------------------------------------------------------------
-- Inspection Debugging

local lastInspectUnitToken = "target";
function Debug:NotifyInspectSpec(unitToken)
    unitToken = unitToken or "target";
    if(not CanInspect(unitToken)) then
        return;
    end
    ClearInspectPlayer();
    lastInspectUnitToken = unitToken;
    ArenaAnalytics:Log("Inspecting:", unitToken);
    NotifyInspect(unitToken);
end

function Debug:HandleDebugInspect(GUID)
    local spec = nil;

    if(C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) then
        spec = C_SpecializationInfo.GetSpecialization(true);
    elseif(GetSpecialization ~= nil) then
        spec = GetSpecialization(true);
    end

    local spec2 = GetInspectSpecialization(lastInspectUnitToken);

    ArenaAnalytics:Log("HandleDebugInspect:", spec, spec2);
end
