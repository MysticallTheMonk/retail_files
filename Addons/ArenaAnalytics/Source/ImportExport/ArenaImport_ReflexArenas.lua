local _, ArenaAnalytics = ...; -- Addon Namespace
local Import = ArenaAnalytics.Import;

-- Local module aliases
local API = ArenaAnalytics.API;
local Localization = ArenaAnalytics.Localization;
local Helpers = ArenaAnalytics.Helpers;
local Internal = ArenaAnalytics.Internal;
local TablePool = ArenaAnalytics.TablePool;

-------------------------------------------------------------------------

local sourceName = "REFlex (arenas)";

local formatPrefix = "Timestamp;Map;PlayersNumber;TeamComposition;EnemyComposition;Duration;Victory;KillingBlows;Damage;Healing;Honor;RatingChange;MMR;EnemyMMR;Specialization;isRated";
local valuesPerArena = 16;

function Import:CheckDataSource_ReflexArenas(outImportData)
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
    outImportData.processorFunc = Import.ProcessNextMatch_ReflexArenas;
    return true;
end

local function IsValidArena(values)
    return values and #values == valuesPerArena;
end

-------------------------------------------------------------------------
-- Process arenas

local function ProcessTeam(players, cachedValues, isEnemyTeam)
    assert(players);

    local valueIndex = isEnemyTeam and 5 or 4;
    local team = cachedValues[valueIndex];
    if(not team or team == "") then
        return;
    end

    local teamCount = 0;

    -- Process each player
    for playerString in team:gmatch("([^,]+)") do
        if(playerString and playerString ~= "") then
            local newPlayer = TablePool:Acquire();

            -- Split player details by hyphen: "CLASS-Spec-Name-Realm"
            local class, spec, name = strsplit("-", playerString, 3);

            newPlayer.isEnemy = isEnemyTeam;
            newPlayer.name = name;
            newPlayer.spec = Localization:GetSpecID(class, spec);

            -- Determine if the player is self
            newPlayer.isSelf = (name == UnitName("player"));
            if(newPlayer.isSelf) then
                -- Get player stats (Index 8, 9, 10)
                newPlayer.kills = tonumber(cachedValues[8]);
                newPlayer.damage = tonumber(cachedValues[9]);
                newPlayer.healing = tonumber(cachedValues[10]);
            end

            -- Add player data to the team list
            table.insert(players, newPlayer);
            teamCount = teamCount + 1;
        end
    end

    return teamCount;
end

function Import.ProcessNextMatch_ReflexArenas(arenaString)
    ArenaAnalytics:Log("ProcessNextMatch_ReflexArenas", arenaString)
    if(not arenaString) then
        return nil;
    end

    local cachedValues = strsplittable(';', arenaString);
    if(not IsValidArena(cachedValues)) then
        local index = Import.state and Import.state.index;
        ArenaAnalytics:PrintSystem("Import (Reflex): Corrupt arena at index:", index, "Value count:", cachedValues and #cachedValues);
        TablePool:Release(cachedValues);
        return nil;
    end

    local date = tonumber(cachedValues[1]);
    if(not Import:CheckDate(date)) then
        TablePool:Release(cachedValues);
        return nil;
    end

    -- Create a new arena match in a standardized import format
    local newArena = TablePool:Acquire();

    -- Set basic arena properties
    newArena.date = date;           -- Date
    newArena.map = tonumber(cachedValues[2]);   -- Map

    -- Fill teams
    newArena.players = TablePool:Acquire();
    local teamCount = ProcessTeam(newArena.players, cachedValues, false);      -- TeamComposition
    local enemyCount = ProcessTeam(newArena.players, cachedValues, true);      -- EnemyComposition

    -- Appears to be a 2v2.
    if(teamCount == 2 and enemyCount == 2) then
        newArena.bracket = "2v2";
    elseif(teamCount == 5 and enemyCount == 5) then
        newArena.bracket = "5v5";
    end

    newArena.duration = tonumber(cachedValues[6]);           -- Duration
    newArena.outcome = Import:RetrieveSimpleOutcome(cachedValues[7]); -- Victory (boolean)

        -- Player stats moved into ProcessTeam for ally team (Index 8, 9, 10)
        -- Honor ignored (Index 11)

    -- Rated Info
    newArena.partyRatingDelta = tonumber(cachedValues[12]);  -- RatingChange
    newArena.partyMMR = tonumber(cachedValues[13]);           -- MMR
    newArena.enemyMMR = tonumber(cachedValues[14]);      -- EnemyMMR

    --local mySpec = cachedValues[15];                    -- Specialization

    newArena.isRated = Import:RetrieveBool(cachedValues[16]);   -- isRated (boolean)

    TablePool:Release(cachedValues);
    return newArena;
end
