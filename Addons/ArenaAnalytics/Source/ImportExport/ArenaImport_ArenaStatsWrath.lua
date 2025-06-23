local _, ArenaAnalytics = ...; -- Addon Namespace
local Import = ArenaAnalytics.Import;

-- Local module aliases
local API = ArenaAnalytics.API;
local TablePool = ArenaAnalytics.TablePool;
local Internal = ArenaAnalytics.Internal;
local Localization = ArenaAnalytics.Localization;

-------------------------------------------------------------------------

local sourceName = "ArenaStats (wrath)";

local formatPrefix = "isRanked,startTime,endTime,zoneId,duration,teamName,teamColor,"..
    "winnerColor,teamPlayerName1,teamPlayerName2,teamPlayerName3,teamPlayerName4,teamPlayerName5,"..
    "teamPlayerClass1,teamPlayerClass2,teamPlayerClass3,teamPlayerClass4,teamPlayerClass5,"..
    "teamPlayerRace1,teamPlayerRace2,teamPlayerRace3,teamPlayerRace4,teamPlayerRace5,"..
    "oldTeamRating,newTeamRating,diffRating,mmr,enemyOldTeamRating,enemyNewTeamRating,enemyDiffRating,enemyMmr,"..
    "enemyTeamName,enemyPlayerName1,enemyPlayerName2,enemyPlayerName3,enemyPlayerName4,enemyPlayerName5,"..
    "enemyPlayerClass1,enemyPlayerClass2,enemyPlayerClass3,enemyPlayerClass4,enemyPlayerClass5,"..
    "enemyPlayerRace1,enemyPlayerRace2,enemyPlayerRace3,enemyPlayerRace4,enemyPlayerRace5,"..
    "enemyFaction";

local valuesPerArena = 48;

function Import:CheckDataSource_ArenaStatsWrath(outImportData)
    if(not Import.raw or Import.raw == "") then
        return false;
    end

    if(formatPrefix ~= Import.raw:sub(1, #formatPrefix)) then
        return false;
    end

    -- Get arena count
    outImportData.isValid = true;
    outImportData.sourceName = sourceName;
    outImportData.prefixLength = #formatPrefix;
    outImportData.processorFunc = Import.ProcessNextMatch_ArenaStatsWrath;
    return true;
end

local function IsValidArena(values)
    return values and #values == (valuesPerArena + 1); -- Ends by comma, include a dummy last value.
end

-------------------------------------------------------------------------
-- Process arenas

local function IsValidValue(value)
    return value and value ~= "" and value ~= "Unknown";
end

local function GetMatchOutcome(cachedValues)
    local myTeam = cachedValues[7];
    local winningTeam = cachedValues[8];
    if(not IsValidValue(myTeam) or not IsValidValue(winningTeam)) then
        return nil;
    end

    local isWin = winningTeam == myTeam;
    return Import:RetrieveSimpleOutcome(isWin);
end

local function ProcessPlayer(cachedValues, isEnemyTeam, playerIndex, factionIndex)
    local valueIndex = (isEnemyTeam and 32 or 8) + playerIndex;

    local name = cachedValues[valueIndex];

    -- Assume invalid player, if name is missing
    if(not IsValidValue(name)) then
        return nil;
    end

    if(not isEnemyTeam) then
        factionIndex = nil;
    end

    local class = cachedValues[valueIndex + 5];
    local race = cachedValues[valueIndex + 10];

    local player = {
        isEnemy = isEnemyTeam,
        isSelf = (name == UnitName("player")),
        name = name,
        race = Localization:GetRaceID(race, factionIndex),
    };

    if(IsValidValue(class)) then
        player.spec = Localization:GetClassID(class);
    else
        ArenaAnalytics:LogError("Import: Missing class and spec for player:", name);
    end

    return player;
end

function Import.ProcessNextMatch_ArenaStatsWrath(arenaString)
    if(not arenaString) then
        return nil;
    end

    local cachedValues = strsplittable(',', arenaString);
    if(not IsValidArena(cachedValues)) then
        local index = Import.state and Import.state.index;
        ArenaAnalytics:LogError("Import (ArenaStats Wrath): Corrupt arena at index:", index, "Value count:", cachedValues and #cachedValues);
        TablePool:Release(cachedValues);
        return nil;
    end

    local date = tonumber(cachedValues[2]);
    if(not Import:CheckDate(date)) then
        TablePool:Release(cachedValues);
        return nil;
    end

    -- Create a new arena match in a standardized import format
    local newArena = TablePool:Acquire();

    -- Set basic arena properties
    newArena.isRated = Import:RetrieveBool(cachedValues[1]);

    newArena.date = date;
    newArena.map = tonumber(cachedValues[4]);
    newArena.duration = tonumber(cachedValues[5]);  -- Duration
    newArena.outcome = GetMatchOutcome(cachedValues);

    -- Fill teams with player data
    newArena.players = TablePool:Acquire();

    local enemyCount = 0;
    local factionIndex = Localization:GetFactionIndex(cachedValues[48]);
    for _,isEnemy in ipairs({false, true}) do
        for i=1, 5 do
            local player = ProcessPlayer(cachedValues, isEnemy, i, factionIndex);
            if(player) then
                tinsert(newArena.players, player);

                if(player.isEnemy) then
                    enemyCount = enemyCount + 1;
                end
            end
        end
    end

    if(#newArena.players == 4 and enemyCount == 2) then
        newArena.bracket = "2v2";
    elseif (#newArena.players == 6 and enemyCount == 3) then
        newArena.bracket = "3v3";
    elseif(#newArena.players == 10 and enemyCount == 5) then
        newArena.bracket = "5v5";
    end

    -- Player rating and MMR data
    newArena.partyRating = tonumber(cachedValues[25]);
    newArena.partyRatingDelta = tonumber(cachedValues[26]);  -- Rating Delta
    newArena.partyMMR = tonumber(cachedValues[27]);  -- Party MMR

    -- Enemy rating and MMR data
    newArena.enemyRating = tonumber(cachedValues[29]);
    newArena.enemyRatingDelta = tonumber(cachedValues[30]);  -- Rating Delta
    newArena.enemyMMR = tonumber(cachedValues[31]);  -- Enemy MMR

    -- Return new arena and updated index
    return newArena;
end