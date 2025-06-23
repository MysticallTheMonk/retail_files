local _, ArenaAnalytics = ...; -- Addon Namespace
local Import = ArenaAnalytics.Import;

-- Local module aliases
local Sessions = ArenaAnalytics.Sessions;
local TablePool = ArenaAnalytics.TablePool;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local Filters = ArenaAnalytics.Filters;
local Helpers = ArenaAnalytics.Helpers;
local Debug = ArenaAnalytics.Debug;
local ImportBox = ArenaAnalytics.ImportBox;
local ImportProgressFrame = ArenaAnalytics.ImportProgressFrame;

-------------------------------------------------------------------------

--[[
    isEnemy
    isSelf
    name
    race_id
    spec_id
    kills
    deaths
    damage
    healing
    wins
    rating
    ratingDelta
    mmr
    mmrDelta
--]]

--[[
    Current Import structure:
        count
        sourceName
        processorFunc
        state
--]]

-------------------------------------------------------------------------

-- Processing
local batchTimeLimit = 0.01;

Import.isImporting = false;
Import.raw = nil;
Import.current = nil;

function Import:IsLocked()
    return not Import.isImporting;
end

function Import:GetSourceName()
    if(Import.current and Import.current.isValid) then
        return Import.current.sourceName or "[Missing Name]";
    end
    return "Invalid";
end

function Import:Reset()
    if(Import.isImporting) then
        return;
    end

    ImportBox:ResetAll();
    ImportProgressFrame:Stop();

    Import.raw = nil;
    Import.current = nil;
    Import.state = nil;
end

function Import:Cancel()
    if(not Import.isImporting) then
        return;
    end

    Import:Finalize();
    Import.isImporting = false;

    C_Timer.After(0, Import.Reset);
end

function Import:TryHide(forced)
    if(ArenaAnalyticsScrollFrame.importDialogFrame ~= nil) then
        if(ArenaAnalytics:HasStoredMatches() or forced) then
            ArenaAnalyticsScrollFrame.importDialogFrame:Hide();
            ArenaAnalyticsScrollFrame.importDialogFrame = nil;
        end
    end
end

function Import:ProcessImportSource()
    local newImportData = {}
    local isValid = false;

    if(not Import.raw or #Import.raw == 0) then
        Import.current = nil;
        return false;
    end

    -- ArenaAnalytics v3
    if(Import:CheckDataSource_ArenaAnalytics(newImportData)) then
        isValid = true;
    elseif(Import:CheckDataSource_ArenaStatsCata(newImportData)) then
        isValid = true;
    elseif(Import:CheckDataSource_ArenaStatsWrath(newImportData)) then
        isValid = true;
    elseif(Import:CheckDataSource_ReflexArenas(newImportData)) then
        isValid = true;
    else
        Import.current = nil;
    end

    Import.current = newImportData;
    return false;
end

function Import:SetPastedInput(pasteBuffer)
    ArenaAnalytics:Log("Finalizing import paste.");

    Import.raw = pasteBuffer and string.trim(table.concat(pasteBuffer)) or nil;
    Import:ProcessImportSource();
end

function Import:ParseRawData()
    if(not Import.raw or Import.raw == "") then
        Import:Reset();
        return;
    end

    if(not Import.current or not Import.current.isValid or not Import.current.processorFunc) then
        ArenaAnalytics:Log("Invalid data for import attempt.. Bailing out immediately..");
        Import:Reset();
        return;
    end

    Import:ProcessImport();
end

local function GetFirstAndLastStoredDateLimits()
    local first, last;

    for i=1, #ArenaAnalyticsDB do
        local match = ArenaAnalytics:GetMatch(i);
        local date = ArenaMatch:GetDate(match);
        if(date and date > 0) then
            if(not first or date < first) then
                first = date;
            end

            if(not last or date > last) then
                last = date;
            end
        end
    end

    -- Adjust to limits
    local minimumOffset = 86400;
    first = first and first - minimumOffset; -- 24 hours before first match
    last = last and last + minimumOffset; -- 24 hours after last match

    return first, last;
end 

-- Check a date for a duplicate, in case of repeating same import
function Import:CheckDate(timestamp)
    if(not timestamp or timestamp == 0) then
        ArenaAnalytics:LogError("Rejecting import arena for invalid date:", timestamp);
        return false;
    end

    if(Import.state) then
        local firstLimit = Import.state.firstTimestampLimit;
        local lastLimit = Import.state.lastTimestampLimit;

        if(firstLimit and lastLimit) then
            if(timestamp > firstLimit and timestamp < lastLimit) then
                return false;
            end
        end
    end

    return true;
end

local function ArenaIterator()
    return coroutine.wrap(function()
        for arena in Import.raw:gmatch("[^\n]+") do
            coroutine.yield(arena);
        end
    end);
end

-- Initiate processing
function Import:ProcessImport()
    Import.isImporting = true;
    local iterator = ArenaIterator() -- Create the iterator

    -- Progress state data
    Import.state = TablePool:Acquire();
    local state = Import.state;

    state.startTime = GetTimePreciseSec();
    state.index = 0;

    local _, importCount = Import.raw:gsub("\n", "");
    state.total = importCount - 1;
    state.existing = #ArenaAnalyticsDB;
    state.skippedArenaCount = 0;

    state.firstTimestampLimit, state.lastTimestampLimit = GetFirstAndLastStoredDateLimits();

    if(importCount > 0) then
        -- Hide import dialogue
        Import:TryHide(true);
    end

    ImportProgressFrame:Start();

    -- Batched proccessing
    local function ProcessBatch()
        local batchEndTime = GetTimePreciseSec() + batchTimeLimit;

        while GetTimePreciseSec() < batchEndTime do
            if(not Import.isImporting) then
                ArenaAnalytics:Log("Import: Processor func missing, bailing out at index:", state.index + 1);
                Import:Finalize();
                return;
            end

            local arenaString = iterator();
            if(state and state.index and state.index > 0) then -- First iteration is the format prefix, before arena index 1
                if(not arenaString) then
                    ArenaAnalytics:Log("Empty arenaString")
                    Import:Finalize();
                    return;
                end

                local processedArena = Import.current.processorFunc(arenaString);
                if(processedArena) then
                    Import:SaveArena(processedArena);
                    TablePool:ReleaseNested(processedArena); -- Release nested or simple release?
                else
                    state.skippedArenaCount = state.skippedArenaCount + 1;
                end
            end

            state.index = state.index + 1;
        end

        C_Timer.After(0, ProcessBatch);
    end

    C_Timer.After(0, ProcessBatch);
end

function Import:Finalize()
    if(not Import.isImporting) then
        return;
    end

    -- Force update before potential freeze from resorting matches.
    ImportProgressFrame:Update();

    Import.isImporting = nil;

    local state = Import.current and Import.state;

    local elapsed, existingCount;
    if(state) then
        elapsed = state.startTime and (GetTimePreciseSec() - state.startTime) or 0;
        existingCount = state.existing or 0;
    else
        elapsed = 0;
        existingCount = 0;
    end

    Import:Reset();
    Import:TryHide();

    ArenaAnalytics:ResortMatchHistory();

    Sessions:RecomputeSessionsForMatchHistory();
    ArenaAnalytics.unsavedArenaCount = #ArenaAnalyticsDB;

    Filters:Refresh();

    local elapsedText = elapsed and format(" in %.1f seconds.", elapsed) or "";
    ArenaAnalytics:PrintSystem(format("Import complete. %d arenas added.%s", (#ArenaAnalyticsDB - existingCount), elapsedText));
    ArenaAnalytics:Log(format("Import ignored %d arenas due to their date.", (state and state.skippedArenaCount or -1)));
end

function Import:SaveArena(arena)
    -- Fill the arena by ArenaMatch formatting
    local newArena = {}
	ArenaMatch:SetDate(newArena, arena.date);
	ArenaMatch:SetDuration(newArena, arena.duration);
	ArenaMatch:SetMap(newArena, arena.map);

	ArenaMatch:SetBracket(newArena, arena.bracket);

	local matchType = nil;
	if(arena.isRated) then
		matchType = "rated";
	elseif(arena.isWargame) then
		matchType = "wargame";
	else
		matchType = "skirmish";
	end

	ArenaMatch:SetMatchType(newArena, matchType);

	if (arena.isRated) then
		ArenaMatch:SetPartyRating(newArena, arena.partyRating);
		ArenaMatch:SetPartyRatingDelta(newArena, arena.partyRatingDelta);
		ArenaMatch:SetPartyMMR(newArena, arena.partyMMR);

		ArenaMatch:SetEnemyRating(newArena, arena.enemyRating);
		ArenaMatch:SetEnemyRatingDelta(newArena, arena.enemyRatingDelta);
		ArenaMatch:SetEnemyMMR(newArena, arena.enemyMMR);
	end

	ArenaMatch:SetSeason(newArena, arena.season);

	ArenaMatch:SetMatchOutcome(newArena, arena.outcome);

	-- Add players from both teams sorted, and assign comps.
	ArenaMatch:AddPlayers(newArena, arena.players);

	if(arena.isShuffle) then
		ArenaMatch:SetRounds(newArena, arena.committedRounds);
	end

	-- Assign session
	local session = Sessions:GetLatestSession();
	local lastMatch = ArenaAnalytics:GetLastMatch();
	if (not Sessions:IsMatchesSameSession(lastMatch, newArena)) then
		session = session + 1;
	end

	ArenaMatch:SetSession(newArena, session);

	-- Insert arena data as a new ArenaAnalyticsDB entry
	table.insert(ArenaAnalyticsDB, newArena);
end

-------------------------------------------------------------------------

function Import:RetrieveBool(value)
    if(value == nil or value == "") then
        return nil;
    end

    value = Helpers:ToSafeLower(value);

    -- Support multiple affirmative values
    return (value == "yes") or (value == "1") or (value == "true") or (value == true) or false;
end

function Import:RetrieveSimpleOutcome(value)
    local isWin = Import:RetrieveBool(value);

    if(isWin == nil) then
        return nil;
    end

    return isWin and 1 or 0;
end