local _, ArenaAnalytics = ...; -- Addon Namespace
local Filters = ArenaAnalytics.Filters;

-- Local module aliases
local Options = ArenaAnalytics.Options;
local Search = ArenaAnalytics.Search;
local Selection = ArenaAnalytics.Selection;
local AAtable = ArenaAnalytics.AAtable;
local ArenaMatch = ArenaAnalytics.ArenaMatch;
local TablePool = ArenaAnalytics.TablePool;
local Sessions = ArenaAnalytics.Sessions;
local Debug = ArenaAnalytics.Debug;
local API = ArenaAnalytics.API;

-------------------------------------------------------------------------

-- Currently applied filters
local currentFilters = {}
local defaults = {}

-- Adds a filter, setting current and default values
local function AddFilter(filter, default)
    assert(filter ~= nil);
    assert(default ~= nil, "Nil values for filters are not supported. Using values as display texts.");

    local override = Filters:GetOverride(filter);

    currentFilters[filter] = (override ~= nil) and override or default;
    defaults[filter] = default;
end

function Filters:Init() 
    AddFilter("Filter_Date", "All Time");
    AddFilter("Filter_Season", "All");
    AddFilter("Filter_Map", "All");
    AddFilter("Filter_Outcome", "All");
    AddFilter("Filter_Bracket", "All");
    AddFilter("Filter_Comp", "All");
    AddFilter("Filter_EnemyComp", "All");
end

function Filters:GetOverride(filter)
    if(filter == "Filter_Date" and Options:Get("defaultCurrentSessionFilter")) then
        return "Current Session";
    end

    if(filter == "Filter_Season" and Options:Get("defaultCurrentSeasonFilter")) then
        return "Current Season";
    end
end

function Filters:IsValidCompKey(compKey)
    return compKey == "Filter_Comp" or compKey == "Filter_EnemyComp";
end

function Filters:Get(filter)
    assert(filter, "Invalid filter in Filters:Get(...)");

    if(not currentFilters[filter]) then
        currentFilters[filter] = Filters:GetDefault(filter);
    end

    return currentFilters[filter];
end

function Filters:GetDefault(filter, skipOverrides)
    -- overrides
    if(not skipOverrides) then
        local override = Filters:GetOverride(filter);
        if(override ~= nil) then
            return override;
        end
    end

    return defaults[filter];
end

function Filters:Set(filter, value)
    assert(filter and currentFilters[filter]);
    value = value or Filters:GetDefault(filter);

    if(value == currentFilters[filter]) then
        return;
    end

    -- Reset comp filters when bracket filter changes
    if (filter == "Filter_Bracket") then
        Filters:Reset("Filter_Comp");
        Filters:Reset("Filter_EnemyComp");
    end

    --ArenaAnalytics:Log("Setting filter:", filter, "to value:", (type(value) == "string" and value:gsub("|", "||") or "nil"));
    currentFilters[filter] = value;

    Filters:Refresh();
end

function Filters:Reset(filter, skipOverrides)
    assert(currentFilters[filter] and defaults[filter], "Invalid filter: " .. (filter and filter or "nil"));
    local default = Filters:GetDefault(filter, skipOverrides);

    local changed = (Filters:Get(filter) ~= default);

    Filters:Set(filter, default);
end

-- Clearing filters, optionally keeping filters explicitly applied through options
function Filters:ResetAll(skipOverrides)
    local changed = false;
    changed = Filters:Reset("Filter_Date", skipOverrides) or changed;
    changed = Filters:Reset("Filter_Season", skipOverrides) or changed;
    changed = Filters:Reset("Filter_Map") or changed;
    changed = Filters:Reset("Filter_Outcome") or changed;
    changed = Filters:Reset("Filter_Bracket") or changed;
    changed = Filters:Reset("Filter_Comp") or changed;
    changed = Filters:Reset("Filter_EnemyComp") or changed;

    changed = Search:Reset() or changed;

    if(changed) then
        ArenaAnalytics:Log("Filters has been reset. Refreshing.");
        Filters:Refresh();
    end
end

function Filters:IsFilterActive(filter, ignoreOverrides)
    local current = currentFilters[filter];
    if (current ~= nil) then
        return current ~= Filters:GetDefault(filter, ignoreOverrides);
    end

    ArenaAnalytics:Log("isFilterActive failed to find filter: ", filter);
    return false;
end

function Filters:GetActiveFilterCount()
    local count = 0;
    if(not Search:IsEmpty()) then
        count = count + 1;
    end
    if(Filters:IsFilterActive("Filter_Date")) then
        count = count + 1;
    end
    if(Filters:IsFilterActive("Filter_Season")) then
        count = count + 1;
    end
    if(Filters:IsFilterActive("Filter_Map")) then
        count = count + 1;
    end
    if(Filters:IsFilterActive("Filter_Outcome")) then
        count = count + 1;
    end
    if(Filters:IsFilterActive("Filter_Bracket")) then
        count = count + 1;
    end
    if(Filters:IsFilterActive("Filter_Comp")) then
        count = count + 1;
    end
    if(Filters:IsFilterActive("Filter_EnemyComp")) then
        count = count + 1; 
    end
    return count;
end

-- check map filter
local function doesMatchPassFilter_Map(match)
    if match == nil then return false end;

    local filter = Filters:Get("Filter_Map");
    if(not filter or filter == "All") then
        return true;
    end

    return ArenaMatch:GetMapID(match) == filter;
end

-- check outcome filter
local function doesMatchPassFilter_Outcome(match)
    if match == nil then return false end; 

    local filter = Filters:Get("Filter_Outcome");
    if(not filter or filter == "All") then
        return true;
    end

    return ArenaMatch:GetMatchOutcome(match) == filter;
end

-- check bracket filter
local function doesMatchPassFilter_Bracket(match)
    if not match then 
        return false;
    end

    if(currentFilters["Filter_Bracket"] == "All") then
        return true;
    end

    return ArenaMatch:GetBracketIndex(match) == currentFilters["Filter_Bracket"];
end

-- check season filter
local function doesMatchPassFilter_Date(match)
    if match == nil then return false end;

    local value = currentFilters["Filter_Date"] and currentFilters["Filter_Date"] or "";
    value = value and value:lower() or "";
    local seconds = 0;
    if(value == "all time" or value == "") then
        return true;
    elseif(value == "current session") then        
        return ArenaMatch:GetSession(match) == Sessions:GetLatestSession();
    elseif(value == "last day") then
        seconds = 86400;
    elseif(value == "last week") then
        seconds = 604800;
    elseif(value == "last month") then -- 31 days
        seconds = 2678400;        
    elseif(value == "last 3 months") then
        seconds = 7889400;
    elseif(value == "last 6 months") then
        seconds = 15778800;
    elseif(value == "last year") then
        seconds = 31536000;
    end

    return (ArenaMatch:GetDate(match) or 0) > (time() - seconds);
end

-- check season filter
local function doesMatchPassFilter_Season(match)
    if match == nil then return false end;

    local season = currentFilters["Filter_Season"];
    Debug:Assert(season ~= nil);
    if(season == "All") then
        return true;
    end
    
    if(season == "Current Season") then
        return ArenaMatch:GetSeason(match) == API:GetCurrentSeason();
    end
    
    return ArenaMatch:GetSeason(match) == tonumber(season);
end

-- check comp filters (comp / enemy comp)
local function doesMatchPassFilter_Comp(match, isEnemyComp)
    if match == nil then 
        return false;
    end

    -- Skip comp filter when no bracket is selected
    if(currentFilters["Filter_Bracket"] == "All") then
        return true;
    end

    local compFilterKey = isEnemyComp and "Filter_EnemyComp" or "Filter_Comp";
    if(currentFilters[compFilterKey] == "All") then
        return true;
    end

    return ArenaMatch:HasComp(match, currentFilters[compFilterKey], isEnemyComp);
end

function Filters:doesMatchPassGameSettings(match)
    local matchType = ArenaMatch:GetMatchType(match);
    if (not Options:Get("showSkirmish") and matchType == "skirmish") then
        return false;
    end

    if (not Options:Get("showWarGames") and matchType == "wargame") then
        return false;
    end

    return true;
end

-- check all filters
function Filters:DoesMatchPassAllFilters(match, excluded)
    if(not match) then
        return false;
    end

    if(not Filters:doesMatchPassGameSettings(match)) then
        return false;
    end

    -- Season
    if(not doesMatchPassFilter_Season(match)) then
        return false;
    end

    -- Map
    if(not doesMatchPassFilter_Map(match)) then
        return false;
    end

    -- Outcome
    if(not doesMatchPassFilter_Outcome(match)) then
        return false;
    end

    -- Bracket
    if(not doesMatchPassFilter_Bracket(match)) then
        return false;
    end

    -- Comp
    if(excluded ~= "comps" and excluded ~= "comp" and not doesMatchPassFilter_Comp(match, false)) then
        return false;
    end

    -- Enemy Comp
    if(excluded ~= "comps" and excluded ~= "enemyComp" and not doesMatchPassFilter_Comp(match, true)) then
        return false;
    end

    -- Time frame
    if(not doesMatchPassFilter_Date(match)) then
        return false;
    end

    -- Search
    if(not Search:DoesMatchPassSearch(match)) then
        return false;
    end

    return true;
end


-------------------------------------------------------------------------
-- Refresh processing

local transientCompData = TablePool:Acquire();

local function ResetTransientCompData()
    TablePool:ReleaseNested(transientCompData);

    transientCompData = {
        Filter_Comp = { ["All"] = {} },
        Filter_EnemyComp = { ["All"] = {} },
    };
end

local function SafeIncrement(table, key, delta)
    table[key] = (table[key] or 0) + (delta or 1);
end

local function findOrAddCompValues(compsTable, comp, isWin, mmr)
    assert(compsTable);
    if comp == nil then 
        return;
    end

    compsTable[comp] = compsTable[comp] or TablePool:Acquire();

    -- Played
    SafeIncrement(compsTable[comp], "played");

    -- Win count
    if isWin then
        SafeIncrement(compsTable[comp], "wins");
    end

    -- MMR Data     (Used to convert mmr to average mmr later)
    if tonumber(mmr) then
        SafeIncrement(compsTable[comp], "mmr", tonumber(mmr));
        SafeIncrement(compsTable[comp], "mmrCount");
    end
end

local function AddToCompData(match, isEnemyTeam)
    assert(match);
    local compKey = isEnemyTeam and "Filter_EnemyComp" or "Filter_Comp";
    assert(transientCompData[compKey]);

    local function AddData(comp, outcome, mmr)
        local isWin = (outcome == 1);

        -- Add to "All" data
        findOrAddCompValues(transientCompData[compKey], "All", isWin, mmr);

        -- Add comp specific data
        if(comp ~= nil) then
            findOrAddCompValues(transientCompData[compKey], comp, isWin, mmr);
        end
    end

    if(ArenaMatch:IsShuffle(match)) then
        local rounds = ArenaMatch:GetRounds(match);
        local roundCount = rounds and #rounds or 0;

        for roundIndex=1, roundCount do
            local comp, outcome, mmr = ArenaMatch:GetCompInfo(match, isEnemyTeam, roundIndex);
            AddData(comp, outcome, mmr);
        end
    else
        local comp, outcome, mmr = ArenaMatch:GetCompInfo(match, isEnemyTeam);
        AddData(comp, outcome, mmr);
    end
end

local function FinalizeCompDataTables()
    local compKeys = { "Filter_Comp", "Filter_EnemyComp" }
    for _,compKey in ipairs(compKeys) do
        -- Compute winrates and average mmr
        local compData = transientCompData[compKey];
        if(compData) then
            for _, compTable in pairs(compData) do
                -- Calculate winrate
                local played = tonumber(compTable.played) or 0;
                local wins = tonumber(compTable.wins) or 0;
                compTable.winrate = (played > 0) and math.floor(wins * 100 / played) or 0;

                -- Calculate average MMR
                local mmr = tonumber(compTable.mmr);
                local mmrCount = tonumber(compTable.mmrCount);
                if mmr and mmrCount and mmrCount > 0 then
                    compTable.mmr = math.floor(mmr / mmrCount);
                    compTable.mmrCount = nil;
                else
                    -- No MMR data
                    compTable.mmr = nil;
                    compTable.mmrCount = nil;
                end
            end
        end
    end
end

local function RecomputeFilteredSession()
    local cachedRealSession = 0;
    local filteredSession = 0;

    for i=ArenaAnalytics.filteredMatchCount, 1, -1 do
        local match = ArenaAnalytics:GetFilteredMatch(i);
        local nextMatch = ArenaAnalytics:GetFilteredMatch(i+1);

        local session = ArenaMatch:GetSession(match);
        local nextSession = ArenaMatch:GetSession(nextMatch);

        if(not nextMatch or session ~= nextSession) then
            filteredSession = filteredSession + 1;
        end

        ArenaAnalytics.filteredMatchHistory[i].filteredSession = filteredSession;
    end
end

local function ProcessMatchIndex(index)
    assert(index);

    local match = ArenaAnalytics:GetMatch(index);
    if(match and Filters:DoesMatchPassAllFilters(match, "comps")) then
        local doesPassComp = doesMatchPassFilter_Comp(match, false);
        local doesPassEnemyComp = doesMatchPassFilter_Comp(match, true);

        if(Filters:IsFilterActive("Filter_Bracket")) then
            if(doesPassEnemyComp) then
                AddToCompData(match, false);
            end
            
            if(doesPassComp) then
                AddToCompData(match, true);
            end
        end

        if(doesPassComp and doesPassEnemyComp) then
            local filteredIndex = ArenaAnalytics.filteredMatchCount + 1;
            ArenaAnalytics.filteredMatchCount = filteredIndex;

            if(filteredIndex > #ArenaAnalytics.filteredMatchHistory) then
                tmpCount = (tmpCount or 0) + 1;
                table.insert(ArenaAnalytics.filteredMatchHistory, {});
            end

            local filteredMatch = ArenaAnalytics.filteredMatchHistory[filteredIndex];
            filteredMatch.index = index;
        end
    end
end

Filters.isRefreshing = nil;
-- Returns matches applying current match filters
function Filters:Refresh(onCompleteFunc)
    if(Filters.isRefreshing) then
        ArenaAnalytics:Log("Refreshing called while locked. Has onComplete: ", onCompleteFunc ~= nil);
        return;
    end
    Filters.isRefreshing = true;

    -- Reset tables
    ArenaAnalytics.filteredMatchCount = 0;    
    Selection:ClearSelectedMatches();
    ResetTransientCompData();
    cachedRealSession = 0;

    local currentIndex = 1;
    local batchDurationLimit = 0.01;

    local startTime = GetTime();

    local function Finalize()
        -- Assign session to filtered matches
        FinalizeCompDataTables();
        ArenaAnalytics:SetCurrentCompData(transientCompData);
        ResetTransientCompData();

        RecomputeFilteredSession();

        AAtable:ForceRefreshFilterDropdowns();
        AAtable:HandleArenaCountChanged();

        if(onCompleteFunc) then
            onCompleteFunc();
        end

        C_Timer.After(0, function() 
			local newTime = GetTime();
			local elapsed = 1000 * (newTime - startTime);
			ArenaAnalytics:Log("Refreshed filters in:", elapsed, "ms.");
		end);

        Filters.isRefreshing = nil;
    end

    local function ProcessBatch()
        local batchEndTime = GetTime() + batchDurationLimit;

        while currentIndex <= #ArenaAnalyticsDB do
            ProcessMatchIndex(currentIndex);
            currentIndex = currentIndex + 1;

            if(batchEndTime < GetTime()) then
                C_Timer.After(0, ProcessBatch);
                return;
            end
        end

        Finalize();
    end

    -- Start processing batches
    ProcessBatch()
end